package br.com.platform.notification.consumer;

import br.com.platform.notification.service.NotificationDispatchService;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.smallrye.common.annotation.RunOnVirtualThread;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import org.eclipse.microprofile.config.inject.ConfigProperty;
import org.jboss.logging.Logger;
import software.amazon.awssdk.services.sqs.SqsClient;
import software.amazon.awssdk.services.sqs.model.*;

import jakarta.annotation.PostConstruct;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

/**
 * Generic SQS consumer for CloudEvents of type 'notification.requested'.
 *
 * Expected CloudEvent payload fields (inside 'data'):
 *   - templateName  : String — Qute template filename (e.g., "receipt-email")
 *   - recipient     : String — destination email
 *   - subject       : String — email subject line
 *   - templateData  : Object — arbitrary data passed to the template
 *
 * No business fields are hard-coded here. The payload schema is defined
 * per cell in Apicurio Registry under group '{cellId}' / artifact 'notification.requested'.
 */
@ApplicationScoped
public class NotificationEventConsumer {

    private static final Logger LOG = Logger.getLogger(NotificationEventConsumer.class);

    @Inject
    SqsClient sqsClient;

    @Inject
    NotificationDispatchService dispatchService;

    @Inject
    ObjectMapper mapper;

    /** Env var: NOTIFICATION_QUEUE_URL */
    @ConfigProperty(name = "platform.notification.queue-url",
                    defaultValue = "http://localhost:4566/000000000000/notification-queue")
    String queueUrl;

    /** Env var: NOTIFICATION_CONSUMER_CONCURRENCY */
    @ConfigProperty(name = "platform.notification.concurrency", defaultValue = "5")
    int concurrency;

    @PostConstruct
    @RunOnVirtualThread
    void startPolling() {
        // Use virtual threads for the poll loop — lightweight, no platform thread blocking
        ExecutorService executor = Executors.newVirtualThreadPerTaskExecutor();
        for (int i = 0; i < concurrency; i++) {
            executor.submit(this::pollLoop);
        }
        LOG.infof("Started %d virtual thread SQS pollers on %s", concurrency, queueUrl);
    }

    private void pollLoop() {
        while (!Thread.currentThread().isInterrupted()) {
            try {
                ReceiveMessageResponse response = sqsClient.receiveMessage(
                    ReceiveMessageRequest.builder()
                        .queueUrl(queueUrl)
                        .maxNumberOfMessages(10)
                        .waitTimeSeconds(20)
                        .build()
                );
                for (Message msg : response.messages()) {
                    processMessage(msg);
                }
            } catch (Exception ex) {
                LOG.errorf(ex, "SQS poll error on %s", queueUrl);
            }
        }
    }

    private void processMessage(Message msg) {
        try {
            JsonNode cloudEvent = mapper.readTree(msg.body());

            // Extract CloudEvent envelope fields
            String cellId   = getText(cloudEvent, "buzid", "unknown");
            String eventId  = getText(cloudEvent, "id", UUID.randomUUID().toString());
            JsonNode data   = cloudEvent.path("data");

            // Extract notification-specific fields from data (generic — no domain hardcoding)
            String templateName  = getText(data, "templateName", null);
            String recipient     = getText(data, "recipient", null);
            String subject       = getText(data, "subject", "Platform Notification");
            JsonNode templateData = data.path("templateData");

            if (templateName == null || recipient == null) {
                LOG.warnf("Missing templateName or recipient in event %s", eventId);
                deleteMessage(msg);
                return;
            }

            dispatchService.dispatch(cellId, UUID.fromString(eventId), templateName,
                                     recipient, subject, templateData);
            deleteMessage(msg);

        } catch (Exception ex) {
            LOG.errorf(ex, "Failed to process notification message: %s", msg.messageId());
        }
    }

    private void deleteMessage(Message msg) {
        sqsClient.deleteMessage(DeleteMessageRequest.builder()
            .queueUrl(queueUrl)
            .receiptHandle(msg.receiptHandle())
            .build());
    }

    private String getText(JsonNode node, String field, String defaultValue) {
        JsonNode n = node.path(field);
        return n.isMissingNode() || n.isNull() ? defaultValue : n.asText();
    }
}

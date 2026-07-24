package br.com.platform.notification.consumer;

import br.com.platform.notification.service.NotificationDispatchService;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.smallrye.common.annotation.RunOnVirtualThread;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import org.eclipse.microprofile.reactive.messaging.Incoming;
import org.eclipse.microprofile.reactive.messaging.Message;
import org.jboss.logging.Logger;

import java.util.UUID;
import java.util.concurrent.CompletionStage;

/**
 * Generic AMQP consumer for CloudEvents of type 'notification.requested'.
 *
 * Expected CloudEvent payload fields (inside 'data'):
 *   - templateName  : String — Qute template filename (e.g., "receipt-email")
 *   - recipient     : String — destination email
 *   - subject       : String — email subject line
 *   - templateData  : Object — arbitrary data passed to the template
 */
@ApplicationScoped
public class NotificationEventConsumer {

    private static final Logger LOG = Logger.getLogger(NotificationEventConsumer.class);

    @Inject
    NotificationDispatchService dispatchService;

    @Inject
    ObjectMapper mapper;

    @Incoming("notifications")
    @RunOnVirtualThread
    public CompletionStage<Void> processMessage(Message<String> msg) {
        try {
            JsonNode cloudEvent = mapper.readTree(msg.getPayload());

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
                return msg.ack();
            }

            dispatchService.dispatch(cellId, UUID.fromString(eventId), templateName,
                                     recipient, subject, templateData);
            
            return msg.ack();

        } catch (Exception ex) {
            LOG.errorf(ex, "Failed to process notification message");
            return msg.nack(ex);
        }
    }

    private String getText(JsonNode node, String field, String defaultValue) {
        JsonNode n = node.path(field);
        return n.isMissingNode() || n.isNull() ? defaultValue : n.asText();
    }
}

package br.com.platform.notification.service;

import br.com.platform.notification.domain.NotificationLog;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.quarkus.mailer.Mail;
import io.quarkus.mailer.Mailer;
import io.quarkus.qute.Engine;
import io.quarkus.qute.Template;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import org.jboss.logging.Logger;

import java.time.Instant;
import java.util.Map;
import java.util.UUID;

/**
 * Generic notification dispatcher.
 *
 * How it works:
 *   1. Receives a CloudEvent payload with: templateName, recipient, cellId, eventId, data (Map).
 *   2. Loads a Qute template by name from resources/templates/{templateName}.html.
 *   3. Renders the template with the data map from the event — zero hard-coded fields.
 *   4. Sends via SMTP (Mailpit in dev, SES in prod — configured via env vars).
 *   5. Logs result in notification_log.
 *
 * Adding support for a new cell/product = drop a new .html file in templates/ + register in Apicurio.
 * Zero code changes.
 */
@ApplicationScoped
public class NotificationDispatchService {

    private static final Logger LOG = Logger.getLogger(NotificationDispatchService.class);

    @Inject
    Mailer mailer;

    @Inject
    Engine quteEngine;

    @Inject
    ObjectMapper mapper;

    @Transactional
    public NotificationLog dispatch(String cellId, UUID eventId, String templateName,
                                    String recipient, String subject, JsonNode templateData) {
        NotificationLog log = NotificationLog.create(eventId, cellId, templateName, recipient);
        log.persist();

        try {
            // Load template by name — customer adds templates without touching code
            Template template = quteEngine.getTemplate(templateName);
            if (template == null) {
                throw new IllegalArgumentException("Template not found: " + templateName);
            }

            // Convert JsonNode to Map so Qute can access fields by name
            @SuppressWarnings("unchecked")
            Map<String, Object> data = mapper.convertValue(templateData, Map.class);

            String html = template.data(data).render();

            mailer.send(Mail.withHtml(recipient, subject, html));

            log.status = "SENT";
            log.sentAt = Instant.now();
            LOG.infof("Notification sent: eventId=%s template=%s recipient=%s", eventId, templateName, recipient);

        } catch (Exception ex) {
            log.status = "FAILED";
            log.errorMessage = ex.getMessage();
            LOG.errorf(ex, "Notification failed: eventId=%s template=%s", eventId, templateName);
        }

        return log;
    }
}

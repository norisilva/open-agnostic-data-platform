package br.com.platform.notification.domain;

import io.quarkus.hibernate.orm.panache.PanacheEntityBase;
import jakarta.persistence.*;

import java.time.Instant;
import java.util.UUID;

/**
 * Generic notification log entry.
 * Records ANY notification dispatched by the platform.
 * Business context is carried by templateName + eventId — not hard-coded here.
 *
 * Template names are agreed between the platform operator and the cell
 * (e.g., "receipt-email", "welcome-email") and registered as Qute templates.
 */
@Entity
@Table(name = "notification_log", indexes = {
    @Index(name = "idx_notification_log_event_id", columnList = "event_id"),
    @Index(name = "idx_notification_log_status", columnList = "status")
})
public class NotificationLog extends PanacheEntityBase {

    @Id
    public UUID id;

    /** Reference to the originating platform event */
    @Column(name = "event_id", nullable = false)
    public UUID eventId;

    /** Identifies the cell that triggered this notification */
    @Column(name = "cell_id", nullable = false)
    public String cellId;

    /** Qute template filename (without extension), e.g. "receipt-email" */
    @Column(name = "template_name", nullable = false)
    public String templateName;

    /** Recipient email address */
    @Column(name = "recipient", nullable = false)
    public String recipient;

    /** SENT | FAILED | RETRYING */
    @Column(name = "status", nullable = false)
    public String status;

    /** Error message if status=FAILED */
    @Column(name = "error_message", columnDefinition = "TEXT")
    public String errorMessage;

    @Column(name = "created_at", nullable = false)
    public Instant createdAt;

    @Column(name = "sent_at")
    public Instant sentAt;

    public NotificationLog() {}

    public static NotificationLog create(UUID eventId, String cellId, String templateName, String recipient) {
        NotificationLog log = new NotificationLog();
        log.id = UUID.randomUUID();
        log.eventId = eventId;
        log.cellId = cellId;
        log.templateName = templateName;
        log.recipient = recipient;
        log.status = "PENDING";
        log.createdAt = Instant.now();
        return log;
    }
}

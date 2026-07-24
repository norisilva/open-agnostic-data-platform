package br.com.platform.eventcdcpublisher.domain;

import java.time.Instant;
import java.util.UUID;

/**
 * Generic platform event record.
 * Stores ANY event from ANY cell without knowing the business domain.
 * The actual payload is stored as raw JSON.
 *
 * Cell identity is carried by cellId + eventType headers (X-Cell-Id, X-Event-Type).
 * The business meaning lives in the schema registered in Apicurio, not here.
 */
public class PlatformEvent {

    public UUID id;

    /** Identifies which cell (Apicurio group) this event belongs to. */
    public String cellId;

    /** Identifies the event type (Apicurio artifact ID within the group). */
    public String eventType;

    /**
     * Raw JSON payload as received. No business-specific mapping.
     * Validated against Apicurio schema at ingestion time.
     */
    public String payload;

    /** Deduplication key provided by the caller. */
    public String idempotencyKey;

    /** Lifecycle status: RECEIVED → PUBLISHED → FAILED */
    public String status;

    public Instant createdAt;

    public Instant updatedAt;

    public PlatformEvent() {}

    public static PlatformEvent create(String cellId, String eventType, String payload, String idempotencyKey) {
        PlatformEvent e = new PlatformEvent();
        e.id = UUID.randomUUID();
        e.cellId = cellId;
        e.eventType = eventType;
        e.payload = payload;
        e.idempotencyKey = idempotencyKey;
        e.status = "RECEIVED";
        e.createdAt = Instant.now();
        return e;
    }
}

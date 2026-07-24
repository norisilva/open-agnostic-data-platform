package br.com.platform.eventapi.domain;

import io.quarkus.hibernate.orm.panache.PanacheEntityBase;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "command_outbox")
public class CommandOutboxEntity extends PanacheEntityBase {

    @Id
    public UUID id;

    @Column(name = "cell_id", nullable = false)
    public String cellId;

    @Column(name = "event_type", nullable = false)
    public String eventType;

    @Column(name = "payload", columnDefinition = "text", nullable = false)
    public String payload;

    @Column(name = "status", nullable = false)
    public String status;

    @Column(name = "idempotency_key")
    public String idempotencyKey;

    @Column(name = "created_at", nullable = false)
    public Instant createdAt;
}

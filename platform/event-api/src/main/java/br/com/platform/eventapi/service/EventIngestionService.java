package br.com.platform.eventapi.service;

import br.com.platform.cloudevents.PlatformCloudEvent;
import br.com.platform.eventapi.domain.CommandOutboxEntity;
import br.com.platform.eventapi.domain.CommandRepository;
import br.com.platform.eventapi.domain.PlatformEvent;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.quarkus.redis.datasource.RedisDataSource;
import io.quarkus.redis.datasource.value.ValueCommands;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import org.eclipse.microprofile.config.inject.ConfigProperty;

import java.time.Instant;
import java.util.UUID;

/**
 * Handles event ingestion for ANY cell.
 */
@ApplicationScoped
public class EventIngestionService {

    @Inject
    CommandRepository commandRepository;

    @Inject
    ObjectMapper mapper;

    @ConfigProperty(name = "platform.idempotency.ttl-seconds", defaultValue = "86400")
    int idempotencyTtlSeconds;

    private final ValueCommands<String, String> redisCache;

    public EventIngestionService(RedisDataSource ds) {
        this.redisCache = ds.value(String.class);
    }

    @Transactional
    public PlatformEvent ingest(String cellId, String eventType, JsonNode payload, String idempotencyKey) {
        if (idempotencyKey != null) {
            String cachedId = redisCache.get("idem:" + idempotencyKey);
            if (cachedId != null) {
                PlatformEvent cachedEvent = new PlatformEvent();
                cachedEvent.id = UUID.fromString(cachedId);
                cachedEvent.status = "ACCEPTED_CACHED";
                return cachedEvent;
            }
        }

        PlatformEvent event = PlatformEvent.create(cellId, eventType, payload.toString(), idempotencyKey);

        try {
            PlatformCloudEvent<JsonNode> cloudEvent = PlatformCloudEvent.<JsonNode>builder()
                    .source("platform/event-api")
                    .type(eventType)
                    .data(payload)
                    .buzId(cellId)
                    .correlationId(event.id.toString())
                    .build();

            CommandOutboxEntity outbox = new CommandOutboxEntity();
            outbox.id = event.id;
            outbox.cellId = cellId;
            outbox.eventType = eventType;
            outbox.payload = mapper.writeValueAsString(cloudEvent);
            outbox.status = "PENDING";
            outbox.idempotencyKey = idempotencyKey;
            outbox.createdAt = Instant.now();

            commandRepository.persist(outbox);

            event.status = "PUBLISHED";
        } catch (Exception ex) {
            event.status = "FAILED";
            return event;
        }

        if (idempotencyKey != null && "PUBLISHED".equals(event.status)) {
            redisCache.setex("idem:" + idempotencyKey, idempotencyTtlSeconds, event.id.toString());
        }

        return event;
    }
}

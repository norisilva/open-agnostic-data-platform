package br.com.platform.eventapi.service;

import br.com.platform.cloudevents.PlatformCloudEvent;
import br.com.platform.eventapi.domain.PlatformEvent;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.quarkus.redis.datasource.RedisDataSource;
import io.quarkus.redis.datasource.value.ValueCommands;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import org.eclipse.microprofile.config.inject.ConfigProperty;
import software.amazon.awssdk.services.sns.SnsClient;
import software.amazon.awssdk.services.sns.model.PublishRequest;

import java.util.UUID;

/**
 * Handles event ingestion for ANY cell.
 * Agnostic: no business domain logic here.
 * Fast dispatching: uses Redis for idempotency, publishes to SNS, and returns immediately.
 * Does NOT persist to SQL directly (handled by downstream event-persister).
 */
@ApplicationScoped
public class EventIngestionService {

    @Inject
    SnsClient snsClient;

    @Inject
    ObjectMapper mapper;

    @ConfigProperty(name = "platform.sns.topic-arn-pattern",
                    defaultValue = "arn:aws:sns:us-east-1:000000000000:%s-events")
    String snsTopicArnPattern;

    @ConfigProperty(name = "platform.idempotency.ttl-seconds", defaultValue = "86400")
    int idempotencyTtlSeconds;

    private final ValueCommands<String, String> redisCache;

    public EventIngestionService(RedisDataSource ds) {
        this.redisCache = ds.value(String.class);
    }

    /**
     * Ingests a generic event payload using Fast Dispatching pattern.
     */
    public PlatformEvent ingest(String cellId, String eventType, JsonNode payload, String idempotencyKey) {
        // 1. Idempotency check via Redis (fast path)
        if (idempotencyKey != null) {
            String cachedId = redisCache.get("idem:" + idempotencyKey);
            if (cachedId != null) {
                // Already processed, return a shell object representing the accepted event
                PlatformEvent cachedEvent = new PlatformEvent();
                cachedEvent.id = UUID.fromString(cachedId);
                cachedEvent.status = "ACCEPTED_CACHED";
                return cachedEvent;
            }
        }

        // 2. Create the event object (in memory)
        PlatformEvent event = PlatformEvent.create(cellId, eventType, payload.toString(), idempotencyKey);

        // 3. Wrap in CloudEvent envelope and publish to SNS
        try {
            PlatformCloudEvent<JsonNode> cloudEvent = PlatformCloudEvent.<JsonNode>builder()
                    .source("platform/event-api")
                    .type(eventType)
                    .data(payload)
                    .buzId(cellId)
                    .correlationId(event.id.toString())
                    .build();

            String topicArn = String.format(snsTopicArnPattern, cellId);
            snsClient.publish(PublishRequest.builder()
                    .topicArn(topicArn)
                    .message(mapper.writeValueAsString(cloudEvent))
                    .build());

            event.status = "PUBLISHED";
        } catch (Exception ex) {
            event.status = "FAILED";
            // Return failed state so client knows it wasn't dispatched
            return event;
        }

        // 4. Cache idempotency key in Redis
        if (idempotencyKey != null && "PUBLISHED".equals(event.status)) {
            redisCache.setex("idem:" + idempotencyKey, idempotencyTtlSeconds, event.id.toString());
        }

        return event;
    }
}

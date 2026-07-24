package br.com.platform.cellrouter.service;

import br.com.platform.cloudevents.PlatformCloudEvent;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.quarkus.redis.datasource.RedisDataSource;
import io.quarkus.redis.datasource.value.ValueCommands;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import org.eclipse.microprofile.config.inject.ConfigProperty;
import org.eclipse.microprofile.rest.client.inject.RestClient;
import software.amazon.awssdk.services.sns.SnsClient;
import software.amazon.awssdk.services.sns.model.PublishRequest;

@ApplicationScoped
public class EventRouterService {

    @Inject
    @RestClient
    ApicurioClient apicurioClient;

    @Inject
    SnsClient snsClient;

    @Inject
    ObjectMapper mapper;

    /**
     * 12-Factor III (Config): SNS Topic ARN pattern fully externalized.
     * Format: arn:aws:sns:{region}:{accountId}:{group}-events
     * In prod, set PLATFORM_SNS_TOPIC_ARN_PATTERN=arn:aws:sns:us-east-1:123456789012:%s-events
     * In local/dev, LocalStack uses the default below.
     */
    @ConfigProperty(name = "platform.sns.topic-arn-pattern",
                    defaultValue = "arn:aws:sns:us-east-1:000000000000:%s-events")
    String snsTopicArnPattern;

    /**
     * 12-Factor III (Config): Schema cache TTL externalized (seconds).
     */
    @ConfigProperty(name = "platform.schema.cache-ttl-seconds", defaultValue = "300")
    int schemaCacheTtlSeconds;

    private final ValueCommands<String, String> redisValueCommands;

    public EventRouterService(RedisDataSource ds) {
        this.redisValueCommands = ds.value(String.class);
    }

    public void routeEvent(String group, String eventType, JsonNode payload) {
        // 1. Fetch schema (from cache or Apicurio)
        String cacheKey = "schema:" + group + ":" + eventType;
        String schemaStr = redisValueCommands.get(cacheKey);
        if (schemaStr == null) {
            JsonNode schemaNode = apicurioClient.getLatestArtifact(group, eventType);
            schemaStr = schemaNode.toString();
            redisValueCommands.setex(cacheKey, schemaCacheTtlSeconds, schemaStr);
        }

        // 2. Wrap in CloudEvent
        PlatformCloudEvent<JsonNode> event = PlatformCloudEvent.<JsonNode>builder()
                .source("platform/cell-router")
                .type(eventType)
                .data(payload)
                .buzId(group)
                .build();

        // 3. Route to SNS — topic ARN is fully driven by env var (12-Factor)
        try {
            String topicArn = String.format(snsTopicArnPattern, group);
            snsClient.publish(PublishRequest.builder()
                    .topicArn(topicArn)
                    .message(mapper.writeValueAsString(event))
                    .build());
        } catch (Exception e) {
            throw new RuntimeException("Failed to publish event to SNS", e);
        }
    }
}

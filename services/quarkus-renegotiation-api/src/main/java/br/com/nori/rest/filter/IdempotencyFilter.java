package br.com.nori.rest.filter;

import io.quarkus.redis.datasource.RedisDataSource;
import io.quarkus.redis.datasource.value.ValueCommands;
import jakarta.inject.Inject;
import jakarta.ws.rs.container.ContainerRequestContext;
import jakarta.ws.rs.container.ContainerRequestFilter;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.ext.Provider;

import java.io.IOException;
import java.time.Duration;

@Provider
public class IdempotencyFilter implements ContainerRequestFilter {

    private final ValueCommands<String, String> valueCommands;

    @Inject
    public IdempotencyFilter(RedisDataSource redisDataSource) {
        this.valueCommands = redisDataSource.value(String.class);
    }

    @Override
    public void filter(ContainerRequestContext requestContext) throws IOException {
        if (!requestContext.getMethod().equalsIgnoreCase("POST")) {
            return;
        }

        String idempotencyKey = requestContext.getHeaderString("Idempotency-Key");
        if (idempotencyKey == null || idempotencyKey.isBlank()) {
            requestContext.abortWith(
                Response.status(Response.Status.BAD_REQUEST)
                        .entity("{\"error\":\"Idempotency-Key header is missing\"}")
                        .build()
            );
            return;
        }

        String redisKey = "idempotency:" + idempotencyKey;
        
        // Use SET NX (set only if not exists)
        boolean set = valueCommands.setnx(redisKey, "PROCESSING");
        
        if (!set) {
            requestContext.abortWith(
                Response.status(Response.Status.CONFLICT)
                        .entity("{\"error\":\"Request already processed or currently processing\"}")
                        .build()
            );
        } else {
            // Set expiration to 24h
            valueCommands.getDataSource().key().expire(redisKey, Duration.ofHours(24));
        }
    }
}

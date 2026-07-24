package br.com.platform.eventapi.rest.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.databind.JsonNode;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

/**
 * Generic event ingestion request.
 * The actual schema/structure of 'payload' is validated against Apicurio
 * at runtime — this DTO knows nothing about the business domain.
 */
public record EventRequest(

    /**
     * Arbitrary JSON payload. Any structure allowed here;
     * validation happens via Apicurio schema (keyed by X-Cell-Id + X-Event-Type).
     */
    @NotNull(message = "payload is required")
    @JsonProperty("payload")
    JsonNode payload

) {}

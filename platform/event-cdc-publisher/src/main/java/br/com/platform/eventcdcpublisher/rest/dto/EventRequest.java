package br.com.platform.eventcdcpublisher.rest.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.databind.JsonNode;
import jakarta.validation.constraints.NotNull;

/**
 * Generic event ingestion request.
 */
public record EventRequest(

        @NotNull(message = "payload is required") @JsonProperty("payload") JsonNode payload

) {
}

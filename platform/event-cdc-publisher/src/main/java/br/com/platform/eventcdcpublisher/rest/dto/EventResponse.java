package br.com.platform.eventcdcpublisher.rest.dto;

import java.time.Instant;
import java.util.UUID;

/**
 * Generic event acceptance response.
 * Returns an eventId the caller can use to track status.
 */
public record EventResponse(
    UUID eventId,
    String status,
    String cellId,
    String eventType,
    Instant receivedAt
) {}

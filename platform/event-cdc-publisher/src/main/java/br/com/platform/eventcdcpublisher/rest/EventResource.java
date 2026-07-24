package br.com.platform.eventcdcpublisher.rest;

import br.com.platform.eventcdcpublisher.domain.PlatformEvent;
import br.com.platform.eventcdcpublisher.rest.dto.EventRequest;
import br.com.platform.eventcdcpublisher.rest.dto.EventResponse;
import br.com.platform.eventcdcpublisher.service.EventIngestionService;
import io.smallrye.common.annotation.RunOnVirtualThread;
import jakarta.inject.Inject;
import jakarta.validation.Valid;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

/**
 * Generic event ingestion REST API.
 * 
 * Headers:
 * X-Cell-Id — identifies the cell (maps to Apicurio group)
 * X-Event-Type — identifies the event schema (maps to Apicurio artifact)
 * Idempotency-Key — optional deduplication key (RFC 8925 style)
 */
@Path("/api/v1/events")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class EventResource {

    @Inject
    EventIngestionService ingestionService;

    @POST
    @RunOnVirtualThread
    public Response ingestEvent(
            @HeaderParam("X-Cell-Id") String cellId,
            @HeaderParam("X-Event-Type") String eventType,
            @HeaderParam("Idempotency-Key") String idempotencyKey,
            @Valid EventRequest request) {

        if (cellId == null || cellId.isBlank()) {
            return Response.status(Response.Status.BAD_REQUEST)
                    .entity("{\"error\": \"Header X-Cell-Id is required\"}")
                    .build();
        }
        if (eventType == null || eventType.isBlank()) {
            return Response.status(Response.Status.BAD_REQUEST)
                    .entity("{\"error\": \"Header X-Event-Type is required\"}")
                    .build();
        }

        PlatformEvent event = ingestionService.ingest(cellId, eventType, request.payload(), idempotencyKey);

        if ("FAILED".equals(event.status)) {
            return Response.serverError().entity("{\"error\": \"Failed to publish event to message broker\"}").build();
        }

        EventResponse resp = new EventResponse(
                event.id,
                event.status,
                event.cellId,
                event.eventType,
                event.createdAt);

        return Response.accepted(resp).build();
    }
}

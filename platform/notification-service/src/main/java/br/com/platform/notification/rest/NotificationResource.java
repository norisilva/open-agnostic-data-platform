package br.com.platform.notification.rest;

import br.com.platform.notification.domain.NotificationLog;
import io.smallrye.common.annotation.RunOnVirtualThread;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

import java.util.UUID;

/**
 * REST API for notification management.
 * Fully agnostic — no business domain in endpoints or DTOs.
 */
@Path("/api/v1/notifications")
@Produces(MediaType.APPLICATION_JSON)
public class NotificationResource {

    @GET
    @Path("/{eventId}/status")
    @RunOnVirtualThread
    public Response getStatus(@PathParam("eventId") UUID eventId) {
        NotificationLog log = NotificationLog.find("eventId", eventId).firstResult();
        if (log == null) {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
        return Response.ok(new StatusResponse(log.id, log.eventId, log.status,
                log.templateName, log.recipient, log.sentAt, log.errorMessage)).build();
    }

    @POST
    @Path("/resend/{eventId}")
    @RunOnVirtualThread
    public Response resend(@PathParam("eventId") UUID eventId) {
        NotificationLog original = NotificationLog.find("eventId", eventId).firstResult();
        if (original == null) {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
        // Reset to RETRYING — consumer will pick it up via a separate resend queue or re-trigger
        // For now: mark as RETRYING so a scheduled job or manual trigger can re-dispatch
        original.status = "RETRYING";
        original.errorMessage = null;
        return Response.accepted(new StatusResponse(original.id, original.eventId, original.status,
                original.templateName, original.recipient, original.sentAt, null)).build();
    }

    public record StatusResponse(
            UUID notificationId,
            UUID eventId,
            String status,
            String templateName,
            String recipient,
            java.time.Instant sentAt,
            String errorMessage
    ) {}
}

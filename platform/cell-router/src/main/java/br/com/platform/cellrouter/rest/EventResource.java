package br.com.platform.cellrouter.rest;

import br.com.platform.cellrouter.service.EventRouterService;
import com.fasterxml.jackson.databind.JsonNode;
import io.smallrye.common.annotation.RunOnVirtualThread;
import jakarta.inject.Inject;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

@Path("/platform/v1/events")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class EventResource {

    @Inject
    EventRouterService eventRouterService;

    @POST
    @Path("/{group}/{eventType}")
    @RunOnVirtualThread
    public Response publishEvent(@PathParam("group") String group, 
                                 @PathParam("eventType") String eventType, 
                                 JsonNode payload) {
        eventRouterService.routeEvent(group, eventType, payload);
        return Response.accepted().build();
    }
}

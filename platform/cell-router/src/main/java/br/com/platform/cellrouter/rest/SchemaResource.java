package br.com.platform.cellrouter.rest;

import br.com.platform.cellrouter.service.ApicurioClient;
import com.fasterxml.jackson.databind.JsonNode;
import io.smallrye.common.annotation.RunOnVirtualThread;
import jakarta.inject.Inject;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import org.eclipse.microprofile.rest.client.inject.RestClient;

@Path("/platform/v1/schemas")
@Produces(MediaType.APPLICATION_JSON)
public class SchemaResource {

    @Inject
    @RestClient
    ApicurioClient apicurioClient;

    @GET
    @Path("/{group}")
    @RunOnVirtualThread
    public JsonNode getSchemas(@PathParam("group") String group) {
        return apicurioClient.getArtifacts(group);
    }
}

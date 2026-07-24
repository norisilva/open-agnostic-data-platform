package br.com.platform.cellrouter.service;

import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import org.eclipse.microprofile.rest.client.inject.RegisterRestClient;
import com.fasterxml.jackson.databind.JsonNode;

@RegisterRestClient(configKey = "apicurio")
@Path("/apis/registry/v3")
public interface ApicurioClient {
    @GET
    @Path("/groups/{group}/artifacts")
    @Produces(MediaType.APPLICATION_JSON)
    JsonNode getArtifacts(@PathParam("group") String group);

    @GET
    @Path("/groups/{group}/artifacts/{artifactId}/versions/branch=latest")
    @Produces(MediaType.APPLICATION_JSON)
    JsonNode getLatestArtifact(@PathParam("group") String group, @PathParam("artifactId") String artifactId);
}

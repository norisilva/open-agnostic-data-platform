package br.com.platform.cellrouter.rest;

import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import org.eclipse.microprofile.config.inject.ConfigProperty;

import java.util.List;
import java.util.Arrays;

@Path("/platform/v1/cells")
@Produces(MediaType.APPLICATION_JSON)
public class CellResource {

    @ConfigProperty(name = "platform.cells.active")
    String activeCells;

    @GET
    public List<String> getCells() {
        return Arrays.asList(activeCells.split(","));
    }
}

package br.com.nori.rest.controller;

import br.com.nori.domain.PaymentRenegotiation;
import br.com.nori.rest.dto.PaymentRenegotiationRequest;
import br.com.nori.rest.dto.PaymentRenegotiationResponse;
import br.com.nori.core.port.ProcessorPort;
import io.smallrye.common.annotation.RunOnVirtualThread;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import jakarta.validation.Valid;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

@Path("/api/v1/renegotiations")
public class RenegotiationController {

    @Inject
    ProcessorPort processor;

    @GET
    @Path("/{id}")
    @Produces(MediaType.APPLICATION_JSON)
    @RunOnVirtualThread
    public Response getRenegotiation(@jakarta.ws.rs.PathParam("id") java.util.UUID id) {
        PaymentRenegotiation entity = PaymentRenegotiation.findById(id);
        if (entity == null) {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
        PaymentRenegotiationResponse response = new PaymentRenegotiationResponse(
            entity.id,
            entity.status,
            "Status da renegociação",
            entity.originalDebtId
        );
        return Response.ok(response).build();
    }

    @POST
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces(MediaType.APPLICATION_JSON)
    @RunOnVirtualThread
    @Transactional
    public Response createRenegotiation(@Valid PaymentRenegotiationRequest request) {
        
        PaymentRenegotiation entity = PaymentRenegotiation.create(
            request.originalDebtId,
            request.codigoBarra,
            request.valorPago,
            request.cpfCnpj,
            request.nomePagador,
            request.emailPagador
        );
        entity.persist();
        
        // Asynchronous processing triggered here
        processor.process(request.codigoBarra, request.valorPago, request.emailPagador);

        PaymentRenegotiationResponse response = new PaymentRenegotiationResponse(
            entity.id,
            entity.status,
            "Pagamento recebido. Comprovante será enviado para " + request.emailPagador,
            request.originalDebtId
        );

        return Response.accepted(response).build();
    }
}
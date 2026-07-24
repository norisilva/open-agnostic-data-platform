package br.com.nori.rest.dto;

import java.time.Instant;
import java.util.UUID;

public class PaymentRenegotiationResponse {

    public UUID idRenegociation;
    public String status;
    public String message;
    public Instant timestamp;
    public String originalDebtId;

    public PaymentRenegotiationResponse() {
    }

    public PaymentRenegotiationResponse(UUID idRenegociation, String status, String message, String originalDebtId) {
        this.idRenegociation = idRenegociation;
        this.status = status;
        this.message = message;
        this.timestamp = Instant.now();
        this.originalDebtId = originalDebtId;
    }
}

package br.com.nori.rest.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Positive;
import java.math.BigDecimal;

public class PaymentRenegotiationRequest {

    @NotBlank(message = "originalDebtId is required")
    public String originalDebtId;

    @NotBlank(message = "codigoBarra is required")
    public String codigoBarra;

    @Positive(message = "valorPago must be positive")
    public BigDecimal valorPago;

    @NotBlank(message = "cpfCnpj is required")
    public String cpfCnpj;

    @NotBlank(message = "nomePagador is required")
    public String nomePagador;

    @NotBlank(message = "emailPagador is required")
    @Email(message = "emailPagador must be a valid email")
    public String emailPagador;
}

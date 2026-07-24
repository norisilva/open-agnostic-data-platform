package br.com.nori.rest.controller;

import br.com.nori.rest.dto.PaymentRenegotiationRequest;
import io.quarkus.test.junit.QuarkusTest;
import io.restassured.http.ContentType;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.*;

@QuarkusTest
class RenegotiationControllerTest {

    @Test
    void testCreateRenegotiation_Success() {
        PaymentRenegotiationRequest request = new PaymentRenegotiationRequest();
        request.originalDebtId = "debt-123";
        request.codigoBarra = "123456789";
        request.valorPago = new BigDecimal("100.00");
        request.cpfCnpj = "12345678900";
        request.nomePagador = "Joao Silva";
        request.emailPagador = "joao@email.com";

        given()
            .contentType(ContentType.JSON)
            .header("Idempotency-Key", "test-key-123")
            .body(request)
        .when()
            .post("/api/v1/renegotiations")
        .then()
            .statusCode(202)
            .body("idRenegociation", notNullValue())
            .body("status", equalTo("PROCESSING"))
            .body("message", containsString("joao@email.com"));
    }

    @Test
    void testCreateRenegotiation_InvalidPayload() {
        PaymentRenegotiationRequest request = new PaymentRenegotiationRequest();
        // Missing originalDebtId, email, etc.

        given()
            .contentType(ContentType.JSON)
            .header("Idempotency-Key", "test-key-456")
            .body(request)
        .when()
            .post("/api/v1/renegotiations")
        .then()
            .statusCode(400); // Bad request due to Bean Validation
    }

    @Test
    void testCreateRenegotiation_MissingIdempotencyKey() {
        PaymentRenegotiationRequest request = new PaymentRenegotiationRequest();
        request.originalDebtId = "debt-123";
        request.codigoBarra = "123456789";
        request.valorPago = new BigDecimal("100.00");
        request.cpfCnpj = "12345678900";
        request.nomePagador = "Joao Silva";
        request.emailPagador = "joao@email.com";

        given()
            .contentType(ContentType.JSON)
            .body(request)
        .when()
            .post("/api/v1/renegotiations")
        .then()
            .statusCode(400); // Due to missing header
    }
}

package br.com.platform.eventapi.rest;

import io.quarkus.test.junit.QuarkusTest;
import io.quarkus.test.InjectMock;
import org.junit.jupiter.api.Test;
import br.com.platform.eventapi.service.EventIngestionService;
import br.com.platform.eventapi.domain.PlatformEvent;

import java.time.Instant;
import java.util.UUID;

import static io.restassured.RestAssured.given;
import static org.hamcrest.CoreMatchers.notNullValue;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.when;

@QuarkusTest
class EventResourceTest {

    @InjectMock
    EventIngestionService ingestionService;

    @Test
    void testIngestEvent_missingCellId_returns400() {
        given()
            .header("X-Event-Type", "order.created")
            .contentType("application/json")
            .body("{\"payload\": {\"amount\": 100}}")
        .when()
            .post("/api/v1/events")
        .then()
            .statusCode(400);
    }

    @Test
    void testIngestEvent_missingEventType_returns400() {
        given()
            .header("X-Cell-Id", "orders")
            .contentType("application/json")
            .body("{\"payload\": {\"amount\": 100}}")
        .when()
            .post("/api/v1/events")
        .then()
            .statusCode(400);
    }

    @Test
    void testIngestEvent_validRequest_returns202() {
        PlatformEvent mockEvent = PlatformEvent.create("orders", "order.created", "{}", null);
        mockEvent.id = UUID.randomUUID();
        mockEvent.createdAt = Instant.now();

        when(ingestionService.ingest(eq("orders"), eq("order.created"), any(), isNull()))
            .thenReturn(mockEvent);

        given()
            .header("X-Cell-Id", "orders")
            .header("X-Event-Type", "order.created")
            .contentType("application/json")
            .body("{\"payload\": {\"amount\": 100}}")
        .when()
            .post("/api/v1/events")
        .then()
            .statusCode(202)
            .body("eventId", notNullValue());
    }
}

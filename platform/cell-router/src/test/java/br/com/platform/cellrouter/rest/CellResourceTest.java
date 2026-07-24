package br.com.platform.cellrouter.rest;

import io.quarkus.test.junit.QuarkusTest;
import org.junit.jupiter.api.Test;

import static io.restassured.RestAssured.given;
import static org.hamcrest.CoreMatchers.is;

@QuarkusTest
class CellResourceTest {

    @Test
    void testCellsEndpoint() {
        given()
          .when().get("/platform/v1/cells")
          .then()
             .statusCode(200);
    }
}

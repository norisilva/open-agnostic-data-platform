package br.com.platform.cloudevents;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

import java.util.Map;

class PlatformCloudEventTest {

    private final ObjectMapper mapper = new ObjectMapper();

    @Test
    void testSerializationAndDeserialization() throws Exception {
        Map<String, String> payload = Map.of("paymentId", "123", "status", "APPROVED");

        PlatformCloudEvent<Map<String, String>> event = PlatformCloudEvent.<Map<String, String>>builder()
                .source("cells/renegotiation/api")
                .type("br.com.platform.renegotiation.payment.v1")
                .buzId("renegotiation-cell-a")
                .correlationId("saga-456")
                .traceParent("00-112233445566778899aabbccddeeff00-1122334455667788-01")
                .data(payload)
                .build();

        assertNotNull(event.getId());
        assertNotNull(event.getTime());
        assertEquals("1.0", event.getSpecVersion());
        assertEquals("application/json", event.getDataContentType());

        String json = mapper.writeValueAsString(event);
        
        PlatformCloudEvent<Map<String, String>> deserializedEvent = mapper.readValue(
            json, 
            new TypeReference<PlatformCloudEvent<Map<String, String>>>() {}
        );

        assertEquals(event.getId(), deserializedEvent.getId());
        assertEquals(event.getSource(), deserializedEvent.getSource());
        assertEquals(event.getType(), deserializedEvent.getType());
        assertEquals(event.getBuzId(), deserializedEvent.getBuzId());
        assertEquals(event.getCorrelationId(), deserializedEvent.getCorrelationId());
        assertEquals("123", deserializedEvent.getData().get("paymentId"));
    }
}

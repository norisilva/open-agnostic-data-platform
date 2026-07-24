package br.com.nori.business.processor;

import br.com.nori.core.port.ProducerPort;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;

import java.math.BigDecimal;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.*;

class PayProcessorTest {

    @Mock
    ProducerPort producerPort;

    @InjectMocks
    PayProcessor payProcessor;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
    }

    @Test
    void process_WithValidData_ShouldReturnSuccessMessageAndSendMessage() {
        String codigoBarra = "123456";
        BigDecimal valorPago = new BigDecimal("100.00");
        String email = "test@test.com";

        String result = payProcessor.process(codigoBarra, valorPago, email);

        assertTrue(result.contains("Pagamento enviado com sucesso"));
        verify(producerPort, times(1)).sendMessage(codigoBarra, valorPago, email);
    }

    @Test
    void process_WithInvalidData_ShouldReturnWaitingMessageAndNotSendMessage() {
        String result = payProcessor.process(null, new BigDecimal("100.00"), "test@test.com");
        assertEquals("Aguardando pagamento.", result);

        result = payProcessor.process("123", BigDecimal.ZERO, "test@test.com");
        assertEquals("Aguardando pagamento.", result);

        verify(producerPort, never()).sendMessage(anyString(), any(), anyString());
    }
}

package br.com.nori.domain;

import org.junit.jupiter.api.Test;

import java.math.BigDecimal;

import static org.junit.jupiter.api.Assertions.*;

class PaymentRenegotiationTest {

    @Test
    void testCreatePaymentRenegotiation() {
        PaymentRenegotiation entity = PaymentRenegotiation.create(
                "debt-123",
                "123456789",
                new BigDecimal("100.50"),
                "123.456.789-00",
                "Joao",
                "joao@email.com"
        );

        assertNotNull(entity.id);
        assertEquals("debt-123", entity.originalDebtId);
        assertEquals("123456789", entity.barcode);
        assertEquals(new BigDecimal("100.50"), entity.amount);
        assertEquals("123.456.789-00", entity.cpfCnpj);
        assertEquals("Joao", entity.payerName);
        assertEquals("joao@email.com", entity.payerEmail);
        assertEquals("PROCESSING", entity.status);
        assertNotNull(entity.createdAt);
    }
}

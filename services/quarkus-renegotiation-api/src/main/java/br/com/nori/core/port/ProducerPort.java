package br.com.nori.core.port;

import java.math.BigDecimal;

public interface ProducerPort {
    void sendMessage(String codigoBarra, BigDecimal valorPago, String email);
}

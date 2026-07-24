package br.com.nori.core.port;

import java.math.BigDecimal;

public interface ProcessorPort {
    String process(String codigoBarra, BigDecimal valorPago, String email);
}

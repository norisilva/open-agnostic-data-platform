package br.com.nori.business.processor;

import br.com.nori.core.port.ProcessorPort;
import br.com.nori.core.port.ProducerPort;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;

import java.math.BigDecimal;

@ApplicationScoped
public class PayProcessor implements ProcessorPort {

    @Inject
    ProducerPort producer;

        public String process(String codigoBarra, BigDecimal valorPago, String email) {
            if (codigoBarra == null || valorPago.compareTo(BigDecimal.ZERO) <= 0 || email == null) {
                return "Aguardando pagamento.";
            }
            producer.sendMessage(codigoBarra, valorPago, email);
            return String.format("Pagamento enviado com sucesso. Você receberá a confirmação da baixa no email %s CodigoBarra: %s, ValorPago: %.2f", email, codigoBarra, valorPago);
        }
}

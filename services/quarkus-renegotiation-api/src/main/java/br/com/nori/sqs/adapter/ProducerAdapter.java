package br.com.nori.sqs.adapter;

import br.com.nori.core.port.ProducerPort;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import org.eclipse.microprofile.config.inject.ConfigProperty;
import software.amazon.awssdk.services.sns.SnsClient;
import software.amazon.awssdk.services.sns.model.PublishRequest;

import java.math.BigDecimal;
import java.util.logging.Logger;

@ApplicationScoped
public class ProducerAdapter implements ProducerPort {

    private static final Logger LOG = Logger.getLogger(ProducerAdapter.class.getName());

    @Inject
    SnsClient snsClient;

    @ConfigProperty(name = "topic.renegotiation.arn")
    String topicArn;

    public void sendMessage(String codigoBarra, BigDecimal valorPago, String email) {
        String messageBody = String.format("{\"barcode\": \"%s\", \"amount\": %.2f, \"payerEmail\": \"%s\"}", codigoBarra, valorPago, email);
        
        PublishRequest request = PublishRequest.builder()
                .topicArn(topicArn)
                .message(messageBody)
                .build();

        var response = snsClient.publish(request);
        LOG.info("Mensagem publicada no SNS com MessageId: " + response.messageId());
    }
}
package br.com.nori.domain;

import io.quarkus.hibernate.orm.panache.PanacheEntityBase;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "renegotiations")
public class PaymentRenegotiation extends PanacheEntityBase {

    @Id
    public UUID id;

    @Column(name = "original_debt_id", nullable = false)
    public String originalDebtId;

    @Column(name = "barcode", nullable = false)
    public String barcode;

    @Column(name = "amount", nullable = false)
    public BigDecimal amount;

    @Column(name = "cpf_cnpj")
    public String cpfCnpj;

    @Column(name = "payer_name")
    public String payerName;

    @Column(name = "payer_email", nullable = false)
    public String payerEmail;

    @Column(name = "status", nullable = false)
    public String status;

    @Column(name = "created_at", nullable = false)
    public Instant createdAt;

    public PaymentRenegotiation() {
    }

    public static PaymentRenegotiation create(String originalDebtId, String barcode, BigDecimal amount, String cpfCnpj, String payerName, String payerEmail) {
        PaymentRenegotiation entity = new PaymentRenegotiation();
        entity.id = UUID.randomUUID();
        entity.originalDebtId = originalDebtId;
        entity.barcode = barcode;
        entity.amount = amount;
        entity.cpfCnpj = cpfCnpj;
        entity.payerName = payerName;
        entity.payerEmail = payerEmail;
        entity.status = "PROCESSING";
        entity.createdAt = Instant.now();
        return entity;
    }
}
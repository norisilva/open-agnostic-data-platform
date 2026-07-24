CREATE TABLE renegotiations (
    id UUID PRIMARY KEY,
    original_debt_id VARCHAR(255) NOT NULL,
    barcode VARCHAR(255) NOT NULL,
    amount DECIMAL(15, 2) NOT NULL,
    cpf_cnpj VARCHAR(50),
    payer_name VARCHAR(255),
    payer_email VARCHAR(255) NOT NULL,
    status VARCHAR(50) NOT NULL,
    created_at TIMESTAMP NOT NULL
);

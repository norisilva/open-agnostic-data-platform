CREATE TABLE command_outbox (
    id UUID PRIMARY KEY,
    cell_id VARCHAR(255) NOT NULL,
    event_type VARCHAR(255) NOT NULL,
    payload TEXT NOT NULL,
    status VARCHAR(50) NOT NULL,
    idempotency_key VARCHAR(255),
    created_at TIMESTAMP NOT NULL
);

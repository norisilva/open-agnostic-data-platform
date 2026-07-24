-- V1: Generic notification log.
-- Records any notification dispatched by the platform regardless of cell/business domain.
-- Template name is a string pointer to a Qute template file — zero schema coupling.
CREATE TABLE notification_log (
    id             UUID         NOT NULL PRIMARY KEY,
    event_id       UUID         NOT NULL,
    cell_id        VARCHAR(64)  NOT NULL,
    template_name  VARCHAR(128) NOT NULL,
    recipient      VARCHAR(255) NOT NULL,
    status         VARCHAR(32)  NOT NULL DEFAULT 'PENDING',
    error_message  TEXT,
    created_at     TIMESTAMPTZ  NOT NULL DEFAULT now(),
    sent_at        TIMESTAMPTZ
);

CREATE INDEX idx_notification_log_event_id ON notification_log (event_id);
CREATE INDEX idx_notification_log_status   ON notification_log (status);
CREATE INDEX idx_notification_log_cell_id  ON notification_log (cell_id);

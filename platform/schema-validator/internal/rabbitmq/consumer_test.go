package rabbitmq

import (
	"encoding/json"
	"testing"
	"errors"

	amqp "github.com/rabbitmq/amqp091-go"
	cloudevents "github.com/multiframeworks-renegociation/platform/cloudevents-go"
	"github.com/multiframeworks-renegociation/platform/schema-validator/internal/config"
)

type mockPublisher struct {
	published []amqp.Publishing
}

func (m *mockPublisher) Publish(exchange, key string, mandatory, immediate bool, msg amqp.Publishing) error {
	m.published = append(m.published, msg)
	return nil
}
func (m *mockPublisher) Close() error { return nil }

type mockAcknowledger struct {
	acked  bool
	nacked bool
}

func (m *mockAcknowledger) Ack(tag uint64, multiple bool) error {
	m.acked = true
	return nil
}
func (m *mockAcknowledger) Nack(tag uint64, multiple bool, requeue bool) error {
	m.nacked = true
	return nil
}
func (m *mockAcknowledger) Reject(tag uint64, requeue bool) error { return nil }

type mockValidator struct {
	err error
}

func (m *mockValidator) Validate(group, artifactId string, data []byte) error {
	return m.err
}

func TestProcessMessage_ParseError(t *testing.T) {
	pub := &mockPublisher{}
	ack := &mockAcknowledger{}
	val := &mockValidator{}

	c := &Consumer{
		cfg: &config.Config{
			DLQName:      "dlq",
			ExchangeName: "exchange",
		},
		pubCh:     pub,
		validator: val,
	}

	msg := amqp.Delivery{
		Acknowledger: ack,
		Body:         []byte(`invalid json`),
	}

	c.processMessage(msg)

	if !ack.acked {
		t.Error("Expected message to be acked (discarded from main queue)")
	}
	if len(pub.published) != 1 {
		t.Fatalf("Expected 1 message published to DLQ, got %d", len(pub.published))
	}
	if pub.published[0].Headers["x-validation-error"] == nil {
		t.Error("Expected x-validation-error header")
	}
}

func TestProcessMessage_ValidationError(t *testing.T) {
	pub := &mockPublisher{}
	ack := &mockAcknowledger{}
	val := &mockValidator{err: errors.New("invalid schema")}

	c := &Consumer{
		cfg: &config.Config{
			DLQName:      "dlq",
			ExchangeName: "exchange",
		},
		pubCh:     pub,
		validator: val,
	}

	ce := cloudevents.PlatformCloudEvent[json.RawMessage]{
		Type:  "test-event",
		BuzID: "test-group",
		Data:  json.RawMessage(`{}`),
	}
	body, _ := json.Marshal(ce)

	msg := amqp.Delivery{
		Acknowledger: ack,
		Body:         body,
	}

	c.processMessage(msg)

	if !ack.acked {
		t.Error("Expected message to be acked (discarded from main queue)")
	}
	if len(pub.published) != 1 {
		t.Fatalf("Expected 1 message published to DLQ, got %d", len(pub.published))
	}
	if pub.published[0].Headers["x-validation-error"] == nil {
		t.Error("Expected x-validation-error header")
	}
}

func TestProcessMessage_Success(t *testing.T) {
	pub := &mockPublisher{}
	ack := &mockAcknowledger{}
	val := &mockValidator{err: nil}

	c := &Consumer{
		cfg: &config.Config{
			DLQName:      "dlq",
			ExchangeName: "exchange",
		},
		pubCh:     pub,
		validator: val,
	}

	ce := cloudevents.PlatformCloudEvent[json.RawMessage]{
		Type:  "test-event",
		BuzID: "test-group",
		Data:  json.RawMessage(`{"name": "valid"}`),
	}
	body, _ := json.Marshal(ce)

	msg := amqp.Delivery{
		Acknowledger: ack,
		Body:         body,
	}

	c.processMessage(msg)

	if !ack.acked {
		t.Error("Expected message to be acked")
	}
	if len(pub.published) != 1 {
		t.Fatalf("Expected 1 message published, got %d", len(pub.published))
	}
	if pub.published[0].Headers["x-validation-error"] != nil {
		t.Error("Did not expect x-validation-error header")
	}
}

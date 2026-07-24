package cloudevents

import (
	"testing"
)

type TestPayload struct {
	PaymentID string `json:"paymentId"`
	Status    string `json:"status"`
}

func TestCloudEventMarshalUnmarshal(t *testing.T) {
	payload := TestPayload{PaymentID: "123", Status: "APPROVED"}
	event := NewPlatformCloudEvent("cells/renegotiation", "br.com.platform.renegotiation.v1", payload)
	event.BuzID = "cell-a"
	event.CorrelationID = "saga-123"

	if event.ID == "" {
		t.Error("Expected generated ID, got empty string")
	}
	if event.SpecVersion != "1.0" {
		t.Errorf("Expected specversion 1.0, got %s", event.SpecVersion)
	}

	data, err := event.Marshal()
	if err != nil {
		t.Fatalf("Failed to marshal event: %v", err)
	}

	unmarshaledEvent, err := Unmarshal[TestPayload](data)
	if err != nil {
		t.Fatalf("Failed to unmarshal event: %v", err)
	}

	if unmarshaledEvent.ID != event.ID {
		t.Errorf("Expected ID %s, got %s", event.ID, unmarshaledEvent.ID)
	}
	if unmarshaledEvent.Data.PaymentID != "123" {
		t.Errorf("Expected PaymentID 123, got %s", unmarshaledEvent.Data.PaymentID)
	}
}

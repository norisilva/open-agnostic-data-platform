package cloudevents

import (
	"encoding/json"
	"time"

	"github.com/google/uuid"
)

// PlatformCloudEvent represents the standardized envelope for the platform
type PlatformCloudEvent[T any] struct {
	SpecVersion     string `json:"specversion"`
	ID              string `json:"id"`
	Source          string `json:"source"`
	Type            string `json:"type"`
	Time            string `json:"time"`
	DataContentType string `json:"datacontenttype"`
	SchemaURL       string `json:"schemaurl,omitempty"`
	BuzID           string `json:"buzid,omitempty"`
	CorrelationID   string `json:"correlationid,omitempty"`
	TraceParent     string `json:"traceparent,omitempty"`
	Data            T      `json:"data"`
}

// NewPlatformCloudEvent creates a new CloudEvent with default values and generates an ID and Time if not provided
func NewPlatformCloudEvent[T any](source, eventType string, data T) PlatformCloudEvent[T] {
	return PlatformCloudEvent[T]{
		SpecVersion:     "1.0",
		ID:              uuid.New().String(),
		Source:          source,
		Type:            eventType,
		Time:            time.Now().UTC().Format(time.RFC3339),
		DataContentType: "application/json",
		Data:            data,
	}
}

// Marshal converts the event to JSON
func (e *PlatformCloudEvent[T]) Marshal() ([]byte, error) {
	return json.Marshal(e)
}

// Unmarshal converts JSON to the event
func Unmarshal[T any](data []byte) (*PlatformCloudEvent[T], error) {
	var event PlatformCloudEvent[T]
	if err := json.Unmarshal(data, &event); err != nil {
		return nil, err
	}
	return &event, nil
}

package message

import (
	"encoding/json"
	"fmt"
	"strings"
	"time"
)

// Message represents a demo message
type Message struct {
	ID        string    `json:"id"`
	Timestamp time.Time `json:"timestamp"`
	Payload   string    `json:"payload"`
}

// New creates a new message with the given ID and payload size
func New(id string, payloadSize int) *Message {
	return &Message{
		ID:        id,
		Timestamp: time.Now(),
		Payload:   generatePayload(payloadSize),
	}
}

// ToJSON marshals the message to JSON bytes
func (m *Message) ToJSON() ([]byte, error) {
	data, err := json.Marshal(m)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal message: %w", err)
	}
	return data, nil
}

// FromJSON unmarshals JSON bytes into a message
func FromJSON(data []byte) (*Message, error) {
	var m Message
	if err := json.Unmarshal(data, &m); err != nil {
		return nil, fmt.Errorf("failed to unmarshal message: %w", err)
	}
	return &m, nil
}

// generatePayload creates a payload string of the specified size
func generatePayload(size int) string {
	if size <= 0 {
		return ""
	}
	return strings.Repeat("x", size)
}

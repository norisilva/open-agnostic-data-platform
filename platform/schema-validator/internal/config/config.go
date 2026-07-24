// Package config loads all runtime configuration from environment variables,
// following 12-Factor App principle III: "Store config in the environment".
package config

import (
	"os"
	"strconv"
	"time"
)

// Config holds all externalized runtime configuration.
type Config struct {
	// AMQP URL (RabbitMQ)
	AMQPURL string
	// Exchange name
	ExchangeName string
	// Queue to consume from
	QueueName string
	// DLQ Exchange or Queue name
	DLQName string
	// Max concurrent messages to process (controls goroutine fan-out)
	Concurrency int
	// Apicurio Schema Registry base URL
	ApicurioURL string
	// Schema cache TTL
	SchemaCacheTTL time.Duration
}

// Load reads all config from environment variables with sensible dev defaults.
func Load() *Config {
	return &Config{
		AMQPURL:        getEnv("AMQP_URL", "amqp://guest:guest@localhost:5672/"),
		ExchangeName:   getEnv("EXCHANGE_NAME", "platform.exchange"),
		QueueName:      getEnv("QUEUE_NAME", "schema-validation-queue"),
		DLQName:        getEnv("DLQ_NAME", "schema-validation-dlq"),
		Concurrency:    getEnvInt("CONCURRENCY", 10),
		ApicurioURL:    getEnv("APICURIO_URL", "http://localhost:8081"),
		SchemaCacheTTL: time.Duration(getEnvInt("SCHEMA_CACHE_TTL_SECONDS", 300)) * time.Second,
	}
}

func getEnv(key, fallback string) string {
	if value, exists := os.LookupEnv(key); exists {
		return value
	}
	return fallback
}

func getEnvInt(key string, fallback int) int {
	if value, exists := os.LookupEnv(key); exists {
		if i, err := strconv.Atoi(value); err == nil {
			return i
		}
	}
	return fallback
}

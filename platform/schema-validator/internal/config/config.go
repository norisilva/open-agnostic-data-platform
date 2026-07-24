// Package config loads all runtime configuration from environment variables,
// following 12-Factor App principle III: "Store config in the environment".
// Defaults are suitable for local development (LocalStack + Apicurio local).
// In production, all vars MUST be supplied via container env / Terraform.
package config

import (
	"os"
	"strconv"
	"time"
)

// Config holds all externalized runtime configuration.
type Config struct {
	// SQS source queue for validation input
	SQSQueueURL string
	// SQS destination queue for validated events
	SQSDestinationURL string
	// SQS dead-letter queue for rejected events
	SQSDLQUrl string
	// Max concurrent messages to process (controls goroutine fan-out)
	SQSConcurrency int
	// Apicurio Schema Registry base URL
	ApicurioURL string
	// AWS region (used by SDK)
	AWSRegion string
	// AWS endpoint override — set to LocalStack URL in dev, empty in prod
	AWSEndpoint string
	// Schema cache TTL
	SchemaCacheTTL time.Duration
}

// Load reads all config from environment variables with sensible dev defaults.
// In prod (ECS/EKS), these are injected by the Terraform task definition.
func Load() *Config {
	return &Config{
		SQSQueueURL:       getEnv("SQS_QUEUE_URL", "http://localhost:4566/000000000000/validation-queue"),
		SQSDestinationURL: getEnv("SQS_DESTINATION_URL", "http://localhost:4566/000000000000/router-queue"),
		SQSDLQUrl:         getEnv("SQS_DLQ_URL", "http://localhost:4566/000000000000/validation-dlq"),
		SQSConcurrency:    getEnvInt("SQS_CONCURRENCY", 10),
		ApicurioURL:       getEnv("APICURIO_URL", "http://localhost:8081"),
		AWSRegion:         getEnv("AWS_REGION", "us-east-1"),
		// AWS_ENDPOINT_URL: set to LocalStack in dev, empty string in prod (uses real AWS)
		AWSEndpoint:    getEnv("AWS_ENDPOINT_URL", "http://localhost:4566"),
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


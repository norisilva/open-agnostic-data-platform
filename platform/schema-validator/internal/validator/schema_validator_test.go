package validator

import (
	"testing"
	"time"

	"github.com/multiframeworks-renegociation/platform/schema-validator/internal/apicurio"
	"github.com/santhosh-tekuri/jsonschema/v5"
)

func TestSchemaValidatorCache(t *testing.T) {
	// Simple sanity test for cache
	client := apicurio.NewClient("http://localhost:8081")
	val := NewSchemaValidator(client)

	// Mocking a schema compiler and cache for testing
	compiler := jsonschema.NewCompiler()
	err := compiler.AddResource("schema.json", []byte(`{"type": "object", "properties": {"name": {"type": "string"}}}`))
	if err != nil {
		t.Fatalf("Failed to add resource: %v", err)
	}
	schema, _ := compiler.Compile("schema.json")

	val.cache["testGroup:testSchema"] = cacheItem{
		schema:    schema,
		expiresAt: time.Now().Add(5 * time.Minute),
	}

	err = val.Validate("testGroup", "testSchema", []byte(`{"name": "John"}`))
	if err != nil {
		t.Errorf("Expected valid JSON, got error: %v", err)
	}

	err = val.Validate("testGroup", "testSchema", []byte(`{"name": 123}`))
	if err == nil {
		t.Errorf("Expected invalid JSON to return error")
	}
}

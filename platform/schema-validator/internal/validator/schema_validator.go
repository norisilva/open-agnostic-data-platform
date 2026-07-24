package validator

import (
	"encoding/json"
	"fmt"
	"strings"
	"sync"
	"time"

	"github.com/santhosh-tekuri/jsonschema/v5"
	"github.com/multiframeworks-renegociation/platform/schema-validator/internal/apicurio"
)

type SchemaValidator struct {
	apicurioClient *apicurio.Client
	cache          map[string]cacheItem
	mu             sync.RWMutex
}

type cacheItem struct {
	schema    *jsonschema.Schema
	expiresAt time.Time
}

func NewSchemaValidator(client *apicurio.Client) *SchemaValidator {
	return &SchemaValidator{
		apicurioClient: client,
		cache:          make(map[string]cacheItem),
	}
}

func (v *SchemaValidator) Validate(group, artifactId string, data []byte) error {
	cacheKey := fmt.Sprintf("%s:%s", group, artifactId)

	v.mu.RLock()
	item, found := v.cache[cacheKey]
	v.mu.RUnlock()

	var schema *jsonschema.Schema

	if found && time.Now().Before(item.expiresAt) {
		schema = item.schema
	} else {
		// Fetch from Apicurio
		schemaStr, err := v.apicurioClient.GetSchema(group, artifactId)
		if err != nil {
			return fmt.Errorf("failed to fetch schema: %w", err)
		}

		compiler := jsonschema.NewCompiler()
		if err := compiler.AddResource("schema.json", strings.NewReader(schemaStr)); err != nil {
			return err
		}
		schema, err = compiler.Compile("schema.json")
		if err != nil {
			return err
		}

		// Save to cache (TTL 5 mins)
		v.mu.Lock()
		v.cache[cacheKey] = cacheItem{
			schema:    schema,
			expiresAt: time.Now().Add(5 * time.Minute),
		}
		v.mu.Unlock()
	}

	var vData interface{}
	if err := json.Unmarshal(data, &vData); err != nil {
		return err
	}

	return schema.Validate(vData)
}

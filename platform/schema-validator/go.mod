module github.com/multiframeworks-renegociation/platform/schema-validator

go 1.22

require (
	github.com/multiframeworks-renegociation/platform/cloudevents-go v0.0.0
	github.com/rabbitmq/amqp091-go v1.13.0
	github.com/santhosh-tekuri/jsonschema/v5 v5.3.1
)

require github.com/google/uuid v1.6.0 // indirect

replace github.com/multiframeworks-renegociation/platform/cloudevents-go => ../cloudevents-go

package rabbitmq

import (
	"context"
	"encoding/json"
	"fmt"
	"log"

	"sync"

	amqp "github.com/rabbitmq/amqp091-go"
	cloudevents "github.com/multiframeworks-renegociation/platform/cloudevents-go"
	"github.com/multiframeworks-renegociation/platform/schema-validator/internal/apicurio"
	"github.com/multiframeworks-renegociation/platform/schema-validator/internal/config"
	"github.com/multiframeworks-renegociation/platform/schema-validator/internal/validator"
)

type publisherChannel interface {
	Publish(exchange, key string, mandatory, immediate bool, msg amqp.Publishing) error
	Close() error
}

type schemaValidator interface {
	Validate(group, artifactId string, data []byte) error
}

type Consumer struct {
	cfg       *config.Config
	conn      *amqp.Connection
	ch        *amqp.Channel
	pubCh     publisherChannel
	pubMutex  sync.Mutex
	validator schemaValidator
}

func NewConsumer(cfg *config.Config) (*Consumer, error) {
	conn, err := amqp.Dial(cfg.AMQPURL)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to RabbitMQ: %w", err)
	}

	ch, err := conn.Channel()
	if err != nil {
		return nil, fmt.Errorf("failed to open consume channel: %w", err)
	}

	pubCh, err := conn.Channel()
	if err != nil {
		return nil, fmt.Errorf("failed to open publish channel: %w", err)
	}

	// Declare exchange
	err = ch.ExchangeDeclare(
		cfg.ExchangeName, // name
		"topic",          // type
		true,             // durable
		false,            // auto-deleted
		false,            // internal
		false,            // no-wait
		nil,              // arguments
	)
	if err != nil {
		return nil, err
	}

	// Declare queue
	q, err := ch.QueueDeclare(
		cfg.QueueName, // name
		true,          // durable
		false,         // delete when unused
		false,         // exclusive
		false,         // no-wait
		nil,           // arguments
	)
	if err != nil {
		return nil, err
	}

	// Bind queue for validation (assuming routing key "event.received" for ingest)
	err = ch.QueueBind(
		q.Name,           // queue name
		"*.event.received", // routing key pattern
		cfg.ExchangeName, // exchange
		false,
		nil,
	)
	if err != nil {
		return nil, err
	}

	// Declare DLQ
	_, err = ch.QueueDeclare(
		cfg.DLQName,   // name
		true,          // durable
		false,         // delete when unused
		false,         // exclusive
		false,         // no-wait
		nil,           // arguments
	)
	if err != nil {
		return nil, err
	}

	apiClient := apicurio.NewClient(cfg.ApicurioURL)
	val := validator.NewSchemaValidator(apiClient)

	return &Consumer{
		cfg:       cfg,
		conn:      conn,
		ch:        ch,
		pubCh:     pubCh,
		validator: val,
	}, nil
}

func (c *Consumer) Start(ctx context.Context) error {
	defer c.conn.Close()
	defer c.ch.Close()
	defer c.pubCh.Close()

	err := c.ch.Qos(c.cfg.Concurrency, 0, false)
	if err != nil {
		return err
	}

	msgs, err := c.ch.Consume(
		c.cfg.QueueName, // queue
		"",              // consumer
		false,           // auto-ack
		false,           // exclusive
		false,           // no-local
		false,           // no-wait
		nil,             // args
	)
	if err != nil {
		return err
	}

	log.Printf("Starting RabbitMQ consumer on queue %s", c.cfg.QueueName)

	sem := make(chan struct{}, c.cfg.Concurrency)

	for {
		select {
		case <-ctx.Done():
			return nil
		case msg, ok := <-msgs:
			if !ok {
				return nil
			}
			sem <- struct{}{}
			go func(m amqp.Delivery) {
				defer func() { <-sem }()
				c.processMessage(m)
			}(msg)
		}
	}
}

func (c *Consumer) processMessage(msg amqp.Delivery) {
	ce, err := cloudevents.Unmarshal[json.RawMessage](msg.Body)
	if err != nil {
		log.Printf("Failed to parse CloudEvent: %v", err)
		c.publishToDLQ(msg.Body, "Parse failed: "+err.Error())
		msg.Ack(false)
		return
	}

	// Group is cellId (BuzID), artifactId is eventType (Type)
	group := ce.BuzID
	if group == "" {
		group = "default"
	}
	artifactId := ce.Type

	err = c.validator.Validate(group, artifactId, ce.Data)
	if err != nil {
		log.Printf("Validation failed for %s/%s: %v", group, artifactId, err)
		c.publishToDLQ(msg.Body, fmt.Sprintf("Schema validation failed: %v", err))
		msg.Ack(false)
		return
	}

	log.Printf("Validation passed for %s/%s", group, artifactId)

	// Publish to destination exchange with the eventType as routing key
	err = c.publishValidated(ce.Type, msg.Body)
	if err != nil {
		log.Printf("Failed to publish validated event: %v", err)
		msg.Nack(false, true) // requeue to try again later
		return
	}
	msg.Ack(false)
}

func (c *Consumer) publishToDLQ(body []byte, reason string) {
	c.pubMutex.Lock()
	defer c.pubMutex.Unlock()

	err := c.pubCh.Publish(
		"",            // exchange (default exchange routes directly to queue)
		c.cfg.DLQName, // routing key = queue name
		false,         // mandatory
		false,         // immediate
		amqp.Publishing{
			ContentType: "application/json",
			Body:        body,
			Headers: amqp.Table{
				"x-validation-error": reason,
			},
		},
	)
	if err != nil {
		log.Printf("Failed to publish to DLQ: %v", err)
	}
}

func (c *Consumer) publishValidated(routingKey string, body []byte) error {
	c.pubMutex.Lock()
	defer c.pubMutex.Unlock()

	return c.pubCh.Publish(
		c.cfg.ExchangeName, // exchange
		routingKey,         // routing key
		false,              // mandatory
		false,              // immediate
		amqp.Publishing{
			ContentType: "application/json",
			Body:        body,
		},
	)
}

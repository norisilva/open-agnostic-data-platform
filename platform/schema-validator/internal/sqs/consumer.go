package sqs

import (
	"context"
	"encoding/json"
	"log"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/sqs"
	"github.com/aws/aws-sdk-go-v2/service/sqs/types"
	cfg "github.com/multiframeworks-renegociation/platform/schema-validator/internal/config"
	"github.com/multiframeworks-renegociation/platform/schema-validator/internal/validator"
	"github.com/multiframeworks-renegociation/platform/schema-validator/internal/apicurio"
)

type Consumer struct {
	client       *sqs.Client
	config       *cfg.Config
	val          *validator.SchemaValidator
}

func NewConsumer(c *cfg.Config) (*Consumer, error) {
	// Load AWS config
	awsCfg, err := config.LoadDefaultConfig(context.TODO(), 
		config.WithRegion(c.AWSRegion),
		config.WithEndpointResolverWithOptions(aws.EndpointResolverWithOptionsFunc(func(service, region string, options ...interface{}) (aws.Endpoint, error) {
			return aws.Endpoint{URL: c.AWSEndpoint}, nil
		})),
	)
	if err != nil {
		return nil, err
	}

	sqsClient := sqs.NewFromConfig(awsCfg)
	apicurioClient := apicurio.NewClient(c.ApicurioURL)
	schemaVal := validator.NewSchemaValidator(apicurioClient)

	return &Consumer{
		client: sqsClient,
		config: c,
		val:    schemaVal,
	}, nil
}

func (c *Consumer) Start(ctx context.Context) error {
	log.Printf("Starting SQS consumer on %s", c.config.SQSQueueURL)
	for {
		select {
		case <-ctx.Done():
			return nil
		default:
			out, err := c.client.ReceiveMessage(ctx, &sqs.ReceiveMessageInput{
				QueueUrl:            aws.String(c.config.SQSQueueURL),
				MaxNumberOfMessages: 10,
				WaitTimeSeconds:     20,
			})
			if err != nil {
				log.Printf("Error receiving message: %v", err)
				continue
			}

			for _, msg := range out.Messages {
				c.processMessage(ctx, msg)
			}
		}
	}
}

func (c *Consumer) processMessage(ctx context.Context, msg types.Message) {
	var cloudEvent map[string]interface{}
	if err := json.Unmarshal([]byte(*msg.Body), &cloudEvent); err != nil {
		c.rejectMessage(ctx, msg, "Invalid CloudEvent JSON")
		return
	}

	// Assuming buzid is the group and type is the artifactId for Apicurio
	group, _ := cloudEvent["buzid"].(string)
	eventType, _ := cloudEvent["type"].(string)
	data, hasData := cloudEvent["data"]

	if group == "" || eventType == "" || !hasData {
		c.rejectMessage(ctx, msg, "Missing buzid, type or data in CloudEvent")
		return
	}

	dataBytes, _ := json.Marshal(data)
	err := c.val.Validate(group, eventType, dataBytes)

	if err != nil {
		log.Printf("Validation failed for %s: %v", eventType, err)
		c.rejectMessage(ctx, msg, err.Error())
	} else {
		c.acceptMessage(ctx, msg)
	}
}

func (c *Consumer) acceptMessage(ctx context.Context, msg types.Message) {
	// Re-publish to destination
	_, err := c.client.SendMessage(ctx, &sqs.SendMessageInput{
		QueueUrl:    aws.String(c.config.SQSDestinationURL),
		MessageBody: msg.Body,
	})
	if err == nil {
		c.client.DeleteMessage(ctx, &sqs.DeleteMessageInput{
			QueueUrl:      aws.String(c.config.SQSQueueURL),
			ReceiptHandle: msg.ReceiptHandle,
		})
	}
}

func (c *Consumer) rejectMessage(ctx context.Context, msg types.Message, reason string) {
	_, err := c.client.SendMessage(ctx, &sqs.SendMessageInput{
		QueueUrl:    aws.String(c.config.SQSDLQUrl),
		MessageBody: msg.Body,
		MessageAttributes: map[string]types.MessageAttributeValue{
			"RejectReason": {
				DataType:    aws.String("String"),
				StringValue: aws.String(reason),
			},
		},
	})
	if err == nil {
		c.client.DeleteMessage(ctx, &sqs.DeleteMessageInput{
			QueueUrl:      aws.String(c.config.SQSQueueURL),
			ReceiptHandle: msg.ReceiptHandle,
		})
	}
}

package main

import (
	"context"
	"log"
	"os"
	"os/signal"
	"syscall"

	"github.com/multiframeworks-renegociation/platform/schema-validator/internal/config"
	"github.com/multiframeworks-renegociation/platform/schema-validator/internal/sqs"
)

func main() {
	cfg := config.Load()
	
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	consumer, err := sqs.NewConsumer(cfg)
	if err != nil {
		log.Fatalf("Failed to initialize consumer: %v", err)
	}

	go func() {
		if err := consumer.Start(ctx); err != nil {
			log.Fatalf("Consumer error: %v", err)
		}
	}()

	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	log.Println("Shutting down...")
	cancel()
}

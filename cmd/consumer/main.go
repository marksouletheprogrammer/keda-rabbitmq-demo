package main

import (
	"log"
	"os"
	"os/signal"
	"strconv"
	"syscall"
	"time"

	amqp "github.com/rabbitmq/amqp091-go"

	"github.com/marksouletheprogrammer/keda-rabbitmq-demo/internal/message"
	"github.com/marksouletheprogrammer/keda-rabbitmq-demo/internal/rabbitmq"
)

type Config struct {
	RabbitMQURL       string
	QueueName         string
	ProcessingDelayMS int
	PrefetchCount     int
}

func loadConfig() *Config {
	config := &Config{
		RabbitMQURL:       getEnv("RABBITMQ_URL", "amqp://guest:guest@localhost:5672/"),
		QueueName:         getEnv("QUEUE_NAME", "demo-queue"),
		ProcessingDelayMS: getEnvInt("PROCESSING_DELAY_MS", 100),
		PrefetchCount:     getEnvInt("PREFETCH_COUNT", 1),
	}

	log.Printf("Configuration loaded:")
	log.Printf("  Queue Name: %s", config.QueueName)
	log.Printf("  Processing Delay: %d ms", config.ProcessingDelayMS)
	log.Printf("  Prefetch Count: %d", config.PrefetchCount)

	return config
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

func getEnvInt(key string, defaultValue int) int {
	if value := os.Getenv(key); value != "" {
		if intValue, err := strconv.Atoi(value); err == nil {
			return intValue
		}
	}
	return defaultValue
}

func main() {
	log.Println("Starting Consumer...")

	config := loadConfig()

	// Connect to RabbitMQ
	client, err := rabbitmq.NewClient(config.RabbitMQURL)
	if err != nil {
		log.Fatalf("Failed to create RabbitMQ client: %v", err)
	}
	defer client.Close()

	// Declare queue
	if err := client.DeclareQueue(config.QueueName); err != nil {
		log.Fatalf("Failed to declare queue: %v", err)
	}

	// Start consuming
	msgs, err := client.Consume(config.QueueName, config.PrefetchCount)
	if err != nil {
		log.Fatalf("Failed to start consuming: %v", err)
	}

	// Setup graceful shutdown
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)

	// Process messages
	doneChan := make(chan struct{})
	go consume(msgs, config, doneChan)

	// Wait for shutdown signal
	sig := <-sigChan
	log.Printf("Received signal %v, shutting down gracefully...", sig)

	// Wait for consumer to finish processing current messages
	select {
	case <-doneChan:
		log.Println("Consumer stopped successfully")
	case <-time.After(30 * time.Second):
		log.Println("Shutdown timeout, forcing exit")
	}
}

func consume(msgs <-chan amqp.Delivery, config *Config, doneChan chan struct{}) {
	messageCount := 0
	startTime := time.Now()
	lastLogTime := startTime

	processingDelay := time.Duration(config.ProcessingDelayMS) * time.Millisecond

	log.Println("Starting to consume messages...")

	for msg := range msgs {
		messageCount++

		// Parse message
		parsedMsg, err := message.FromJSON(msg.Body)
		if err != nil {
			log.Printf("Error parsing message: %v", err)
			msg.Nack(false, false) // Reject message
			continue
		}

		// Simulate processing work
		time.Sleep(processingDelay)

		// Calculate message latency
		latency := time.Since(parsedMsg.Timestamp)

		// Acknowledge message
		if err := msg.Ack(false); err != nil {
			log.Printf("Error acknowledging message: %v", err)
			continue
		}

		// Log statistics every 10 seconds
		if time.Since(lastLogTime) >= 10*time.Second {
			elapsed := time.Since(startTime).Seconds()
			rate := float64(messageCount) / elapsed
			log.Printf("Stats: %d messages processed, average rate: %.2f msg/sec, last latency: %v",
				messageCount, rate, latency.Round(time.Millisecond))
			lastLogTime = time.Now()
		}
	}

	log.Printf("Message channel closed. Total messages processed: %d", messageCount)
	close(doneChan)
}

package main

import (
	"fmt"
	"log"
	"os"
	"os/signal"
	"strconv"
	"syscall"
	"time"

	"github.com/marksouletheprogrammer/keda-rabbitmq-demo/internal/message"
	"github.com/marksouletheprogrammer/keda-rabbitmq-demo/internal/rabbitmq"
)

type Config struct {
	RabbitMQURL string
	QueueName   string
	MessageRate int
	MessageSize int
}

func loadConfig() *Config {
	config := &Config{
		RabbitMQURL: getEnv("RABBITMQ_URL", "amqp://guest:guest@localhost:5672/"),
		QueueName:   getEnv("QUEUE_NAME", "demo-queue"),
		MessageRate: getEnvInt("MESSAGE_RATE", 10),
		MessageSize: getEnvInt("MESSAGE_SIZE", 1024),
	}

	log.Printf("Configuration loaded:")
	log.Printf("  Queue Name: %s", config.QueueName)
	log.Printf("  Message Rate: %d msg/sec", config.MessageRate)
	log.Printf("  Message Size: %d bytes", config.MessageSize)

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
	log.Println("Starting Producer...")

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

	// Setup graceful shutdown
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)

	// Start producing messages
	stopChan := make(chan struct{})
	doneChan := make(chan struct{})

	go produce(client, config, stopChan, doneChan)

	// Wait for shutdown signal
	sig := <-sigChan
	log.Printf("Received signal %v, shutting down gracefully...", sig)
	close(stopChan)

	// Wait for producer to finish
	<-doneChan
	log.Println("Producer stopped successfully")
}

func produce(client *rabbitmq.Client, config *Config, stopChan, doneChan chan struct{}) {
	defer close(doneChan)

	messageCount := 0
	ticker := time.NewTicker(time.Second / time.Duration(config.MessageRate))
	defer ticker.Stop()

	startTime := time.Now()
	lastLogTime := startTime

	log.Printf("Starting to produce messages at %d msg/sec...", config.MessageRate)

	for {
		select {
		case <-stopChan:
			log.Printf("Stop signal received. Total messages sent: %d", messageCount)
			return
		case <-ticker.C:
			// Create and send message
			messageCount++
			msg := message.New(fmt.Sprintf("msg-%d", messageCount), config.MessageSize)

			body, err := msg.ToJSON()
			if err != nil {
				log.Printf("Error marshaling message: %v", err)
				continue
			}

			if err := client.Publish(config.QueueName, body); err != nil {
				log.Printf("Error publishing message: %v", err)
				continue
			}

			// Log statistics every 10 seconds
			if time.Since(lastLogTime) >= 10*time.Second {
				elapsed := time.Since(startTime).Seconds()
				rate := float64(messageCount) / elapsed
				log.Printf("Stats: %d messages sent, average rate: %.2f msg/sec", messageCount, rate)
				lastLogTime = time.Now()
			}
		}
	}
}

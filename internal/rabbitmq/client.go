package rabbitmq

import (
	"fmt"
	"log"
	"time"

	amqp "github.com/rabbitmq/amqp091-go"
)

// Client represents a RabbitMQ client
type Client struct {
	conn    *amqp.Connection
	channel *amqp.Channel
	url     string
}

// NewClient creates a new RabbitMQ client
func NewClient(url string) (*Client, error) {
	client := &Client{
		url: url,
	}

	if err := client.connect(); err != nil {
		return nil, err
	}

	return client, nil
}

// connect establishes connection to RabbitMQ with retry logic
func (c *Client) connect() error {
	var err error
	maxRetries := 10
	retryDelay := 2 * time.Second

	for i := 0; i < maxRetries; i++ {
		c.conn, err = amqp.Dial(c.url)
		if err == nil {
			c.channel, err = c.conn.Channel()
			if err == nil {
				log.Println("Successfully connected to RabbitMQ")
				return nil
			}
			c.conn.Close()
		}

		log.Printf("Failed to connect to RabbitMQ (attempt %d/%d): %v", i+1, maxRetries, err)
		if i < maxRetries-1 {
			time.Sleep(retryDelay)
		}
	}

	return fmt.Errorf("failed to connect to RabbitMQ after %d attempts: %w", maxRetries, err)
}

// DeclareQueue declares a durable queue
func (c *Client) DeclareQueue(queueName string) error {
	_, err := c.channel.QueueDeclare(
		queueName, // name
		true,      // durable
		false,     // delete when unused
		false,     // exclusive
		false,     // no-wait
		nil,       // arguments
	)
	if err != nil {
		return fmt.Errorf("failed to declare queue: %w", err)
	}
	log.Printf("Queue '%s' declared", queueName)
	return nil
}

// Publish publishes a message to the queue
func (c *Client) Publish(queueName string, body []byte) error {
	err := c.channel.Publish(
		"",        // exchange
		queueName, // routing key
		false,     // mandatory
		false,     // immediate
		amqp.Publishing{
			DeliveryMode: amqp.Persistent,
			ContentType:  "application/json",
			Body:         body,
		},
	)
	if err != nil {
		return fmt.Errorf("failed to publish message: %w", err)
	}
	return nil
}

// Consume starts consuming messages from the queue
func (c *Client) Consume(queueName string, prefetchCount int) (<-chan amqp.Delivery, error) {
	err := c.channel.Qos(
		prefetchCount, // prefetch count
		0,             // prefetch size
		false,         // global
	)
	if err != nil {
		return nil, fmt.Errorf("failed to set QoS: %w", err)
	}

	msgs, err := c.channel.Consume(
		queueName, // queue
		"",        // consumer
		false,     // auto-ack
		false,     // exclusive
		false,     // no-local
		false,     // no-wait
		nil,       // args
	)
	if err != nil {
		return nil, fmt.Errorf("failed to register consumer: %w", err)
	}

	log.Printf("Started consuming from queue '%s' with prefetch count %d", queueName, prefetchCount)
	return msgs, nil
}

// Close closes the RabbitMQ connection
func (c *Client) Close() error {
	if c.channel != nil {
		if err := c.channel.Close(); err != nil {
			return err
		}
	}
	if c.conn != nil {
		if err := c.conn.Close(); err != nil {
			return err
		}
	}
	log.Println("RabbitMQ connection closed")
	return nil
}

// IsClosed checks if the connection is closed
func (c *Client) IsClosed() bool {
	return c.conn == nil || c.conn.IsClosed()
}

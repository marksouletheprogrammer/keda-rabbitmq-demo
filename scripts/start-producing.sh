#!/bin/bash

set -e

echo "=========================================="
echo "Starting Message Production"
echo "=========================================="
echo ""

# Scale producer to 1 replica
echo "Scaling producer to 1 replica..."
kubectl scale deployment/producer -n keda-demo --replicas=1

echo "Waiting for producer to be ready..."
kubectl wait --for=condition=available --timeout=60s deployment/producer -n keda-demo

echo ""
echo "✅ Producer started successfully!"
echo ""
echo "Producer is now sending messages to RabbitMQ."
echo ""
echo "To view logs:"
echo "  make logs-producer"
echo ""
echo "To check queue status:"
echo "  make demo-status"
echo ""

#!/bin/bash

set -e

echo "=========================================="
echo "Starting Message Consumption"
echo "=========================================="
echo ""

# Scale consumer to 1 replica
echo "Scaling consumer to 1 replica..."
kubectl scale deployment/consumer -n keda-demo --replicas=1

echo "Waiting for consumer to be ready..."
kubectl wait --for=condition=available --timeout=60s deployment/consumer -n keda-demo

echo ""
echo "✅ Consumer started successfully!"
echo ""
echo "Consumer is now processing messages from RabbitMQ."
echo ""
echo "To view logs:"
echo "  make logs-consumer"
echo ""
echo "To check queue status:"
echo "  make demo-status"
echo ""
echo "Note: In Layer 3, KEDA will automatically scale consumers based on queue depth."
echo ""

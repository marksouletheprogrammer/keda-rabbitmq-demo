#!/bin/bash

set -e

echo "=========================================="
echo "Demo Status"
echo "=========================================="
echo ""

# Check if namespace exists
if ! kubectl get namespace keda-demo &> /dev/null; then
    echo "❌ Namespace 'keda-demo' not found. Please run 'make deploy' first."
    exit 1
fi

echo "📊 Pod Status:"
echo ""
kubectl get pods -n keda-demo -l 'app in (producer,consumer,rabbitmq)'
echo ""

echo "📦 Deployment Replicas:"
echo ""
kubectl get deployments -n keda-demo -l 'app in (producer,consumer)' -o wide
echo ""

echo "🐰 RabbitMQ Queue Status:"
echo ""

# Try to get queue info from RabbitMQ management API
RABBITMQ_POD=$(kubectl get pods -n keda-demo -l app=rabbitmq -o jsonpath='{.items[0].metadata.name}')

if [ -n "$RABBITMQ_POD" ]; then
    echo "Fetching queue information..."
    kubectl exec -n keda-demo "$RABBITMQ_POD" -- rabbitmqadmin list queues name messages consumers -f tsv 2>/dev/null || \
    echo "⚠️  Could not fetch queue stats. Check RabbitMQ UI at: make rabbitmq-ui"
else
    echo "⚠️  RabbitMQ pod not found"
fi

echo ""
echo "=========================================="
echo "Quick Actions:"
echo "=========================================="
echo ""
echo "  make rabbitmq-ui       - Open RabbitMQ Management UI"
echo "  make logs-producer     - View producer logs"
echo "  make logs-consumer     - View consumer logs"
echo "  make start-producing   - Start message production"
echo "  make start-consuming   - Start message consumption"
echo ""

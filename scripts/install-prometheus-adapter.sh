#!/bin/bash

set -e

echo "=========================================="
echo "Installing Prometheus Adapter"
echo "=========================================="
echo ""

# Check if helm is installed
if ! command -v helm &> /dev/null; then
    echo "Error: helm is not installed. Please install helm first."
    echo "Visit: https://helm.sh/docs/intro/install/"
    exit 1
fi

# Check if Prometheus is running
if ! kubectl get svc prometheus -n keda-demo &> /dev/null; then
    echo "Error: Prometheus not found in keda-demo namespace."
    echo "Please run 'make deploy' first to set up infrastructure."
    exit 1
fi

# Add Prometheus Community Helm repository
echo "Adding Prometheus Community Helm repository..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install or upgrade Prometheus Adapter
echo "Installing Prometheus Adapter..."
helm upgrade --install prometheus-adapter prometheus-community/prometheus-adapter \
  --namespace keda-demo \
  --set prometheus.url=http://prometheus.keda-demo.svc.cluster.local \
  --set prometheus.port=9090 \
  --set rules.default=false \
  --set rules.custom[0].seriesQuery='rabbitmq_queue_messages_ready{namespace="keda-demo",queue="demo-queue"}' \
  --set rules.custom[0].resources.overrides.namespace.resource="namespace" \
  --set rules.custom[0].name.as="rabbitmq_queue_messages_ready" \
  --set rules.custom[0].metricsQuery='sum(rabbitmq_queue_messages_ready{namespace="keda-demo",queue="demo-queue"})' \
  --set resources.requests.cpu=100m \
  --set resources.requests.memory=128Mi \
  --set resources.limits.cpu=500m \
  --set resources.limits.memory=256Mi \
  --wait

echo ""
echo "Waiting for Prometheus Adapter to be ready..."
kubectl wait --for=condition=available --timeout=120s deployment/prometheus-adapter -n keda-demo

echo ""
echo "✅ Prometheus Adapter installed successfully!"
echo ""
echo "Verifying custom metrics..."
sleep 5

# Try to get custom metrics
if kubectl get --raw "/apis/custom.metrics.k8s.io/v1beta1" &> /dev/null; then
    echo "✅ Custom metrics API is available"
else
    echo "⚠️  Custom metrics API not yet available. This may take a few moments."
fi

echo ""
echo "Prometheus Adapter Components:"
kubectl get pods -n keda-demo -l app.kubernetes.io/name=prometheus-adapter
echo ""

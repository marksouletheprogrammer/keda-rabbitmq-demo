#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

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
  --values "${PROJECT_ROOT}/k8s/autoscaling/prometheus-adapter/values.yaml" \
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

#!/bin/bash

set -e

echo "=========================================="
echo "Installing KEDA"
echo "=========================================="

# Check if helm is installed
if ! command -v helm &> /dev/null; then
    echo "Error: helm is not installed. Please install helm first."
    echo "Visit: https://helm.sh/docs/intro/install/"
    exit 1
fi

# Add KEDA Helm repository
echo "Adding KEDA Helm repository..."
helm repo add kedacore https://kedacore.github.io/charts
helm repo update

# Install or upgrade KEDA
echo "Installing KEDA..."
helm upgrade --install keda kedacore/keda \
  --namespace keda \
  --create-namespace \
  --set prometheus.metricServer.enabled=true \
  --set prometheus.operator.enabled=true \
  --set prometheus.operator.podMonitor.enabled=false \
  --set serviceAccount.operator.create=true \
  --set serviceAccount.metricServer.create=true \
  --set resources.operator.requests.cpu=100m \
  --set resources.operator.requests.memory=100Mi \
  --set resources.operator.limits.cpu=1000m \
  --set resources.operator.limits.memory=1000Mi \
  --set resources.metricServer.requests.cpu=100m \
  --set resources.metricServer.requests.memory=100Mi \
  --set resources.metricServer.limits.cpu=1000m \
  --set resources.metricServer.limits.memory=1000Mi \
  --wait

echo ""
echo "Waiting for KEDA operator to be ready..."
kubectl wait --for=condition=available --timeout=120s deployment/keda-operator -n keda
kubectl wait --for=condition=available --timeout=120s deployment/keda-operator-metrics-apiserver -n keda

echo ""
echo "✅ KEDA installed successfully!"
echo ""
echo "KEDA Components:"
kubectl get pods -n keda

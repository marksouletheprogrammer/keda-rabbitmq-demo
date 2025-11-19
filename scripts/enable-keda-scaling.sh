#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "=========================================="
echo "Enabling KEDA Autoscaling"
echo "=========================================="
echo ""

# Check if HPA is active
if kubectl get hpa consumer-hpa -n keda-demo &> /dev/null; then
    echo "❌ Error: HPA autoscaling is currently active."
    echo "Please disable HPA first: make disable-hpa"
    exit 1
fi

# Check if Prometheus Adapter is installed (conflicts with KEDA)
if helm list -n keda-demo | grep -q prometheus-adapter; then
    echo "⚠️  Prometheus Adapter is installed and conflicts with KEDA"
    echo "   Uninstalling Prometheus Adapter..."
    helm uninstall prometheus-adapter -n keda-demo
    echo "   Waiting for Prometheus Adapter to be removed..."
    sleep 10
fi

# Check if KEDA is installed, reinstall if needed
if ! kubectl get deployment keda-operator -n keda &> /dev/null; then
    echo "KEDA not found. Installing..."
    echo ""
    helm repo add kedacore https://kedacore.github.io/charts
    helm repo update
    helm install keda kedacore/keda --namespace keda --create-namespace --wait
    echo "✅ KEDA installed"
    echo ""
fi

# Apply ScaledObject
echo "1. Applying KEDA ScaledObject (using Prometheus scaler)..."
kubectl apply -f "${PROJECT_ROOT}/k8s/autoscaling/keda/scaled-object.yaml"
echo "✅ ScaledObject created"
echo ""

# Wait for ScaledObject to be ready
echo "2. Waiting for ScaledObject to initialize..."
sleep 5

echo ""
echo "=========================================="
echo "✅ KEDA Autoscaling Enabled!"
echo "=========================================="
echo ""
echo "ScaledObject Status:"
kubectl get scaledobject -n keda-demo
echo ""
echo "KEDA will scale consumer from 0 to 10 replicas based on queue depth."
echo "Using Prometheus scaler to query RabbitMQ metrics."
echo ""
echo "=========================================="
echo "Next Steps:"
echo "=========================================="
echo ""
echo "1. Start producing messages: make start-producing"
echo "2. Watch KEDA scaling: watch kubectl get scaledobject -n keda-demo"
echo "3. Check status: make scaling-status"
echo "4. View RabbitMQ queue: make rabbitmq-ui"
echo ""
echo "Note: KEDA can scale to 0 replicas when queue is empty!"
echo ""

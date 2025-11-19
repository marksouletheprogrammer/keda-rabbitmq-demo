#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "=========================================="
echo " Enabling HPA + Prometheus Adapter Autoscaling"
echo "=========================================="
echo ""

# Check if KEDA scaling is active
if kubectl get scaledobject consumer-scaledobject -n keda-demo &> /dev/null; then
    echo " Error: KEDA autoscaling is currently active!"
    echo ""
    echo "Please disable KEDA first:"
    echo "  make disable-keda"
    echo ""
    exit 1
fi

# Check if KEDA is installed (conflicts with Prometheus Adapter)
if helm list -n keda | grep -q keda; then
    echo "  KEDA is installed and conflicts with Prometheus Adapter"
    echo "   Temporarily uninstalling KEDA..."
    helm uninstall keda -n keda
    echo "   Waiting for KEDA to be removed..."
    sleep 10
fi

# Check if Prometheus Adapter is installed
if ! kubectl get deployment prometheus-adapter -n keda-demo &> /dev/null; then
    echo "Prometheus Adapter not found. Installing..."
    "${SCRIPT_DIR}/install-prometheus-adapter.sh"
    echo ""
fi

# Apply HPA
echo "1. Applying HPA configuration..."
kubectl apply -f "${PROJECT_ROOT}/k8s/autoscaling/prometheus-adapter/hpa-prometheus.yaml"
echo "✅ HPA created"
echo ""

# Wait a moment for HPA to initialize
echo "2. Waiting for HPA to initialize..."
sleep 5

# Scale consumer to 1 replica if at 0
CURRENT_REPLICAS=$(kubectl get deployment consumer -n keda-demo -o jsonpath='{.spec.replicas}')
if [ "$CURRENT_REPLICAS" -eq 0 ]; then
    echo "3. Scaling consumer to 1 replica (HPA minimum)..."
    kubectl scale deployment/consumer -n keda-demo --replicas=1
    kubectl wait --for=condition=available --timeout=60s deployment/consumer -n keda-demo
    echo "✅ Consumer scaled to 1 replica"
else
    echo "3. Consumer already running with $CURRENT_REPLICAS replica(s)"
fi
echo ""

echo "=========================================="
echo "✅ HPA Autoscaling Enabled!"
echo "=========================================="
echo ""
echo "HPA Status:"
kubectl get hpa -n keda-demo
echo ""
echo "Current Metrics:"
kubectl get --raw "/apis/custom.metrics.k8s.io/v1beta1/namespaces/keda-demo/services/rabbitmq/rabbitmq_queue_messages_ready" 2>/dev/null | jq '.' || echo "Metrics not yet available (may take a minute)"
echo ""
echo "=========================================="
echo "Next Steps:"
echo "=========================================="
echo ""
echo "1. Start producing messages: make start-producing"
echo "2. Watch HPA scaling: watch kubectl get hpa -n keda-demo"
echo "3. Check status: make scaling-status"
echo "4. View RabbitMQ queue: make rabbitmq-ui"
echo ""

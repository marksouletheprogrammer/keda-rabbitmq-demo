#!/bin/bash

set -e

echo "=========================================="
echo "Autoscaling Status"
echo "=========================================="
echo ""

# Check which autoscaling method is active
HPA_ACTIVE=false
KEDA_ACTIVE=false

if kubectl get hpa consumer-hpa -n keda-demo &> /dev/null; then
    HPA_ACTIVE=true
fi

if kubectl get scaledobject consumer-scaledobject -n keda-demo &> /dev/null; then
    KEDA_ACTIVE=true
fi

# Display active method
echo "📊 Active Autoscaling Method:"
echo ""
if [ "$HPA_ACTIVE" = true ]; then
    echo "  ✅ HPA + Prometheus Adapter"
elif [ "$KEDA_ACTIVE" = true ]; then
    echo "  ✅ KEDA"
else
    echo "  ❌ None (manual scaling only)"
fi
echo ""

# Show consumer deployment status
echo "📦 Consumer Deployment:"
echo ""
kubectl get deployment consumer -n keda-demo
echo ""

# Show HPA details if active
if [ "$HPA_ACTIVE" = true ]; then
    echo "📈 HPA Details:"
    echo ""
    kubectl get hpa consumer-hpa -n keda-demo
    echo ""
    
    echo "Current Metrics:"
    kubectl get --raw "/apis/custom.metrics.k8s.io/v1beta1/namespaces/keda-demo/services/rabbitmq/rabbitmq_queue_messages_ready" 2>/dev/null | jq '.' || echo "  Metrics not yet available"
    echo ""
fi

# Show KEDA details if active
if [ "$KEDA_ACTIVE" = true ]; then
    echo "📈 KEDA ScaledObject Details:"
    echo ""
    kubectl get scaledobject consumer-scaledobject -n keda-demo
    echo ""
    kubectl describe scaledobject consumer-scaledobject -n keda-demo | grep -A 10 "Status:" || true
    echo ""
fi

# Show RabbitMQ queue status
echo "🐰 RabbitMQ Queue Status:"
echo ""
RABBITMQ_POD=$(kubectl get pods -n keda-demo -l app=rabbitmq -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -n "$RABBITMQ_POD" ]; then
    kubectl exec -n keda-demo "$RABBITMQ_POD" -- rabbitmqadmin list queues name messages consumers -f tsv 2>/dev/null || \
    echo "  Could not fetch queue stats. Check RabbitMQ UI: make rabbitmq-ui"
else
    echo "  RabbitMQ pod not found"
fi

echo ""
echo "=========================================="
echo "Quick Actions:"
echo "=========================================="
echo ""
if [ "$HPA_ACTIVE" = false ] && [ "$KEDA_ACTIVE" = false ]; then
    echo "  make enable-hpa    - Enable HPA + Prometheus Adapter"
    echo "  make enable-keda   - Enable KEDA autoscaling"
elif [ "$HPA_ACTIVE" = true ]; then
    echo "  make disable-hpa   - Disable HPA autoscaling"
    echo "  make enable-keda   - Switch to KEDA autoscaling"
elif [ "$KEDA_ACTIVE" = true ]; then
    echo "  make disable-keda  - Disable KEDA autoscaling"
    echo "  make enable-hpa    - Switch to HPA autoscaling"
fi
echo ""

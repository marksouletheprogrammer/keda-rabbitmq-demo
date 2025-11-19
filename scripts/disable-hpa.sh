#!/bin/bash

set -e

echo "=========================================="
echo "Disabling HPA + Prometheus Adapter Scaling"
echo "=========================================="
echo ""

# Check if HPA exists
if ! kubectl get hpa consumer-hpa -n keda-demo &> /dev/null; then
    echo "ℹ️  HPA is not currently active."
    exit 0
fi

# Delete HPA
echo "1. Deleting HPA..."
kubectl delete hpa consumer-hpa -n keda-demo
echo "✅ HPA deleted"
echo ""

# Scale consumer to 0 to reset state
echo "2. Scaling consumer to 0 replicas..."
kubectl scale deployment/consumer -n keda-demo --replicas=0
echo "✅ Consumer scaled to 0"
echo ""

echo "=========================================="
echo "✅ HPA Autoscaling Disabled!"
echo "=========================================="
echo ""

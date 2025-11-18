#!/bin/bash

set -e

echo "=========================================="
echo "Disabling KEDA Autoscaling"
echo "=========================================="
echo ""

# Check if ScaledObject exists
if ! kubectl get scaledobject consumer-scaledobject -n keda-demo &> /dev/null; then
    echo "ℹ️  KEDA autoscaling is not currently active."
    exit 0
fi

# Delete ScaledObject
echo "1. Deleting ScaledObject..."
kubectl delete scaledobject consumer-scaledobject -n keda-demo
echo "✅ ScaledObject deleted"
echo ""

# Scale consumer to 0 to reset state
echo "2. Scaling consumer to 0 replicas..."
kubectl scale deployment/consumer -n keda-demo --replicas=0
echo "✅ Consumer scaled to 0"
echo ""

echo "=========================================="
echo "✅ KEDA Autoscaling Disabled!"
echo "=========================================="
echo ""

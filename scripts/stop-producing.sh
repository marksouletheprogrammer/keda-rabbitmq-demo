#!/bin/bash

set -e

echo "=========================================="
echo "Stopping Message Production"
echo "=========================================="
echo ""

# Scale producer to 0 replicas
echo "Scaling producer to 0 replicas..."
kubectl scale deployment/producer -n keda-demo --replicas=0

echo ""
echo "✅ Producer stopped successfully!"
echo ""
echo "To check queue status:"
echo "  make demo-status"
echo ""

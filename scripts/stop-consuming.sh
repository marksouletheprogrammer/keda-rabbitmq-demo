#!/bin/bash

set -e

echo "=========================================="
echo "Stopping Message Consumption"
echo "=========================================="
echo ""

# Scale consumer to 0 replicas
echo "Scaling consumer to 0 replicas..."
kubectl scale deployment/consumer -n keda-demo --replicas=0

echo ""
echo "✅ Consumer stopped successfully!"
echo ""
echo "Messages will remain in the queue until consumption resumes."
echo ""
echo "To check queue status:"
echo "  make demo-status"
echo ""

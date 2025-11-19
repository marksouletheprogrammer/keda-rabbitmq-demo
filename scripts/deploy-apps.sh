#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "=========================================="
echo "Deploying Applications"
echo "=========================================="
echo ""

# Check if namespace exists
if ! kubectl get namespace keda-demo &> /dev/null; then
    echo "❌ Error: Namespace 'keda-demo' not found."
    echo "Please run 'make deploy' first to set up infrastructure."
    exit 1
fi

# Build images
echo "1. Building Docker images..."
"${SCRIPT_DIR}/build-images.sh"
echo ""

# Deploy ConfigMap
echo "2. Deploying ConfigMap..."
kubectl apply -f "${PROJECT_ROOT}/k8s/apps/app-configmap.yaml"
echo "✅ ConfigMap deployed"
echo ""

# Deploy Producer
echo "3. Deploying Producer..."
kubectl apply -f "${PROJECT_ROOT}/k8s/apps/producer-deployment.yaml"
echo "✅ Producer deployment created"
echo ""

# Deploy Consumer
echo "4. Deploying Consumer..."
kubectl apply -f "${PROJECT_ROOT}/k8s/apps/consumer-deployment.yaml"
echo "✅ Consumer deployment created"
echo ""

echo "=========================================="
echo "✅ Applications Deployed!"
echo "=========================================="
echo ""
echo "Current Status:"
kubectl get deployments -n keda-demo -l 'app in (producer,consumer)'
echo ""
echo "Applications are deployed and ready to use."
echo ""

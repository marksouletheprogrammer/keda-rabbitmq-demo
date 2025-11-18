#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "=========================================="
echo "Building Docker Images"
echo "=========================================="
echo ""

cd "${PROJECT_ROOT}"

# Build producer image
echo "Building producer image..."
docker build -t keda-demo-producer:latest -f Dockerfile.producer .
echo "✅ Producer image built"
echo ""

# Build consumer image
echo "Building consumer image..."
docker build -t keda-demo-consumer:latest -f Dockerfile.consumer .
echo "✅ Consumer image built"
echo ""

# Load images into cluster (for kind/minikube)
echo "Detecting Kubernetes cluster type..."

if kubectl config current-context | grep -q "kind"; then
    echo "Kind cluster detected, loading images..."
    kind load docker-image keda-demo-producer:latest
    kind load docker-image keda-demo-consumer:latest
    echo "✅ Images loaded into kind cluster"
elif kubectl config current-context | grep -q "minikube"; then
    echo "Minikube cluster detected, loading images..."
    minikube image load keda-demo-producer:latest
    minikube image load keda-demo-consumer:latest
    echo "✅ Images loaded into minikube cluster"
elif kubectl config current-context | grep -q "docker-desktop"; then
    echo "Docker Desktop cluster detected, images already available"
    echo "✅ Images available in Docker Desktop"
else
    echo "ℹ️  Unknown cluster type. Images built locally."
    echo "   If using kind, run: kind load docker-image keda-demo-producer:latest keda-demo-consumer:latest"
    echo "   If using minikube, run: minikube image load keda-demo-producer:latest keda-demo-consumer:latest"
fi

echo ""
echo "=========================================="
echo "✅ Build Complete!"
echo "=========================================="
echo ""
echo "Images:"
echo "  - keda-demo-producer:latest"
echo "  - keda-demo-consumer:latest"
echo ""

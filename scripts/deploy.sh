#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "=========================================="
echo "KEDA RabbitMQ Demo - Infrastructure Setup"
echo "=========================================="
echo ""

# Check prerequisites
echo "Checking prerequisites..."
echo ""

if ! command -v kubectl &> /dev/null; then
    echo "❌ Error: kubectl is not installed."
    echo "Please install kubectl: https://kubernetes.io/docs/tasks/tools/"
    exit 1
fi

if ! command -v helm &> /dev/null; then
    echo "❌ Error: helm is not installed."
    echo "Please install helm: https://helm.sh/docs/intro/install/"
    exit 1
fi

if ! command -v docker &> /dev/null; then
    echo "❌ Error: docker is not installed."
    echo "Please install docker: https://docs.docker.com/get-docker/"
    exit 1
fi

# Check if Kubernetes cluster is accessible
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Error: Cannot connect to Kubernetes cluster."
    echo "Please ensure your Kubernetes cluster is running (minikube, kind, or Docker Desktop)."
    exit 1
fi

echo "✅ All prerequisites met!"
echo ""

# Deploy namespace
echo "1. Creating namespace..."
kubectl apply -f "${PROJECT_ROOT}/k8s/namespace.yaml"
echo "✅ Namespace created"
echo ""

# Deploy RabbitMQ
echo "2. Deploying RabbitMQ..."
kubectl apply -f "${PROJECT_ROOT}/k8s/rabbitmq/"
echo "✅ RabbitMQ deployment created"
echo ""

# Deploy Prometheus
echo "3. Deploying Prometheus..."
kubectl apply -f "${PROJECT_ROOT}/k8s/monitoring/"
echo "✅ Prometheus deployment created"
echo ""

# Install KEDA
echo "4. Installing KEDA..."
"${SCRIPT_DIR}/install-keda.sh"
echo ""

# Wait for RabbitMQ to be ready
echo "5. Waiting for RabbitMQ to be ready..."
kubectl wait --for=condition=available --timeout=180s deployment/rabbitmq -n keda-demo
echo "✅ RabbitMQ is ready"
echo ""

# Wait for Prometheus to be ready
echo "6. Waiting for Prometheus to be ready..."
kubectl wait --for=condition=available --timeout=120s deployment/prometheus -n keda-demo
echo "✅ Prometheus is ready"
echo ""

echo "=========================================="
echo "✅ Infrastructure Deployment Complete!"
echo "=========================================="
echo ""
echo "Deployed Components:"
echo ""
kubectl get all -n keda-demo
echo ""
echo "KEDA Components:"
kubectl get pods -n keda
echo ""
echo "=========================================="
echo "Access Services:"
echo "=========================================="
echo ""
echo "RabbitMQ Management UI:"
echo "  Run: kubectl port-forward -n keda-demo svc/rabbitmq 15672:15672"
echo "  Then open: http://localhost:15672"
echo "  Username: guest"
echo "  Password: guest"
echo ""
echo "Prometheus UI:"
echo "  Run: kubectl port-forward -n keda-demo svc/prometheus 9090:9090"
echo "  Then open: http://localhost:9090"
echo ""
echo "=========================================="
echo "Next Steps:"
echo "=========================================="
echo ""
echo "1. Access RabbitMQ UI: make rabbitmq-ui"
echo "2. Access Prometheus UI: make prometheus-ui"
echo "3. Check component status: make status"
echo "4. View logs: make logs-rabbitmq or make logs-keda"
echo ""
echo "Ready for Layer 2 (Golang apps) deployment!"
echo ""

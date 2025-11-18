#!/bin/bash

set -e

echo "=========================================="
echo "KEDA RabbitMQ Demo - Infrastructure Teardown"
echo "=========================================="
echo ""

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "❌ Error: kubectl is not installed."
    exit 1
fi

# Check if helm is installed
if ! command -v helm &> /dev/null; then
    echo "❌ Error: helm is not installed."
    exit 1
fi

read -p "⚠️  This will delete all demo resources. Continue? (y/N) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Teardown cancelled."
    exit 0
fi

echo ""
echo "1. Uninstalling KEDA..."
if helm list -n keda | grep -q keda; then
    helm uninstall keda -n keda
    echo "✅ KEDA uninstalled"
else
    echo "ℹ️  KEDA not found (already uninstalled)"
fi
echo ""

echo "2. Deleting KEDA namespace..."
if kubectl get namespace keda &> /dev/null; then
    kubectl delete namespace keda --timeout=60s
    echo "✅ KEDA namespace deleted"
else
    echo "ℹ️  KEDA namespace not found"
fi
echo ""

echo "3. Deleting demo namespace (keda-demo)..."
if kubectl get namespace keda-demo &> /dev/null; then
    kubectl delete namespace keda-demo --timeout=60s
    echo "✅ Demo namespace deleted"
else
    echo "ℹ️  Demo namespace not found"
fi
echo ""

echo "4. Cleaning up ClusterRole and ClusterRoleBinding..."
kubectl delete clusterrole prometheus --ignore-not-found=true
kubectl delete clusterrolebinding prometheus --ignore-not-found=true
echo "✅ Cluster resources cleaned up"
echo ""

echo "=========================================="
echo "✅ Teardown Complete!"
echo "=========================================="
echo ""
echo "All demo resources have been removed."
echo "To redeploy, run: make deploy"
echo ""

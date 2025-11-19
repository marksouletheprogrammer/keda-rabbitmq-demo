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
echo "1. Cleaning up autoscaling resources..."
# Delete HPA if exists
if kubectl get hpa consumer-hpa -n keda-demo &> /dev/null; then
    echo "   Deleting HPA..."
    kubectl delete hpa consumer-hpa -n keda-demo --ignore-not-found=true
fi

# Delete KEDA ScaledObjects if exist (must be done before uninstalling KEDA)
if kubectl get scaledobject -n keda-demo &> /dev/null 2>&1; then
    echo "   Deleting KEDA ScaledObjects..."
    kubectl delete scaledobject --all -n keda-demo --timeout=30s 2>/dev/null || true
fi

# Delete TriggerAuthentications if exist
if kubectl get triggerauthentication -n keda-demo &> /dev/null 2>&1; then
    echo "   Deleting TriggerAuthentications..."
    kubectl delete triggerauthentication --all -n keda-demo --ignore-not-found=true
fi

# Delete Prometheus Adapter if exists
if helm list -n keda-demo | grep -q prometheus-adapter; then
    echo "   Uninstalling Prometheus Adapter..."
    helm uninstall prometheus-adapter -n keda-demo
fi

echo "✅ Autoscaling resources cleaned up"
echo ""

echo "2. Uninstalling KEDA..."
if helm list -n keda | grep -q keda; then
    helm uninstall keda -n keda
    echo "✅ KEDA uninstalled"
else
    echo "ℹ️  KEDA not found (already uninstalled)"
fi
echo ""

echo "3. Deleting KEDA namespace..."
if kubectl get namespace keda &> /dev/null; then
    echo "   Deleting namespace..."
    kubectl delete namespace keda --timeout=90s 2>/dev/null || {
        echo "   ⚠️  Namespace deletion timed out, checking for stuck resources..."
        
        # Check if namespace is stuck in Terminating
        if kubectl get namespace keda -o jsonpath='{.status.phase}' 2>/dev/null | grep -q "Terminating"; then
            echo "   Namespace stuck in Terminating state, attempting to force cleanup..."
            
            # Try to find and remove finalizers from stuck resources
            for resource in $(kubectl api-resources --verbs=list --namespaced -o name 2>/dev/null); do
                objects=$(kubectl get "$resource" -n keda -o name 2>/dev/null)
                if [ -n "$objects" ]; then
                    echo "   Removing finalizers from $resource..."
                    for obj in $objects; do
                        kubectl patch "$obj" -n keda -p '{"metadata":{"finalizers":[]}}' --type=merge 2>/dev/null || true
                    done
                fi
            done
            
            # Force remove namespace finalizers
            echo "   Forcing namespace deletion..."
            kubectl get namespace keda -o json | jq '.spec.finalizers = []' | kubectl replace --raw "/api/v1/namespaces/keda/finalize" -f - 2>/dev/null || true
            
            # Wait a bit more
            sleep 3
        fi
    }
    
    if kubectl get namespace keda &> /dev/null; then
        echo "⚠️  KEDA namespace still exists, but continuing..."
    else
        echo "✅ KEDA namespace deleted"
    fi
else
    echo "ℹ️  KEDA namespace not found"
fi
echo ""

echo "4. Deleting demo namespace (keda-demo)..."
if kubectl get namespace keda-demo &> /dev/null; then
    echo "   Deleting namespace..."
    kubectl delete namespace keda-demo --timeout=90s 2>/dev/null || {
        echo "   ⚠️  Namespace deletion timed out, checking for stuck resources..."
        
        # Check if namespace is stuck in Terminating
        if kubectl get namespace keda-demo -o jsonpath='{.status.phase}' 2>/dev/null | grep -q "Terminating"; then
            echo "   Namespace stuck in Terminating state, attempting to force cleanup..."
            
            # Try to find and remove finalizers from stuck resources
            for resource in $(kubectl api-resources --verbs=list --namespaced -o name 2>/dev/null); do
                objects=$(kubectl get "$resource" -n keda-demo -o name 2>/dev/null)
                if [ -n "$objects" ]; then
                    echo "   Removing finalizers from $resource..."
                    for obj in $objects; do
                        kubectl patch "$obj" -n keda-demo -p '{"metadata":{"finalizers":[]}}' --type=merge 2>/dev/null || true
                    done
                fi
            done
            
            # Force remove namespace finalizers
            echo "   Forcing namespace deletion..."
            kubectl get namespace keda-demo -o json | jq '.spec.finalizers = []' | kubectl replace --raw "/api/v1/namespaces/keda-demo/finalize" -f - 2>/dev/null || true
            
            # Wait a bit more
            sleep 3
            echo "   Checking if namespace was deleted..."
            kubectl wait --for=delete namespace/keda-demo --timeout=30s 2>/dev/null || {
                echo "   ⚠️  Namespace still exists. You may need to manually investigate:"
                echo "      kubectl get all -n keda-demo"
                echo "      kubectl api-resources --verbs=list --namespaced -o name | xargs -n 1 kubectl get --show-kind --ignore-not-found -n keda-demo"
            }
        fi
    }
    
    if kubectl get namespace keda-demo &> /dev/null; then
        echo "⚠️  Demo namespace still exists"
    else
        echo "✅ Demo namespace deleted"
    fi
else
    echo "ℹ️  Demo namespace not found"
fi
echo ""

echo "5. Cleaning up ClusterRole and ClusterRoleBinding..."
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

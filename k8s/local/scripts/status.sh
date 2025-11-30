#!/bin/bash

echo "=========================================="
echo "Layer8 Local Cluster Status"
echo "=========================================="
echo ""

# Check if layer8 namespace exists
if ! kubectl get namespace layer8 &> /dev/null; then
    echo "❌ Layer8 namespace not found!"
    echo "Run 'make deploy' to deploy the application."
    exit 1
fi

echo "📦 Pods:"
echo "----------------------------------------"
kubectl get pods -n layer8
echo ""

echo "🔌 Services:"
echo "----------------------------------------"
kubectl get svc -n layer8
echo ""

echo "💾 PersistentVolumeClaims:"
echo "----------------------------------------"
kubectl get pvc -n layer8
echo ""

echo "🗄️  StatefulSets:"
echo "----------------------------------------"
kubectl get statefulsets -n layer8
echo ""

echo "🚀 Deployments:"
echo "----------------------------------------"
kubectl get deployments -n layer8
echo ""

echo "🌐 Ingress:"
echo "----------------------------------------"
kubectl get ingress -n layer8
echo ""

echo "=========================================="
echo "Quick Health Check:"
echo "=========================================="
echo ""

# Count ready vs total pods
TOTAL_PODS=$(kubectl get pods -n layer8 --no-headers 2>/dev/null | wc -l)
READY_PODS=$(kubectl get pods -n layer8 --no-headers 2>/dev/null | grep "Running" | grep -E "([0-9]+)/\1" | wc -l)

echo "Ready Pods: $READY_PODS / $TOTAL_PODS"

if [ "$READY_PODS" -eq "$TOTAL_PODS" ] && [ "$TOTAL_PODS" -gt 0 ]; then
    echo "✅ All pods are ready!"
else
    echo "⚠️  Some pods are not ready. Check logs with:"
    echo "   kubectl logs -n layer8 <pod-name>"
fi
echo ""

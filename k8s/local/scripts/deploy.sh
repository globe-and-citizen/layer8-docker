#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCAL_DIR="$(dirname "$SCRIPT_DIR")"

echo "=========================================="
echo "Layer8 Local Deployment Script"
echo "=========================================="
echo ""

# Function to apply manifests from a directory
apply_manifests() {
    local dir=$1
    local name=$2

    if [ -d "$dir" ]; then
        echo "→ Applying $name..."
        kubectl apply -f "$dir/"
        echo "✓ $name applied successfully"
        echo ""
    else
        echo "⚠ Warning: Directory $dir not found, skipping..."
        echo ""
    fi
}

# Apply manifests in the correct order
echo "Starting deployment to Kind cluster..."
echo ""

apply_manifests "$LOCAL_DIR/namespace" "Namespace"
apply_manifests "$LOCAL_DIR/secrets" "Secrets"
apply_manifests "$LOCAL_DIR/configmap" "ConfigMaps"
apply_manifests "$LOCAL_DIR/storage" "Storage (PVCs)"
apply_manifests "$LOCAL_DIR/database" "Databases"
apply_manifests "$LOCAL_DIR/service" "Services"
apply_manifests "$LOCAL_DIR/ingress" "Ingress"

echo "=========================================="
echo "Deployment Complete!"
echo "=========================================="
echo ""
echo "To check the status of your deployment, run:"
echo "  make status"
echo "  OR"
echo "  kubectl get all -n layer8"
echo ""

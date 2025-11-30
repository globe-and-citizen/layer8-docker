#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCAL_DIR="$(dirname "$SCRIPT_DIR")"

echo "=========================================="
echo "Layer8 Local Cleanup Script"
echo "=========================================="
echo ""
echo "⚠️  WARNING: This will delete all Layer8 resources from your cluster!"
echo ""
read -p "Are you sure you want to continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Cleanup cancelled."
    exit 0
fi

echo ""
echo "Starting cleanup..."
echo ""

# Function to delete manifests from a directory
delete_manifests() {
    local dir=$1
    local name=$2

    if [ -d "$dir" ]; then
        echo "→ Deleting $name..."
        kubectl delete -f "$dir/" --ignore-not-found=true
        echo "✓ $name deleted"
        echo ""
    else
        echo "⚠ Warning: Directory $dir not found, skipping..."
        echo ""
    fi
}

# Delete manifests in reverse order
delete_manifests "$LOCAL_DIR/ingress" "Ingress"
delete_manifests "$LOCAL_DIR/service" "Services"
delete_manifests "$LOCAL_DIR/database" "Databases"
delete_manifests "$LOCAL_DIR/storage" "Storage (PVCs)"
delete_manifests "$LOCAL_DIR/configmap" "ConfigMaps"
delete_manifests "$LOCAL_DIR/secrets" "Secrets"
delete_manifests "$LOCAL_DIR/namespace" "Namespace"

echo "=========================================="
echo "Cleanup Complete!"
echo "=========================================="
echo ""

#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCAL_DIR="$(dirname "$SCRIPT_DIR")"
CLUSTER_CONFIG="$LOCAL_DIR/kind-cluster/layer8-dev-001-cluster.yaml"

echo "=========================================="
echo "Layer8 Kind Cluster Creation"
echo "=========================================="
echo ""

# Check if kind is installed
if ! command -v kind &> /dev/null; then
    echo "❌ Error: 'kind' is not installed."
    echo "Please install Kind from: https://kind.sigs.k8s.io/docs/user/quick-start/#installation"
    exit 1
fi

# Check if cluster already exists
if kind get clusters 2>/dev/null | grep -q "layer8-dev-001"; then
    echo "⚠️  Cluster 'layer8-dev-001' already exists!"
    read -p "Do you want to delete and recreate it? (yes/no): " confirm

    if [ "$confirm" = "yes" ]; then
        echo "→ Deleting existing cluster..."
        kind delete cluster --name layer8-dev-001
        echo "✓ Cluster deleted"
        echo ""
    else
        echo "Using existing cluster."
        exit 0
    fi
fi

# Create the cluster
if [ -f "$CLUSTER_CONFIG" ]; then
    echo "→ Creating Kind cluster using config: $CLUSTER_CONFIG"
    kind create cluster --config "$CLUSTER_CONFIG"
    echo "✓ Cluster created successfully"
else
    echo "❌ Error: Cluster config not found at $CLUSTER_CONFIG"
    exit 1
fi

echo ""
echo "=========================================="
echo "Cluster Created Successfully!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "  1. Deploy Layer8: make deploy"
echo "  2. Check status:  make status"
echo ""

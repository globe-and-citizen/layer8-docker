.PHONY: help create-cluster delete-cluster deploy cleanup status logs shell

# Default target
help:
	@echo "=========================================="
	@echo "Layer8 Local Development Makefile"
	@echo "=========================================="
	@echo ""
	@echo "Available targets:"
	@echo ""
	@echo "  make create-cluster  - Create Kind cluster for local development"
	@echo "  make delete-cluster  - Delete Kind cluster"
	@echo "  make deploy          - Deploy all Layer8 manifests to the cluster"
	@echo "  make cleanup         - Remove all Layer8 resources from the cluster"
	@echo "  make status          - Show status of all Layer8 resources"
	@echo "  make logs POD=<name> - Show logs for a specific pod"
	@echo "  make shell POD=<name> - Open shell in a specific pod"
	@echo ""
	@echo "Quick Start:"
	@echo "  1. make create-cluster"
	@echo "  2. make deploy"
	@echo "  3. make status"
	@echo ""

# Create Kind cluster
create-cluster:
	@bash scripts/create-cluster.sh

# Delete Kind cluster
delete-cluster:
	@echo "Deleting Kind cluster 'layer8-dev-001'..."
	@kind delete cluster --name layer8-dev-001
	@echo "✓ Cluster deleted"

# Deploy all manifests
deploy:
	@bash scripts/deploy.sh

# Cleanup all resources
cleanup:
	@bash scripts/cleanup.sh

# Show status of all resources
status:
	@bash scripts/status.sh

# Show logs for a specific pod
logs:
ifndef POD
	@echo "Error: POD parameter is required"
	@echo "Usage: make logs POD=<pod-name>"
	@echo ""
	@echo "Available pods:"
	@kubectl get pods -n layer8 --no-headers 2>/dev/null | awk '{print "  - " $$1}' || echo "  No pods found"
else
	@kubectl logs -n layer8 $(POD) -f
endif

# Open shell in a specific pod
shell:
ifndef POD
	@echo "Error: POD parameter is required"
	@echo "Usage: make shell POD=<pod-name>"
	@echo ""
	@echo "Available pods:"
	@kubectl get pods -n layer8 --no-headers 2>/dev/null | awk '{print "  - " $$1}' || echo "  No pods found"
else
	@kubectl exec -it -n layer8 $(POD) -- /bin/sh || kubectl exec -it -n layer8 $(POD) -- /bin/bash
endif

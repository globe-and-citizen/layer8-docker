# Layer8 Local Development Environment

This directory contains Kubernetes manifests and scripts for running Layer8 locally using [Kind](https://kind.sigs.k8s.io/) (Kubernetes in Docker).

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) installed and running
- [Kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation) installed
- [kubectl](https://kubernetes.io/docs/tasks/tools/) installed

## Quick Start

### 1. Create Kind Cluster

```bash
cd local/
make create-cluster
```

This creates a Kind cluster named `layer8-dev-001` with:
- 1 control-plane node
- 2 worker nodes
- Port mappings for all services (see below)

### 2. Deploy Layer8

```bash
make deploy
```

This deploys all Layer8 components in the correct order:
1. Namespace
2. Secrets
3. ConfigMaps
4. Storage (PVCs)
5. Databases (PostgreSQL, InfluxDB, Telegraf)
6. Services (auth-server, proxies, spa-frontend/backend)
7. Ingress

### 3. Check Status

```bash
make status
```

View logs for a specific pod:

```bash
make logs POD=auth-server-<pod-id>
```

Open a shell in a pod:

```bash
make shell POD=postgres-0
```

## Available Commands

Run `make` or `make help` to see all available commands:

| Command | Description |
|---------|-------------|
| `make create-cluster` | Create Kind cluster for local development |
| `make delete-cluster` | Delete Kind cluster completely |
| `make deploy` | Deploy all Layer8 manifests to the cluster |
| `make cleanup` | Remove all Layer8 resources (keeps cluster) |
| `make status` | Show status of all Layer8 resources |
| `make logs POD=<name>` | Show logs for a specific pod |
| `make shell POD=<name>` | Open shell in a specific pod |

## Port Mappings

The Kind cluster exposes the following services on localhost:

| Service | Port | URL |
|---------|------|-----|
| Forward Proxy | 6191 | http://localhost:6191 |
| Reverse Proxy | 6193 | http://localhost:6193 |
| Auth Server | 5001 | http://localhost:5001 |
| SPA Frontend | 5173 | http://localhost:5173 |
| SPA Backend | 3000 | http://localhost:3000 |
| InfluxDB | 8086 | http://localhost:8086 |
| PostgreSQL | 5432 | localhost:5432 |
| Ingress HTTP | 80 | http://localhost |
| Ingress HTTPS | 443 | https://localhost |

## Directory Structure

```
local/
├── scripts/              # Deployment and management scripts
│   ├── create-cluster.sh # Creates Kind cluster
│   ├── deploy.sh         # Deploys all manifests
│   ├── cleanup.sh        # Removes all resources
│   └── status.sh         # Shows cluster status
├── kind-cluster/         # Kind cluster configuration
├── namespace/            # Namespace definition
├── secrets/              # Secret configurations (databases, services)
├── configmap/            # ConfigMaps (migration scripts, etc.)
├── storage/              # PersistentVolumeClaims
├── database/             # Database StatefulSets (postgres, influxdb, telegraf)
├── service/              # Application services (auth, proxies, spa)
├── ingress/              # Ingress resources
├── Makefile              # Make commands for easy deployment
└── README.md             # This file
```

## Manual Deployment

If you prefer to apply manifests manually:

```bash
# Create cluster
kind create cluster --config local/kind-cluster/layer8-dev-001-cluster.yaml

# Apply manifests in order
kubectl apply -f local/namespace/
kubectl apply -f local/secrets/
kubectl apply -f local/configmap/
kubectl apply -f local/storage/
kubectl apply -f local/database/
kubectl apply -f local/service/
kubectl apply -f local/ingress/

# Check status
kubectl get all -n layer8
```

## Troubleshooting

### Check pod logs
```bash
kubectl logs -n layer8 -l app=auth-server -f
kubectl logs -n layer8 -l app=spa-backend-sp1 -f
```

### Check database migration status
```bash
kubectl logs -n layer8 -l app=auth-server -c auth-setup
```

### Verify databases are ready
```bash
kubectl exec -n layer8 postgres-0 -- pg_isready -U layer8development
kubectl exec -n layer8 influxdb-0 -- influx ping
```

### Check PVC status
```bash
kubectl get pvc -n layer8
```

### Describe a pod for detailed events
```bash
kubectl describe pod -n layer8 <pod-name>
```

## Cleanup

### Remove all resources but keep the cluster
```bash
make cleanup
```

### Delete the entire cluster
```bash
make delete-cluster
```

## Development Workflow

1. **Start fresh**: `make create-cluster && make deploy`
2. **Make changes** to your manifests
3. **Apply changes**: `kubectl apply -f local/<component>/`
4. **Check status**: `make status`
5. **View logs**: `make logs POD=<pod-name>`
6. **Clean up**: `make cleanup` (or `make delete-cluster` to remove everything)

## Notes

- All secrets are **development-only** and should never be used in production
- The cluster uses custom pod/service subnets configured in the Kind cluster config
- Port mappings allow direct access to services without port-forwarding
- Services support horizontal pod autoscaling (HPA manifests available)

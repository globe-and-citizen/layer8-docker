# Layer8 Kubernetes Architecture (NEED TO IMPROVE)

This document provides visual diagrams of the Layer8 Kubernetes infrastructure architecture.

## Table of Contents
- [High-Level Architecture](#high-level-architecture)
- [Network Flow](#network-flow)
- [Service Provider Architecture](#service-provider-architecture)
- [Monitoring Architecture](#monitoring-architecture)
- [Database Layer](#database-layer)
- [Port Mappings](#port-mappings)
- [Resource Distribution](#resource-distribution)

---

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          Kind Cluster: layer8-dev-001                        │
│                                                                               │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                         Namespace: layer8                            │    │
│  │                                                                       │    │
│  │  ┌──────────────────────────────────────────────────────────────┐   │    │
│  │  │                    Ingress Controller (NGINX)                 │   │    │
│  │  │                    Host: layer8.local                         │   │    │
│  │  │                                                               │   │    │
│  │  │  Routes:                                                      │   │    │
│  │  │    /     → forward-proxy:6191                               │   │    │
│  │  │    /auth → auth-server:5001                                 │   │    │
│  │  └────────────────┬──────────────────┬──────────────────────────┘   │    │
│  │                   │                  │                              │    │
│  │  ┌────────────────▼─────┐   ┌───────▼──────────┐                   │    │
│  │  │   Forward Proxy      │   │   Auth Server    │                   │    │
│  │  │   (3 replicas)       │   │   (2 replicas)   │                   │    │
│  │  │   Port: 6191         │   │   Port: 5001     │                   │    │
│  │  │   + Telegraf         │   │   + Telegraf     │                   │    │
│  │  └──────────┬───────────┘   └────────┬─────────┘                   │    │
│  │             │                        │                              │    │
│  │             │                        │                              │    │
│  │  ┌──────────▼────────────────────────▼──────────────────────┐      │    │
│  │  │              Reverse Proxy (SP1)                          │      │    │
│  │  │              (2 replicas)                                 │      │    │
│  │  │              Port: 6193                                   │      │    │
│  │  │              + Telegraf                                   │      │    │
│  │  └──────────┬───────────────────┬────────────────────────────┘      │    │
│  │             │                   │                                   │    │
│  │  ┌──────────▼─────────┐  ┌─────▼──────────────┐                    │    │
│  │  │  SPA Frontend (SP1) │  │  SPA Backend (SP1) │                    │    │
│  │  │  (2 replicas)       │  │  (2 replicas)      │                    │    │
│  │  │  Port: 5173         │  │  Port: 3000        │                    │    │
│  │  └─────────────────────┘  └──────────┬─────────┘                    │    │
│  │                                      │                              │    │
│  │                                      │                              │    │
│  │  ┌───────────────────────────────────▼──────────────────────┐       │    │
│  │  │                    PostgreSQL                             │       │    │
│  │  │                    (StatefulSet)                          │       │    │
│  │  │                    Port: 5432                             │       │    │
│  │  │                    PVC: postgres-pvc                      │       │    │
│  │  └───────────────────────────────────────────────────────────┘       │    │
│  │                                                                       │    │
│  │  ┌───────────────────────────────────────────────────────────┐       │    │
│  │  │                    InfluxDB                               │       │    │
│  │  │                    (StatefulSet)                          │       │    │
│  │  │                    Port: 8086                             │       │    │
│  │  │                    PVC: influxdb-pvc                      │       │    │
│  │  └─────────────────────────▲─────────────────────────────────┘       │    │
│  │                            │                                         │    │
│  │                            │ (Metrics)                               │    │
│  │                    ┌───────┴────────┐                                │    │
│  │                    │  All Telegraf  │                                │    │
│  │                    │   Sidecars     │                                │    │
│  │                    └────────────────┘                                │    │
│  └───────────────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Network Flow

### External Request Flow
```
┌────────────┐
│   Client   │
│ (Browser)  │
└─────┬──────┘
      │
      │ HTTP/HTTPS
      │ (Port 80/443)
      ▼
┌─────────────────────────────┐
│  Kind Host Port Mapping     │
│  80:80, 443:443             │
└─────────────┬───────────────┘
              │
              ▼
┌─────────────────────────────┐
│  NGINX Ingress Controller   │
│  layer8.local               │
└─────┬───────────────┬───────┘
      │               │
      │ /             │ /auth
      ▼               ▼
┌──────────────┐  ┌──────────────┐
│   Forward    │  │     Auth     │
│    Proxy     │  │    Server    │
│  (Service)   │  │  (Service)   │
│  Port: 6191  │  │  Port: 5001  │
└──────┬───────┘  └──────┬───────┘
       │                 │
       │ Load Balances   │ Load Balances
       ▼                 ▼
┌──────────────┐  ┌──────────────┐
│ Forward      │  │ Auth Server  │
│ Proxy Pods   │  │ Pods         │
│ (3 replicas) │  │ (2 replicas) │
└──────────────┘  └──────────────┘
```

### Internal Service Communication
```
┌──────────────────┐
│  Forward Proxy   │
│     Pods         │
└────────┬─────────┘
         │
         │ Internal ClusterIP
         ▼
┌──────────────────┐
│  Reverse Proxy   │────────┐
│  Service         │        │
│  (SP1)           │        │
└────────┬─────────┘        │
         │                  │
         │                  │
         ▼                  ▼
┌──────────────┐   ┌────────────────┐
│ SPA Frontend │   │  SPA Backend   │
│  Service     │   │   Service      │
│  (SP1)       │   │   (SP1)        │
└──────────────┘   └───────┬────────┘
                           │
                           │ postgres.layer8.svc.cluster.local:5432
                           ▼
                   ┌────────────────┐
                   │   PostgreSQL   │
                   │    Service     │
                   └────────────────┘
```

---

## Service Provider Architecture

The system uses a multi-tenant Service Provider (SP) pattern, allowing multiple isolated deployments:

```
┌────────────────────────────────────────────────────────────────────┐
│                     Service Provider Pattern                       │
│                                                                     │
│  ┌───────────────────────────────────────────────────────────┐    │
│  │              Service Provider 1 (sp-id: sp1)              │    │
│  │                                                            │    │
│  │  ┌─────────────────────┐  ┌─────────────────────┐        │    │
│  │  │ reverse-proxy-sp1   │  │  spa-frontend-sp1   │        │    │
│  │  │ Deployment          │  │  Deployment         │        │    │
│  │  │ Labels:             │  │  Labels:            │        │    │
│  │  │   sp-id: sp1        │  │    sp-id: sp1       │        │    │
│  │  └─────────────────────┘  └─────────────────────┘        │    │
│  │                                                            │    │
│  │  ┌─────────────────────┐                                  │    │
│  │  │  spa-backend-sp1    │                                  │    │
│  │  │  Deployment         │                                  │    │
│  │  │  Labels:            │                                  │    │
│  │  │    sp-id: sp1       │                                  │    │
│  │  └─────────────────────┘                                  │    │
│  └────────────────────────────────────────────────────────────┘    │
│                                                                     │
│  ┌───────────────────────────────────────────────────────────┐    │
│  │         Future: Service Provider 2 (sp-id: sp2)           │    │
│  │         (Can be added for multi-tenancy)                  │    │
│  └───────────────────────────────────────────────────────────┘    │
│                                                                     │
│  ┌───────────────────────────────────────────────────────────┐    │
│  │              Shared Infrastructure                         │    │
│  │  - Auth Server (no SP label)                              │    │
│  │  - Forward Proxy (no SP label)                            │    │
│  │  - PostgreSQL                                             │    │
│  │  - InfluxDB                                               │    │
│  └───────────────────────────────────────────────────────────┘    │
└────────────────────────────────────────────────────────────────────┘
```

---

## Monitoring Architecture

### Sidecar Pattern with Telegraf

```
┌──────────────────────────────────────────────────────────────────────┐
│                    Application Pod (Example: Auth Server)            │
│                                                                       │
│  ┌──────────────────────────┐  ┌──────────────────────────────┐     │
│  │  Main Container          │  │  Telegraf Sidecar            │     │
│  │  auth-server             │  │                              │     │
│  │                          │  │  Ports:                      │     │
│  │  Port: 5001             │  │    - 4317 (OpenTelemetry)   │     │
│  │                          │  │    - 8125 (StatsD UDP)      │     │
│  │  Emits metrics ─────────┼──┼──▶ Receives metrics         │     │
│  │  (StatsD/OTLP)          │  │                              │     │
│  │                          │  │  ConfigMap:                  │     │
│  │                          │  │    telegraf-config          │     │
│  │                          │  │    (/etc/telegraf)          │     │
│  └──────────────────────────┘  └───────────┬──────────────────┘     │
│                                            │                         │
└────────────────────────────────────────────┼─────────────────────────┘
                                             │
                                             │ HTTP
                                             │ InfluxDB Line Protocol
                                             ▼
                          ┌──────────────────────────────────┐
                          │  InfluxDB Service                │
                          │  influxdb.layer8.svc.cluster.local:8086 │
                          │                                  │
                          │  Credentials:                    │
                          │    - Token (from secret)         │
                          │    - Org (from secret)           │
                          │    - Bucket (from secret)        │
                          └──────────────────────────────────┘
```

### Metrics Flow Diagram

```
┌────────────────┐  ┌────────────────┐  ┌────────────────┐
│ Forward Proxy  │  │  Auth Server   │  │ Reverse Proxy  │
│     Pod        │  │     Pod        │  │     Pod        │
│                │  │                │  │                │
│  ┌──────────┐  │  │  ┌──────────┐  │  │  ┌──────────┐  │
│  │ Telegraf │  │  │  │ Telegraf │  │  │  │ Telegraf │  │
│  └────┬─────┘  │  │  └────┬─────┘  │  │  └────┬─────┘  │
└───────┼────────┘  └───────┼────────┘  └───────┼────────┘
        │                   │                   │
        │                   │                   │
        └───────────────────┼───────────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
┌───────▼────────┐  ┌───────▼────────┐  ┌───────▼────────┐
│  SPA Frontend  │  │  SPA Backend   │  │  Telegraf      │
│     Pod        │  │     Pod        │  │  StatefulSet   │
│  ┌──────────┐  │  │  ┌──────────┐  │  │  (Standalone)  │
│  │ Telegraf │  │  │  │ Telegraf │  │  └───────┬────────┘
│  └────┬─────┘  │  │  └────┬─────┘  │          │
└───────┼────────┘  └───────┼────────┘          │
        │                   │                   │
        └───────────────────┴───────────────────┘
                            │
                            ▼
                ┌───────────────────────┐
                │      InfluxDB         │
                │   (Time-Series DB)    │
                │                       │
                │  Storage:             │
                │    influxdb-pvc       │
                │    /var/lib/influxdb2 │
                └───────────────────────┘
```

---

## Database Layer

### PostgreSQL Architecture

```
┌──────────────────────────────────────────────────────────┐
│                  PostgreSQL StatefulSet                   │
│                                                           │
│  ┌────────────────────────────────────────────────┐      │
│  │  Pod: postgres-0                               │      │
│  │                                                 │      │
│  │  ┌──────────────────────────────────────┐      │      │
│  │  │  Container: postgres                  │      │      │
│  │  │  Image: postgres:13                   │      │      │
│  │  │  Port: 5432                           │      │      │
│  │  │                                       │      │      │
│  │  │  Volume Mounts:                       │      │      │
│  │  │    /var/lib/postgresql/data           │      │      │
│  │  │       ← postgres-pvc                  │      │      │
│  │  │                                       │      │      │
│  │  │    /docker-entrypoint-initdb.d        │      │      │
│  │  │       ← postgres-init (ConfigMap)     │      │      │
│  │  │                                       │      │      │
│  │  │  Secrets:                             │      │      │
│  │  │    postgres-standalone-secret         │      │      │
│  │  │      - POSTGRES_DB                    │      │      │
│  │  │      - POSTGRES_USER                  │      │      │
│  │  │      - POSTGRES_PASSWORD              │      │      │
│  │  │                                       │      │      │
│  │  │  Health Checks:                       │      │      │
│  │  │    pg_isready -U layer8development    │      │      │
│  │  └──────────────────────────────────────┘      │      │
│  └────────────────────────────────────────────────┘      │
│                                                           │
│  Service: postgres.layer8.svc.cluster.local:5432        │
│  Type: ClusterIP                                         │
└──────────────────────────────────────────────────────────┘
```

### InfluxDB Architecture

```
┌──────────────────────────────────────────────────────────┐
│                  InfluxDB StatefulSet                     │
│                                                           │
│  ┌────────────────────────────────────────────────┐      │
│  │  Pod: influxdb-0                               │      │
│  │                                                 │      │
│  │  ┌──────────────────────────────────────┐      │      │
│  │  │  Container: influxdb                  │      │      │
│  │  │  Image: influxdb:2                    │      │      │
│  │  │  Port: 8086                           │      │      │
│  │  │                                       │      │      │
│  │  │  Volume Mounts:                       │      │      │
│  │  │    /var/lib/influxdb2                 │      │      │
│  │  │       ← influxdb-pvc                  │      │      │
│  │  │                                       │      │      │
│  │  │  Secrets:                             │      │      │
│  │  │    influxdb-standalone-secret         │      │      │
│  │  │      - DOCKER_INFLUXDB_INIT_*         │      │      │
│  │  │                                       │      │      │
│  │  │  Health Checks:                       │      │      │
│  │  │    GET /health (Port 8086)            │      │      │
│  │  └──────────────────────────────────────┘      │      │
│  └────────────────────────────────────────────────┘      │
│                                                           │
│  Service: influxdb.layer8.svc.cluster.local:8086        │
│  Type: ClusterIP                                         │
└──────────────────────────────────────────────────────────┘
```

---

## Port Mappings

### Kind Cluster Port Mappings (Host ↔ Cluster)

```
┌─────────────────────────────────────────────────────────────┐
│                      Host Machine                            │
│                                                              │
│  Port 80      ──┐                                           │
│  Port 443     ──┤                                           │
│  Port 5001    ──┤                                           │
│  Port 5432    ──┤                                           │
│  Port 6191    ──┤                                           │
│  Port 8086    ──┤                                           │
└─────────────────┼───────────────────────────────────────────┘
                  │
                  │ Docker Port Mapping
                  ▼
┌─────────────────────────────────────────────────────────────┐
│            Kind Control Plane Node                          │
│                                                              │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  Service Type: NodePort                               │  │
│  │                                                        │  │
│  │  80:80     → Ingress HTTP                            │  │
│  │  443:443   → Ingress HTTPS                           │  │
│  │  5001:30001  → Auth Server                           │  │
│  │  5432:30432  → PostgreSQL                            │  │
│  │  6191:30191  → Forward Proxy                         │  │
│  │  8086:30086  → InfluxDB                              │  │
│  └────────────────────────┬──────────────────────────────┘  │
│                           │                                  │
│                           ▼                                  │
│  ┌───────────────────────────────────────────────────────┐  │
│  │         ClusterIP Services (Internal)                 │  │
│  │                                                        │  │
│  │  auth-server:5001                                    │  │
│  │  forward-proxy:6191                                  │  │
│  │  reverse-proxy:6193                                  │  │
│  │  spa-frontend:5173                                   │  │
│  │  spa-backend:3000                                    │  │
│  │  postgres:5432                                       │  │
│  │  influxdb:8086                                       │  │
│  │  telegraf:8125,4317                                  │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### Service Port Reference Table

| Service          | Container Port | Service Port | NodePort | Health Endpoint        |
|------------------|----------------|--------------|----------|------------------------|
| forward-proxy    | 6191          | 6191         | 30191    | /healthcheck           |
| auth-server      | 5001          | 5001         | 30001    | /health                |
| reverse-proxy    | 6193          | 6193         | -        | /l8_health_check       |
| spa-frontend     | 5173          | 5173         | -        | /                      |
| spa-backend      | 3000          | 3000         | -        | /                      |
| postgres         | 5432          | 5432         | 30432    | pg_isready             |
| influxdb         | 8086          | 8086         | 30086    | /health                |
| telegraf (OTLP)  | 4317          | 4317         | -        | nc -z localhost 4317   |
| telegraf (StatsD)| 8125          | 8125         | -        | -                      |

---

## Resource Distribution

### Pod Resource Allocation

```
┌────────────────────────────────────────────────────────────────────┐
│                      Resource Requests & Limits                    │
│                                                                     │
│  ┌──────────────────────┬──────────────┬──────────────┬─────────┐  │
│  │ Service              │ CPU Request  │ CPU Limit    │ Replicas│  │
│  ├──────────────────────┼──────────────┼──────────────┼─────────┤  │
│  │ forward-proxy        │ 500m         │ 2000m        │ 3       │  │
│  │ auth-server          │ 250m         │ 1000m        │ 2-10*   │  │
│  │ reverse-proxy        │ 250m         │ 1000m        │ 2-10*   │  │
│  │ spa-frontend         │ 100m         │ 200m         │ 2-10*   │  │
│  │ spa-backend          │ 250m         │ 500m         │ 2-10*   │  │
│  │ postgres             │ 250m         │ 1000m        │ 1       │  │
│  │ influxdb             │ 500m         │ 2000m        │ 1       │  │
│  │ telegraf (sidecar)   │ 50m          │ 250m         │ N/A     │  │
│  └──────────────────────┴──────────────┴──────────────┴─────────┘  │
│                                                                     │
│  ┌──────────────────────┬──────────────┬──────────────┐            │
│  │ Service              │ Mem Request  │ Mem Limit    │            │
│  ├──────────────────────┼──────────────┼──────────────┤            │
│  │ forward-proxy        │ 512Mi        │ 2Gi          │            │
│  │ auth-server          │ 256Mi        │ 1Gi          │            │
│  │ reverse-proxy        │ 512Mi        │ 2Gi          │            │
│  │ spa-frontend         │ 128Mi        │ 256Mi        │            │
│  │ spa-backend          │ 256Mi        │ 512Mi        │            │
│  │ postgres             │ 256Mi        │ 1Gi          │            │
│  │ influxdb             │ 512Mi        │ 2Gi          │            │
│  │ telegraf (sidecar)   │ 64Mi         │ 256Mi        │            │
│  └──────────────────────┴──────────────┴──────────────┘            │
│                                                                     │
│  * Managed by Horizontal Pod Autoscaler (HPA)                      │
└────────────────────────────────────────────────────────────────────┘
```

### Horizontal Pod Autoscaler (HPA) Configuration

```
┌────────────────────────────────────────────────────────────────────┐
│                   HPA Scaling Policies                              │
│                                                                     │
│  ┌─────────────────┬──────────┬──────────┬──────────┬──────────┐   │
│  │ Service         │ Min      │ Max      │ CPU %    │ Memory % │   │
│  ├─────────────────┼──────────┼──────────┼──────────┼──────────┤   │
│  │ auth-server     │ 2        │ 10       │ 70       │ 80       │   │
│  │ forward-proxy   │ 3        │ 10       │ 70       │ 80       │   │
│  │ reverse-proxy   │ 2        │ 10       │ 70       │ 80       │   │
│  │ spa-frontend    │ 2        │ 10       │ 70       │ 80       │   │
│  │ spa-backend     │ 2        │ 10       │ 70       │ 80       │   │
│  └─────────────────┴──────────┴──────────┴──────────┴──────────┘   │
│                                                                     │
│  Scale-Up Behavior:                                                │
│    - No stabilization window (immediate)                           │
│    - Max: 100% increase per 30s OR 2 pods per 30s                 │
│                                                                     │
│  Scale-Down Behavior:                                              │
│    - 5 minute stabilization window                                │
│    - Max: 50% decrease per 60s                                    │
└────────────────────────────────────────────────────────────────────┘
```

---

## Storage Architecture

### Persistent Volume Claims

```
┌──────────────────────────────────────────────────────────────┐
│                    Storage Layer                              │
│                                                               │
│  ┌────────────────────┐           ┌────────────────────┐     │
│  │  postgres-pvc      │           │  influxdb-pvc      │     │
│  │                    │           │                    │     │
│  │  AccessMode:       │           │  AccessMode:       │     │
│  │    ReadWriteOnce   │           │    ReadWriteOnce   │     │
│  │                    │           │                    │     │
│  │  Storage:          │           │  Storage:          │     │
│  │    (Default)       │           │    (Default)       │     │
│  │                    │           │                    │     │
│  │  Mount Path:       │           │  Mount Path:       │     │
│  │    /var/lib/       │           │    /var/lib/       │     │
│  │    postgresql/data │           │    influxdb2       │     │
│  └─────────┬──────────┘           └──────────┬─────────┘     │
│            │                                 │               │
│            │                                 │               │
│            ▼                                 ▼               │
│  ┌─────────────────────────────────────────────────────┐     │
│  │         Kind Node Local Storage                     │     │
│  │         (Persistent across pod restarts)            │     │
│  └─────────────────────────────────────────────────────┘     │
└──────────────────────────────────────────────────────────────┘
```

---

## Init Container Pattern

### Auth Server with Setup Init Container

```
┌────────────────────────────────────────────────────────────┐
│                  Auth Server Pod Lifecycle                  │
│                                                             │
│  Phase 1: Init Container                                   │
│  ┌──────────────────────────────────────────────────┐      │
│  │  Init Container: auth-setup                      │      │
│  │  Image: dtpthao/auth-server:statistics           │      │
│  │  Command: ./setup docker                         │      │
│  │                                                   │      │
│  │  Responsibilities:                               │      │
│  │    - Database schema migrations                  │      │
│  │    - Initial data seeding                        │      │
│  │    - Configuration validation                    │      │
│  │                                                   │      │
│  │  Secrets: auth-setup-secrets                     │      │
│  │  Must complete successfully before main starts   │      │
│  └──────────────────────────────────────────────────┘      │
│            │                                                │
│            │ (On Success)                                   │
│            ▼                                                │
│  Phase 2: Main Container                                   │
│  ┌──────────────────────────────────────────────────┐      │
│  │  Main Container: auth-server                     │      │
│  │  Image: dtpthao/auth-server:statistics           │      │
│  │  Command: ./main                                 │      │
│  │  Port: 5001                                      │      │
│  │                                                   │      │
│  │  Health Checks:                                  │      │
│  │    - Liveness: /health                           │      │
│  │    - Readiness: /health                          │      │
│  │                                                   │      │
│  │  Secrets: auth-setup-secrets                     │      │
│  └──────────────────────────────────────────────────┘      │
│                                                             │
│  Phase 3: Sidecar (Runs in parallel with main)             │
│  ┌──────────────────────────────────────────────────┐      │
│  │  Sidecar Container: telegraf                     │      │
│  │  Ports: 4317 (OTLP), 8125 (StatsD)              │      │
│  └──────────────────────────────────────────────────┘      │
└────────────────────────────────────────────────────────────┘
```

---

## Deployment Dependency Graph

```
┌─────────────────────────────────────────────────────────────────┐
│                    Deployment Order (Dependencies)               │
│                                                                  │
│  Step 1: Foundation                                             │
│  ┌──────────────┐                                               │
│  │  Namespace   │                                               │
│  └──────┬───────┘                                               │
│         │                                                        │
│         ▼                                                        │
│  Step 2: Configuration & Storage                                │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │   Secrets    │  │  ConfigMaps  │  │     PVCs     │          │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘          │
│         └─────────────────┼─────────────────┘                   │
│                           ▼                                      │
│  Step 3: Databases (StatefulSets)                               │
│  ┌──────────────┐  ┌──────────────┐                            │
│  │  PostgreSQL  │  │   InfluxDB   │                            │
│  └──────┬───────┘  └──────┬───────┘                            │
│         │                 │                                      │
│         │                 │                                      │
│         ▼                 ▼                                      │
│  Step 4: Core Services                                          │
│  ┌──────────────┐  ┌──────────────┐                            │
│  │ Auth Server  │  │Forward Proxy │                            │
│  └──────┬───────┘  └──────┬───────┘                            │
│         │                 │                                      │
│         └────────┬────────┘                                     │
│                  ▼                                               │
│  Step 5: Service Provider Services                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │Reverse Proxy │  │ SPA Frontend │  │ SPA Backend  │          │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘          │
│         └─────────────────┼─────────────────┘                   │
│                           ▼                                      │
│  Step 6: Ingress                                                │
│  ┌──────────────────────┐                                       │
│  │  Ingress Controller  │                                       │
│  └──────────────────────┘                                       │
└─────────────────────────────────────────────────────────────────┘
```

---

## Security Architecture

### Secret Distribution

```
┌──────────────────────────────────────────────────────────────┐
│                     Secrets & Configuration                   │
│                                                               │
│  ┌────────────────────────────────────────────────────┐      │
│  │  auth-setup-secrets                                │      │
│  │    ├─ Used by: auth-server (init + main)          │      │
│  │    └─ Contains: DB credentials, JWT secrets       │      │
│  └────────────────────────────────────────────────────┘      │
│                                                               │
│  ┌────────────────────────────────────────────────────┐      │
│  │  postgres-standalone-secret                        │      │
│  │    ├─ Used by: postgres StatefulSet                │      │
│  │    └─ Contains: POSTGRES_DB, USER, PASSWORD       │      │
│  └────────────────────────────────────────────────────┘      │
│                                                               │
│  ┌────────────────────────────────────────────────────┐      │
│  │  influxdb-standalone-secret                        │      │
│  │    ├─ Used by: influxdb StatefulSet                │      │
│  │    └─ Contains: INFLUXDB init credentials          │      │
│  └────────────────────────────────────────────────────┘      │
│                                                               │
│  ┌────────────────────────────────────────────────────┐      │
│  │  layer8-secrets                                    │      │
│  │    ├─ Used by: All Telegraf sidecars               │      │
│  │    └─ Contains: influxdb-token, org, bucket        │      │
│  └────────────────────────────────────────────────────┘      │
│                                                               │
│  ┌────────────────────────────────────────────────────┐      │
│  │  forward-proxy-standalone-secret                   │      │
│  │    └─ Used by: forward-proxy Deployment            │      │
│  └────────────────────────────────────────────────────┘      │
│                                                               │
│  ┌────────────────────────────────────────────────────┐      │
│  │  reverse-proxy-standalone-secret                   │      │
│  │    └─ Used by: reverse-proxy Deployment            │      │
│  └────────────────────────────────────────────────────┘      │
│                                                               │
│  ┌────────────────────────────────────────────────────┐      │
│  │  spa-frontend-secret                               │      │
│  │    └─ Used by: spa-frontend Deployment             │      │
│  └────────────────────────────────────────────────────┘      │
│                                                               │
│  ┌────────────────────────────────────────────────────┐      │
│  │  spa-backend-secret                                │      │
│  │    └─ Used by: spa-backend Deployment              │      │
│  └────────────────────────────────────────────────────┘      │
└──────────────────────────────────────────────────────────────┘
```

---

## Summary

This architecture demonstrates:

1. **Microservices Pattern**: Separated concerns with dedicated services for auth, proxying, and SPA
2. **Service Provider Multi-tenancy**: SP-labeled deployments allow isolated service provider instances
3. **Sidecar Pattern**: Telegraf containers for distributed metrics collection
4. **StatefulSet Pattern**: For databases requiring persistent identity and storage
5. **Init Container Pattern**: Database migrations before application startup
6. **Horizontal Scaling**: HPA-managed auto-scaling based on resource utilization
7. **Health Monitoring**: Liveness and readiness probes on all services
8. **Persistent Storage**: PVCs for database data retention
9. **Configuration Management**: Secrets and ConfigMaps for environment-specific config
10. **Ingress Routing**: NGINX-based routing to internal services

The architecture is designed for development on Kind but can be adapted for production Kubernetes clusters by adjusting resource limits, storage classes, and ingress configurations.

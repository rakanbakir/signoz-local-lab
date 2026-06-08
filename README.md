# signoz-local-lab

Single-node SigNoz observability lab on Kind (Kubernetes-in-Docker). Includes a Python Flask demo app with manual OpenTelemetry instrumentation (traces, metrics, logs), hostmetrics collection, infrastructure monitoring, and pre-built dashboards. Designed for learning observability on a laptop.

## Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                        Kind Cluster                               │
│                                                                  │
│  ┌──────────┐   ┌──────────────┐   ┌──────────────────────────┐  │
│  │  nginx   │   │  SigNoz      │   │  Platform                │  │
│  │  ingress │──▶│  Frontend    │   │  ClickHouse + Zookeeper   │  │
│  │  :80/443 │   │  :8080       │   │  SigNoz OTel Collector   │  │
│  └──────────┘   └──────────────┘   └──────────────────────────┘  │
│                                                                  │
│  ┌──────────────┐   ┌────────────────────────────┐               │
│  │  OTel        │   │  k8s-collector             │               │
│  │  Operator    │──▶│  DaemonSet                  │──────────────┤
│  └──────────────┘   │  traces + metrics + logs   │               │
│                     │  + hostmetrics              │               │
│  ┌──────────────┐   └────────────────────────────┘               │
│  │  Demo Apps   │──▶  OTLP :4317/:4318                            │
│  │  (basic-demo)│                                                │
│  └──────────────┘                                                │
└──────────────────────────────────────────────────────────────────┘
```

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/)
- [Kind](https://kind.sigs.k8s.io/) (`brew install kind`)
- [kubectl](https://kubernetes.io/docs/tasks/tools/) (`brew install kubectl`)
- [Helm](https://helm.sh/) (`brew install helm`)

## Quick Start

```bash
# Create cluster and deploy everything
bash setup.sh

# Access SigNoz
# Add to /etc/hosts: 127.0.0.1 signoz.local
open http://signoz.local

# Generate traces (in a new terminal)
kubectl port-forward -n demo svc/basic-demo 8080:80
curl http://localhost:8080/
curl http://localhost:8080/api/users
curl http://localhost:8080/api/users/1
```

## What's Deployed

| Component | Description |
|-----------|-------------|
| **SigNoz** | Observability platform (frontend, query service, alertmanager) |
| **ClickHouse** | Telemetry datastore (traces, metrics, logs) |
| **k8s-collector** | OTel Collector DaemonSet — collects cluster-wide telemetry |
| **OTel Operator** | Manages OpenTelemetry collectors and auto-instrumentation |
| **basic-demo** | Python Flask app with manual OTel instrumentation |
| **nginx-ingress** | Ingress controller for signoz.local access |
| **cert-manager** | TLS certificate management for OTel Operator |

Optional demo apps (deploy manually):

| Component | Description |
|-----------|-------------|
| **trace-demo** | Simple Python trace generator (`kubectl apply -f trace-demo/trace-demo.yaml`) |

## Demo App

The `basic-demo` is a Flask app in `demo/basic-demo/` with three endpoints:

```
GET /               → Home page
GET /api/users      → List users (with DB query span)
GET /api/users/<id> → Get user (with cache-check → DB fetch spans)
```

Each endpoint creates a hierarchy of manual spans and exports OTLP telemetry (traces, metrics, logs) to the k8s-collector.

## Dashboards

Import pre-built dashboards:

```bash
# Get auth token from browser console:
#   JSON.parse(localStorage.getItem('AUTH_TOKEN')).accessJwt
SIGNOZ_TOKEN="<token>" bash dashboards/setup.sh
```

| Dashboard | What it shows |
|-----------|---------------|
| Basic Demo Overview | Request rate, errors, p99 latency (traces-based) |
| Basic Demo HTTP Metrics | HTTP request metrics from OTel SDK |
| APM Metrics | Auto-generated span latency/error metrics |
| Host Metrics | CPU, memory, disk, network usage |
| ClickHouse | ClickHouse query performance |
| Flask Monitoring | (Included but requires Prometheus-style metrics) |

## Project Structure

```
├── setup.sh                       # Main setup script
├── signoz-values.yaml             # SigNoz Helm chart values
├── kind-config.yaml               # Kind cluster configuration
├── otel-collector-daemonset.yaml  # k8s-collector DaemonSet + RBAC
├── otel-instrumentation.yaml      # Auto-instrumentation CR
├── demo/
│   └── basic-demo/
│       └── deploy.yaml            # Flask app (ConfigMap + Deployment)
├── dashboards/
│   ├── setup.sh                   # Dashboard import script
│   └── *.json                     # Dashboard JSON templates
├── online-boutique/               # Google microservices demo
├── trace-demo/                    # Trace generator
├── openspec/
│   └── specs/                     # OpenSpec specifications
└── .opencode/                     # OpenCode + OpenSpec integration
```

## Spec-Driven Development

This project uses [OpenSpec](https://openspec.dev/) for spec-driven development. Specs live in `openspec/specs/` and describe the system requirements. Changes are proposed, designed, and tracked through the OpenSpec workflow.

## License

MIT

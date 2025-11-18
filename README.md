# KEDA RabbitMQ Demo

A comprehensive demonstration of Kubernetes Event-Driven Autoscaling (KEDA) with RabbitMQ, comparing KEDA's native autoscaling capabilities with Prometheus Adapter-based scaling.

## Overview

This demo showcases how to implement event-driven autoscaling in Kubernetes using:
- **KEDA** - Event-driven autoscaling based on RabbitMQ queue depth
- **Prometheus Adapter** - Metrics-based autoscaling using custom Prometheus metrics
- **RabbitMQ** - Message broker for the producer/consumer pattern
- **Golang** - Producer and consumer applications

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Kubernetes Cluster                      │
│                                                               │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐  │
│  │   Producer   │───▶│   RabbitMQ   │◀───│   Consumer   │  │
│  │  (Golang)    │    │   (Queue)    │    │  (Golang)    │  │
│  └──────────────┘    └──────┬───────┘    └──────┬───────┘  │
│                              │                    │          │
│                              ▼                    ▼          │
│  ┌──────────────────────────────────────────────────────┐  │
│  │              Prometheus (Metrics)                    │  │
│  └───────────────────────┬──────────────────────────────┘  │
│                          │                                  │
│         ┌────────────────┴────────────────┐                │
│         ▼                                  ▼                │
│  ┌─────────────┐                  ┌──────────────────┐    │
│  │    KEDA     │                  │ Prometheus       │    │
│  │  ScaledObj  │                  │ Adapter (HPA)    │    │
│  └──────┬──────┘                  └────────┬─────────┘    │
│         │                                   │               │
│         └──────────▶ Auto-Scale ◀──────────┘               │
│                     Consumer Pods                           │
└─────────────────────────────────────────────────────────────┘
```

## Project Structure

```
keda-rabbitmq-demo/
├── cmd/                          # Application entry points
│   ├── producer/                 # Producer application
│   │   └── main.go
│   └── consumer/                 # Consumer application
│       └── main.go
├── internal/                     # Internal packages
│   ├── rabbitmq/                 # RabbitMQ client
│   │   └── client.go
│   └── message/                  # Message structures
│       └── message.go
├── k8s/                          # Kubernetes manifests
│   ├── namespace.yaml            # Demo namespace
│   ├── rabbitmq/                 # RabbitMQ deployment
│   │   ├── rabbitmq-deployment.yaml
│   │   ├── rabbitmq-service.yaml
│   │   └── rabbitmq-secret.yaml
│   ├── monitoring/               # Prometheus for metrics
│   │   ├── prometheus-deployment.yaml
│   │   ├── prometheus-service.yaml
│   │   ├── prometheus-configmap.yaml
│   │   └── prometheus-rbac.yaml
│   ├── apps/                     # Application deployments
│   │   ├── app-configmap.yaml
│   │   ├── producer-deployment.yaml
│   │   └── consumer-deployment.yaml
│   └── autoscaling/              # Autoscaling configurations
│       ├── prometheus-adapter/
│       │   └── hpa-prometheus.yaml
│       └── keda/
│           ├── trigger-auth.yaml
│           └── scaled-object.yaml
├── scripts/                      # Management scripts
│   ├── deploy.sh                 # Deploy infrastructure
│   ├── teardown.sh               # Remove infrastructure
│   ├── install-keda.sh           # Install KEDA
│   ├── build-images.sh           # Build Docker images
│   ├── deploy-apps.sh            # Deploy applications
│   ├── start-producing.sh        # Start producer
│   ├── stop-producing.sh         # Stop producer
│   ├── start-consuming.sh        # Start consumer
│   ├── stop-consuming.sh         # Stop consumer
│   ├── demo-status.sh            # Show demo status
│   ├── install-prometheus-adapter.sh  # Install Prometheus Adapter
│   ├── enable-hpa.sh             # Enable HPA autoscaling
│   ├── disable-hpa.sh            # Disable HPA autoscaling
│   ├── enable-keda-scaling.sh    # Enable KEDA autoscaling
│   ├── disable-keda-scaling.sh   # Disable KEDA autoscaling
│   └── scaling-status.sh         # Show autoscaling status
├── Dockerfile.producer           # Producer container image
├── Dockerfile.consumer           # Consumer container image
├── go.mod                        # Go module definition
├── go.sum                        # Go module checksums
├── Makefile                      # Convenient command interface
└── README.md                     # This file
```

## Prerequisites

Before running this demo, ensure you have the following installed:

- **Docker** - Container runtime ([Install Docker](https://docs.docker.com/get-docker/))
- **Kubernetes** - Local cluster (minikube, kind, or Docker Desktop)
  - [Docker Desktop Kubernetes](https://docs.docker.com/desktop/kubernetes/)
  - [minikube](https://minikube.sigs.k8s.io/docs/start/)
  - [kind](https://kind.sigs.k8s.io/docs/user/quick-start/)
- **kubectl** - Kubernetes CLI ([Install kubectl](https://kubernetes.io/docs/tasks/tools/))
- **Helm** - Kubernetes package manager ([Install Helm](https://helm.sh/docs/intro/install/))

### Verify Prerequisites

```bash
# Check Docker
docker --version

# Check Kubernetes cluster
kubectl cluster-info

# Check kubectl
kubectl version --client

# Check Helm
helm version
```

## Quick Start (Layer 1)

### 1. Deploy Infrastructure

Deploy RabbitMQ, Prometheus, and KEDA:

```bash
make deploy
```

This command will:
- Create the `keda-demo` namespace
- Deploy RabbitMQ with management UI
- Deploy Prometheus for metrics collection
- Install KEDA using Helm
- Wait for all components to be ready

### 2. Verify Deployment

Check the status of all components:

```bash
make status
```

### 3. Access Services

**RabbitMQ Management UI:**
```bash
make rabbitmq-ui
# Open http://localhost:15672
# Username: guest
# Password: guest
```

**Prometheus UI:**
```bash
make prometheus-ui
# Open http://localhost:9090
```

### 4. View Logs

**RabbitMQ logs:**
```bash
make logs-rabbitmq
```

**KEDA operator logs:**
```bash
make logs-keda
```

**Prometheus logs:**
```bash
make logs-prometheus
```

### 5. Teardown

Remove all infrastructure:

```bash
make teardown
```

## Layer 1: Base Infrastructure ✅

**Status:** Complete

Layer 1 provides the foundational infrastructure for the demo:

### Components

- **Kubernetes Namespace** (`keda-demo`) - Isolates all demo resources
- **RabbitMQ** - Message broker with management UI
  - Service: `rabbitmq.keda-demo.svc.cluster.local:5672`
  - Management UI: Port-forward to `localhost:15672`
  - Credentials: `guest/guest`
- **Prometheus** - Metrics collection and monitoring
  - Service: `prometheus.keda-demo.svc.cluster.local:9090`
  - UI: Port-forward to `localhost:9090`
  - Configured to scrape pods with `prometheus.io/*` annotations
- **KEDA** - Kubernetes Event-Driven Autoscaling
  - Installed in `keda` namespace via Helm
  - Prometheus integration enabled
  - MetricServer enabled for custom metrics

### Available Commands

```bash
make help          # Show all available commands
make deploy        # Deploy all infrastructure
make teardown      # Remove all infrastructure
make status        # Show status of all components
make rabbitmq-ui   # Access RabbitMQ Management UI
make prometheus-ui # Access Prometheus UI
make logs-rabbitmq # Tail RabbitMQ logs
make logs-keda     # Tail KEDA operator logs
```

## Layer 2: Golang Applications ✅

**Status:** Complete

Layer 2 provides the producer and consumer applications:

### Components

- **Producer Application** - Golang app that sends messages to RabbitMQ
  - Configurable message rate (default: 10 msg/sec)
  - Configurable message size (default: 1024 bytes)
  - JSON message format with ID, timestamp, and payload
  - Graceful shutdown on SIGTERM
  
- **Consumer Application** - Golang app that processes messages from RabbitMQ
  - Configurable processing delay (default: 100ms to simulate work)
  - Configurable prefetch count (default: 1)
  - Calculates and logs message latency
  - Graceful shutdown with message completion

- **Docker Images** - Multi-stage builds for minimal size
  - `keda-demo-producer:latest`
  - `keda-demo-consumer:latest`
  - Alpine-based runtime
  - Non-root user for security

### Configuration

Applications are configured via environment variables from ConfigMap:

- `QUEUE_NAME` - Queue name (default: `demo-queue`)
- `MESSAGE_RATE` - Messages per second for producer
- `MESSAGE_SIZE` - Payload size in bytes
- `PROCESSING_DELAY_MS` - Simulated processing time for consumer
- `PREFETCH_COUNT` - Number of unacked messages for consumer

### Available Commands

```bash
# Build and deploy applications
make build-apps      # Build Docker images
make deploy-apps     # Deploy to Kubernetes

# Control demo
make start-producing # Start message production
make stop-producing  # Stop message production
make start-consuming # Start message consumption
make stop-consuming  # Stop message consumption
make demo-status     # Show queue depth and pod status

# View logs
make logs-producer   # Tail producer logs
make logs-consumer   # Tail consumer logs
```

### Quick Start (Layer 2)

After completing Layer 1:

```bash
# 1. Build and deploy applications
make deploy-apps

# 2. Start producing messages
make start-producing

# 3. Check queue building up
make demo-status
# or
make rabbitmq-ui

# 4. Start consuming messages
make start-consuming

# 5. Watch the demo in action
make logs-producer   # In one terminal
make logs-consumer   # In another terminal
```

## Layer 3: Autoscaling Configurations ✅

**Status:** Complete

Layer 3 provides two mutually exclusive autoscaling approaches for comparing traditional Kubernetes HPA with KEDA:

### Autoscaling Options

#### Option 1: HPA + Prometheus Adapter

Traditional Kubernetes approach using custom metrics from Prometheus:

- **Prometheus** scrapes RabbitMQ queue metrics
- **Prometheus Adapter** exposes metrics as Kubernetes custom metrics API
- **HPA** scales consumer deployment based on queue depth
- **Min replicas**: 1 (cannot scale to zero)
- **Target**: 5 messages per pod

**Pros:**
- Standard Kubernetes approach
- Works with any Prometheus metric
- Fine-grained control over HPA behavior

**Cons:**
- More complex setup (Adapter + HPA)
- Cannot scale to zero
- Metric lag through Prometheus scraping

#### Option 2: KEDA Prometheus Scaler

Event-driven autoscaling using Prometheus metrics:

- **KEDA** queries Prometheus for RabbitMQ queue metrics
- **ScaledObject** automatically manages HPA creation
- **Prometheus plugin** exposes RabbitMQ queue depth metrics
- **Min replicas**: 0 (can scale to zero!)
- **Target**: 5 messages per pod

**Pros:**
- Simpler configuration (single ScaledObject)
- Uses same metrics as HPA approach (fair comparison)
- Can scale to zero when queue is empty
- Avoids deprecated RabbitMQ management API
- Event-driven architecture

**Cons:**
- Requires KEDA installation
- Requires Prometheus infrastructure

### Configuration Details

Both methods use the same threshold for fair comparison:
- **Queue depth target**: 5 messages per pod
- **Max replicas**: 10
- **Scaling calculation**: `desired_replicas = queue_depth / 5`

Example: If queue has 50 messages → 50 / 5 = 10 pods

### Available Commands

```bash
# Prometheus Adapter (if not already installed)
make install-prometheus-adapter

# Enable HPA + Prometheus Adapter scaling
make enable-hpa

# Disable HPA scaling
make disable-hpa

# Enable KEDA autoscaling
make enable-keda

# Disable KEDA autoscaling
make disable-keda

# Check which method is active
make scaling-status

# Watch scaling in real-time
make watch-scaling
```

### Comparison Table

| Feature | HPA + Prometheus Adapter | KEDA |
|---------|-------------------------|------|
| **Setup Complexity** | High (Adapter + HPA) | Low (ScaledObject only) |
| **Min Replicas** | 1 | 0 (scale to zero!) |
| **Metric Source** | Prometheus (via Adapter) | Prometheus (via KEDA) |
| **Latency** | Similar (both query Prometheus) | Similar (both query Prometheus) |
| **Flexibility** | Any Prometheus metric | Event source specific |
| **Standard K8s** | Yes | Requires KEDA |
| **Configuration** | Multiple resources | Single ScaledObject |
| **Scale to Zero** | No | Yes |

### Quick Start (Layer 3)

After completing Layers 1 and 2:

#### Testing HPA + Prometheus Adapter

```bash
# 1. Enable HPA-based autoscaling
make enable-hpa

# 2. Start producing messages
make start-producing

# 3. Watch HPA scale up consumer pods
make scaling-status
# or
make watch-scaling

# 4. View in RabbitMQ UI
make rabbitmq-ui

# 5. Stop producing and watch scale down
make stop-producing

# 6. Disable HPA when done
make disable-hpa
```

#### Testing KEDA Autoscaling

```bash
# 1. Enable KEDA autoscaling (starts at 0 replicas)
make enable-keda

# 2. Start producing messages
make start-producing

# 3. Watch KEDA scale up from 0
make scaling-status
# or
kubectl get scaledobject -n keda-demo --watch

# 4. View in RabbitMQ UI
make rabbitmq-ui

# 5. Stop producing and watch scale back to 0
make stop-producing

# 6. Disable KEDA when done
make disable-keda
```

### Mutual Exclusion

Only one autoscaling method can be active at a time. The scripts enforce this:

```bash
# This will fail if HPA is active
make enable-keda
# Error: HPA autoscaling is currently active.
# Please disable HPA first: make disable-hpa

# Switch between methods
make disable-hpa
make enable-keda
```

## Demo Scenarios

### Scenario 1: Setup
```bash
# User pulls down the repo and deploys infrastructure
make deploy
```

### Scenario 2: Start Demo (Layer 2)
```bash
# Deploy applications
make deploy-apps

# Start producing messages (consumer not started yet)
make start-producing

# Watch queue depth grow
make demo-status
```

### Scenario 3: Enable Consumption (Layer 2)
```bash
# Start consuming messages from RabbitMQ
make start-consuming

# Monitor consumption
make logs-consumer
```

### Scenario 4: HPA Autoscaling (Layer 3)
```bash
# Enable HPA + Prometheus Adapter autoscaling
make enable-hpa

# Producer should already be running from Scenario 2
# If not, start it:
make start-producing

# Watch HPA scale consumer pods based on queue depth
make watch-scaling
# or
make scaling-status

# View queue and metrics in RabbitMQ UI
make rabbitmq-ui

# Stop producing to see scale down
make stop-producing
```

### Scenario 5: KEDA Autoscaling (Layer 3)
```bash
# Switch to KEDA autoscaling
make disable-hpa
make enable-keda

# Start producing messages
make start-producing

# Watch KEDA scale from 0 to multiple pods
make scaling-status
kubectl get scaledobject -n keda-demo --watch

# View queue in RabbitMQ UI
make rabbitmq-ui

# Stop producing and watch KEDA scale back to 0
make stop-producing
```

### Scenario 6: Comparison & Teardown
```bash
# Compare both autoscaling methods
# 1. Test HPA
make enable-hpa
make start-producing
# Observe scaling behavior, note: min replicas = 1

make stop-producing
make disable-hpa

# 2. Test KEDA
make enable-keda
make start-producing
# Observe scaling behavior, note: can scale to 0!

make stop-producing
# Watch KEDA scale to 0 after cooldown period

# Final teardown
make disable-keda
make teardown
```

## Troubleshooting

### Layer 3 Issues

#### Prometheus Adapter Not Installing

Check Helm repository:
```bash
helm repo list
helm repo update
```

Verify Prometheus is running:
```bash
kubectl get svc prometheus -n keda-demo
```

#### HPA Shows "Unknown" Metrics

Wait for Prometheus Adapter to collect metrics (may take 1-2 minutes):
```bash
# Check if custom metrics API is available
kubectl get apiservice v1beta1.custom.metrics.k8s.io

# Check Prometheus Adapter logs
kubectl logs -n keda-demo -l app.kubernetes.io/name=prometheus-adapter

# Verify metric is available
kubectl get --raw "/apis/custom.metrics.k8s.io/v1beta1/namespaces/keda-demo/services/rabbitmq/rabbitmq_queue_messages_ready"
```

Ensure RabbitMQ is exposing metrics:
```bash
# Check if RabbitMQ Prometheus plugin is enabled
kubectl exec -n keda-demo -l app=rabbitmq -- rabbitmq-plugins list | grep prometheus

# Verify metrics endpoint
kubectl exec -n keda-demo -l app=rabbitmq -- wget -qO- http://localhost:15692/metrics | head
```

#### KEDA ScaledObject Not Scaling

Check ScaledObject status:
```bash
kubectl describe scaledobject consumer-scaledobject -n keda-demo
```

Verify KEDA operator is running:
```bash
kubectl get pods -n keda
kubectl logs -n keda -l app=keda-operator
```

Verify Prometheus is accessible from KEDA:
```bash
# Check Prometheus service
kubectl get svc prometheus -n keda-demo

# Test Prometheus query
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- \
  curl -s "http://prometheus.keda-demo.svc.cluster.local:9090/api/v1/query?query=rabbitmq_queue_messages_ready"
```

Check if RabbitMQ metrics are in Prometheus:
```bash
# View Prometheus UI and search for: rabbitmq_queue_messages_ready{queue="demo-queue"}
make prometheus-ui
```

#### Both Autoscaling Methods Active

This shouldn't happen, but if it does:
```bash
# Disable both
make disable-hpa
make disable-keda

# Verify nothing is active
make scaling-status

# Enable the one you want
make enable-keda  # or make enable-hpa
```

#### Consumer Not Scaling as Expected

Check queue has messages:
```bash
make demo-status
make rabbitmq-ui
```

Ensure producer is running:
```bash
kubectl get pods -n keda-demo -l app=producer
make logs-producer
```

Check consumer deployment is not manually scaled:
```bash
kubectl get deployment consumer -n keda-demo
```

### Layer 2 Issues

#### Docker Images Not Building

Check Docker is running:
```bash
docker ps
```

Ensure Go dependencies are downloaded:
```bash
go mod download
```

#### Pods Not Starting

Check image pull policy and availability:
```bash
kubectl describe pod -n keda-demo -l app=producer
kubectl describe pod -n keda-demo -l app=consumer
```

For kind clusters, ensure images are loaded:
```bash
kind load docker-image keda-demo-producer:latest
kind load docker-image keda-demo-consumer:latest
```

#### Producer/Consumer Connection Errors

Verify RabbitMQ is running:
```bash
kubectl get pods -n keda-demo -l app=rabbitmq
```

Check connection string in secret:
```bash
kubectl get secret rabbitmq-secret -n keda-demo -o jsonpath='{.data.connectionString}' | base64 -d
```

### RabbitMQ Not Starting

Check RabbitMQ logs:
```bash
make logs-rabbitmq
```

Verify RabbitMQ pod status:
```bash
kubectl get pods -n keda-demo -l app=rabbitmq
kubectl describe pod -n keda-demo -l app=rabbitmq
```

### KEDA Not Installing

Check Helm installation:
```bash
helm list -n keda
```

Verify KEDA pods:
```bash
kubectl get pods -n keda
make logs-keda
```

### Cannot Access Services

Ensure port-forwarding is active:
```bash
# List all port-forwards
ps aux | grep "port-forward"
```

### Kubernetes Cluster Not Accessible

Verify cluster is running:
```bash
kubectl cluster-info
kubectl get nodes
```

For Docker Desktop, ensure Kubernetes is enabled in settings.

## Resources

- [KEDA Documentation](https://keda.sh/)
- [KEDA at Zapier (CNCF Blog)](https://www.cncf.io/blog/2022/01/21/keda-at-zapier/)
- [RabbitMQ Documentation](https://www.rabbitmq.com/documentation.html)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Kubernetes HPA Documentation](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)

## License

MIT

## Contributing

This is a demo project. Feel free to extend and modify for your learning purposes

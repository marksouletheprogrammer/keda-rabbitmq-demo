.PHONY: help deploy teardown status rabbitmq-ui prometheus-ui logs-rabbitmq logs-prometheus logs-keda clean \
        build-apps deploy-apps start-producing stop-producing start-consuming stop-consuming demo-status \
        logs-producer logs-consumer install-prometheus-adapter enable-hpa disable-hpa enable-keda \
        disable-keda scaling-status watch-scaling

# Default target
help:
	@echo "=========================================="
	@echo "KEDA RabbitMQ Demo - Available Commands"
	@echo "=========================================="
	@echo ""
	@echo "Infrastructure:"
	@echo "  make deploy         - Deploy all infrastructure (RabbitMQ, Prometheus, KEDA)"
	@echo "  make teardown       - Remove all infrastructure"
	@echo "  make status         - Show status of all components"
	@echo ""
	@echo "Applications:"
	@echo "  make build-apps     - Build producer and consumer Docker images"
	@echo "  make deploy-apps    - Deploy producer and consumer applications"
	@echo "  make start-producing - Start message production"
	@echo "  make stop-producing  - Stop message production"
	@echo "  make start-consuming - Start message consumption"
	@echo "  make stop-consuming  - Stop message consumption"
	@echo "  make demo-status     - Show demo status (queue depth, pods, etc.)"
	@echo ""
	@echo "Autoscaling:"
	@echo "  make install-prometheus-adapter - Install Prometheus Adapter"
	@echo "  make enable-hpa      - Enable HPA + Prometheus Adapter scaling"
	@echo "  make disable-hpa     - Disable HPA scaling"
	@echo "  make enable-keda     - Enable KEDA autoscaling"
	@echo "  make disable-keda    - Disable KEDA autoscaling"
	@echo "  make scaling-status  - Show active autoscaling method and status"
	@echo "  make watch-scaling   - Watch autoscaling in real-time"
	@echo ""
	@echo "Access Services:"
	@echo "  make rabbitmq-ui    - Port-forward to RabbitMQ Management UI"
	@echo "  make prometheus-ui  - Port-forward to Prometheus UI"
	@echo ""
	@echo "Logs:"
	@echo "  make logs-rabbitmq   - Tail RabbitMQ logs"
	@echo "  make logs-prometheus - Tail Prometheus logs"
	@echo "  make logs-keda       - Tail KEDA operator logs"
	@echo "  make logs-producer   - Tail producer logs"
	@echo "  make logs-consumer   - Tail consumer logs"
	@echo ""
	@echo "Other:"
	@echo "  make clean          - Clean up local build artifacts"
	@echo ""

# Deploy all infrastructure
deploy:
	@./scripts/deploy.sh

# Teardown all infrastructure
teardown:
	@./scripts/teardown.sh

# Show status of all components
status:
	@echo "=========================================="
	@echo "Demo Components Status"
	@echo "=========================================="
	@echo ""
	@echo "Namespaces:"
	@kubectl get namespaces | grep -E '(NAME|keda-demo|keda)' || true
	@echo ""
	@echo "Demo Components (keda-demo namespace):"
	@kubectl get all -n keda-demo 2>/dev/null || echo "Namespace keda-demo not found"
	@echo ""
	@echo "KEDA Components (keda namespace):"
	@kubectl get all -n keda 2>/dev/null || echo "Namespace keda not found"
	@echo ""

# Port-forward to RabbitMQ Management UI
rabbitmq-ui:
	@echo "=========================================="
	@echo "RabbitMQ Management UI"
	@echo "=========================================="
	@echo ""
	@echo "Opening RabbitMQ Management UI..."
	@echo "URL: http://localhost:15672"
	@echo "Username: guest"
	@echo "Password: guest"
	@echo ""
	@echo "Press Ctrl+C to stop port forwarding"
	@echo ""
	@kubectl port-forward -n keda-demo svc/rabbitmq 15672:15672

# Port-forward to Prometheus UI
prometheus-ui:
	@echo "=========================================="
	@echo "Prometheus UI"
	@echo "=========================================="
	@echo ""
	@echo "Opening Prometheus UI..."
	@echo "URL: http://localhost:9090"
	@echo ""
	@echo "Press Ctrl+C to stop port forwarding"
	@echo ""
	@kubectl port-forward -n keda-demo svc/prometheus 9090:9090

# Tail RabbitMQ logs
logs-rabbitmq:
	@echo "Tailing RabbitMQ logs (Ctrl+C to exit)..."
	@kubectl logs -f -n keda-demo -l app=rabbitmq --tail=50

# Tail Prometheus logs
logs-prometheus:
	@echo "Tailing Prometheus logs (Ctrl+C to exit)..."
	@kubectl logs -f -n keda-demo -l app=prometheus --tail=50

# Tail KEDA operator logs
logs-keda:
	@echo "Tailing KEDA operator logs (Ctrl+C to exit)..."
	@kubectl logs -f -n keda -l app=keda-operator --tail=50

# Build Docker images for applications
build-apps:
	@./scripts/build-images.sh

# Deploy applications to Kubernetes
deploy-apps:
	@./scripts/deploy-apps.sh

# Start message production
start-producing:
	@./scripts/start-producing.sh

# Stop message production
stop-producing:
	@./scripts/stop-producing.sh

# Start message consumption
start-consuming:
	@./scripts/start-consuming.sh

# Stop message consumption
stop-consuming:
	@./scripts/stop-consuming.sh

# Show demo status
demo-status:
	@./scripts/demo-status.sh

# Tail producer logs
logs-producer:
	@echo "Tailing producer logs (Ctrl+C to exit)..."
	@kubectl logs -f -n keda-demo -l app=producer --tail=50

# Tail consumer logs
logs-consumer:
	@echo "Tailing consumer logs (Ctrl+C to exit)..."
	@kubectl logs -f -n keda-demo -l app=consumer --tail=50

# Install Prometheus Adapter
install-prometheus-adapter:
	@./scripts/install-prometheus-adapter.sh

# Enable HPA + Prometheus Adapter scaling
enable-hpa:
	@./scripts/enable-hpa.sh

# Disable HPA scaling
disable-hpa:
	@./scripts/disable-hpa.sh

# Enable KEDA autoscaling
enable-keda:
	@./scripts/enable-keda-scaling.sh

# Disable KEDA autoscaling
disable-keda:
	@./scripts/disable-keda-scaling.sh

# Show autoscaling status
scaling-status:
	@./scripts/scaling-status.sh

# Watch autoscaling in real-time
watch-scaling:
	@echo "Watching autoscaling (Ctrl+C to exit)..."
	@while true; do \
		clear; \
		echo "=== Consumer Pods ==="; \
		kubectl get pods -n keda-demo -l app=consumer 2>/dev/null || echo "No pods found"; \
		echo ""; \
		echo "=== Autoscaling Status ==="; \
		if kubectl get hpa consumer-hpa -n keda-demo 2>/dev/null; then \
			echo ""; \
		elif kubectl get scaledobject consumer-scaledobject -n keda-demo 2>/dev/null; then \
			echo ""; \
		else \
			echo "No autoscaling active"; \
		fi; \
		echo ""; \
		echo "=== Queue Status ==="; \
		POD=$$(kubectl get pods -n keda-demo -l app=rabbitmq -o jsonpath='{.items[0].metadata.name}' 2>/dev/null); \
		if [ -n "$$POD" ]; then \
			kubectl exec -n keda-demo "$$POD" -- rabbitmqadmin list queues name messages consumers -f tsv 2>/dev/null || echo "Could not fetch queue stats"; \
		else \
			echo "RabbitMQ pod not found"; \
		fi; \
		echo ""; \
		echo "Last updated: $$(date)"; \
		sleep 2; \
	done

# Clean up local artifacts
clean:
	@echo "Cleaning up local artifacts..."
	@rm -rf bin/
	@rm -rf tmp/
	@echo "✅ Clean complete"

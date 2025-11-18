.PHONY: help deploy teardown status rabbitmq-ui prometheus-ui logs-rabbitmq logs-prometheus logs-keda clean

# Default target
help:
	@echo "=========================================="
	@echo "KEDA RabbitMQ Demo - Available Commands"
	@echo "=========================================="
	@echo ""
	@echo "Infrastructure Management:"
	@echo "  make deploy         - Deploy all infrastructure (RabbitMQ, Prometheus, KEDA)"
	@echo "  make teardown       - Remove all infrastructure"
	@echo "  make status         - Show status of all components"
	@echo ""
	@echo "Access Services:"
	@echo "  make rabbitmq-ui    - Port-forward to RabbitMQ Management UI"
	@echo "  make prometheus-ui  - Port-forward to Prometheus UI"
	@echo ""
	@echo "Logs:"
	@echo "  make logs-rabbitmq  - Tail RabbitMQ logs"
	@echo "  make logs-prometheus - Tail Prometheus logs"
	@echo "  make logs-keda      - Tail KEDA operator logs"
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

# Clean up local artifacts
clean:
	@echo "Cleaning up local artifacts..."
	@rm -rf bin/
	@rm -rf tmp/
	@echo "✅ Clean complete"

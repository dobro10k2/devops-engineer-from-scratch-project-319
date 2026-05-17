# ==========================================
# TERRAFORM
# ==========================================
tf-init:
	cd terraform && terraform init

tf-plan:
	cd terraform && terraform plan

tf-apply:
	cd terraform && terraform apply -auto-approve

tf-destroy:
	cd terraform && terraform destroy -auto-approve

# Получить outputs
tf-outputs:
	cd terraform && terraform output

# ==========================================
# KUBERNETES & HELM
# ==========================================
KUBECTL = kubectl -n bulletin-board
MASTER_IP = $(shell cd terraform && terraform output -raw master_public_ip 2>/dev/null || echo "localhost")

# Получить kubeconfig
k8s-get-config:
	@echo "Скачивание kubeconfig с мастера..."
	scp ubuntu@$(MASTER_IP):/etc/rancher/k3s/k3s.yaml ~/.kube/config-k3s
	sed -i.bak 's/127.0.0.1/$(MASTER_IP)/g' ~/.kube/config-k3s
	@echo "✅ Готово! Используйте: export KUBECONFIG=~/.kube/config-k3s"

# Создание namespace (если еще нет)
k8s-namespace:
	kubectl apply -f k8s/namespace.yaml

# Деплой через Helm (локально, использует значения из values.yaml по умолчанию)
helm-deploy: k8s-namespace
	helm upgrade --install bulletin-board ./k8s/bulletin-board \
	  --namespace bulletin-board

# Откат релиза на предыдущую версию
helm-rollback:
	helm rollback bulletin-board 0 --namespace bulletin-board

# Полное удаление приложения
helm-clean:
	helm uninstall bulletin-board --namespace bulletin-board || true

# ==========================================
# KUBERNETES UTILS (DEBUG & CHECK)
# ==========================================
# Статус ресурсов
k8s-status:
	$(KUBECTL) get pods,svc,ingress,hpa,pdb -o wide

# Проверка нод
k8s-nodes:
	kubectl get nodes -o wide

# Проверка распределения подов по нодам
k8s-pod-distribution:
	kubectl get pods -n bulletin-board -o wide --sort-by=.spec.nodeName

# Порт форвард
k8s-port-forward:
	@echo "Приложение будет доступно на http://localhost:8080"
	$(KUBECTL) port-forward svc/bulletin-app 8080:8080

# Логи
k8s-logs:
	$(KUBECTL) logs -f deployment/bulletin-app --all-containers=true

# ==========================================
# OBSERVABILITY (STEP 5)
# ==========================================
k8s-deploy-monitoring:
	envsubst < k8s/monitoring/prometheus-agent.yaml | kubectl apply -f -

k8s-install-logging:
	helm upgrade --install fluent-bit oci://cr.yandex/yc-marketplace/yandex-cloud/fluent-bit/fluent-bit \
	  --namespace kube-system \
	  --version 4.2.3-1 \
	  --set auth.apiKey=$(OBSERVABILITY_API_KEY) \
	  --set loggingGroupId=$(LOG_GROUP_ID)

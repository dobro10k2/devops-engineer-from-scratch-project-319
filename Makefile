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

# Kubernetes
KUBECTL = kubectl -n bulletin-board
MASTER_IP = $(shell cd terraform && terraform output -raw master_public_ip 2>/dev/null || echo "localhost")

# Получить kubeconfig
k8s-get-config:
	@echo "Скачивание kubeconfig с мастера..."
	scp ubuntu@$(MASTER_IP):/etc/rancher/k3s/k3s.yaml ~/.kube/config-k3s
	sed -i.bak 's/127.0.0.1/$(MASTER_IP)/g' ~/.kube/config-k3s
	@echo "✅ Готово! Используйте: export KUBECONFIG=~/.kube/config-k3s"

# Первичный деплой
k8s-deploy:
	kubectl apply -f k8s/namespace.yaml
	kubectl apply -f k8s/configmap.yaml
	kubectl apply -f k8s/secret.yaml
	kubectl apply -f k8s/postgres/
	kubectl apply -f k8s/app/

# Step 4: Масштабирование и балансировка
k8s-scale:
	kubectl apply -f k8s/pdb.yaml
	kubectl apply -f k8s/hpa.yaml
	kubectl apply -f k8s/ingress.yaml
	@echo "✅ PDB, HPA и Ingress применены"

# Полный деплой (все включено)
k8s-deploy-full: k8s-deploy k8s-scale

# Удаление
k8s-clean:
	kubectl delete -f k8s/app/ || true
	kubectl delete -f k8s/postgres/ || true
	kubectl delete -f k8s/secret.yaml || true
	kubectl delete -f k8s/configmap.yaml || true
	kubectl delete -f k8s/namespace.yaml || true

# Мониторинг
k8s-status:
	$(KUBECTL) get pods,svc,ingress,hpa,pdb -o wide

# Проверка нод
k8s-nodes:
	kubectl get nodes -o wide

# Проверка распределения подов по нодам
k8s-pod-distribution:
	kubectl get pods -n bulletin-board -o wide --sort-by=.spec.nodeName

# Rolling update (тестовый деплой новой версии)
k8s-update:
	kubectl set image deployment/bulletin-app bulletin-app=ghcr.io/dobro10k2/project-devops-deploy:v2 -n bulletin-board
	kubectl rollout status deployment/bulletin-app -n bulletin-board

# Откат
k8s-rollback:
	kubectl rollout undo deployment/bulletin-app -n bulletin-board

# Порт форвард
k8s-port-forward:
	@echo "Приложение будет доступно на http://localhost:8080"
	$(KUBECTL) port-forward svc/bulletin-app 8080:8080

# Логи
k8s-logs:
	$(KUBECTL) logs -f deployment/bulletin-app --all-containers=true

k8s-deploy-monitoring:
	envsubst < k8s/monitoring/prometheus-agent.yaml | kubectl apply -f -

k8s-install-logging:
	helm upgrade --install fluent-bit oci://cr.yandex/yc-marketplace/yandex-cloud/fluent-bit/fluent-bit \
	  --namespace kube-system \
	  --version 0.2.0 \
	  --set auth.apiKey=$(OBSERVABILITY_API_KEY) \
	  --set loggingGroupId=$(LOG_GROUP_ID)

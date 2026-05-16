tf-init:
	cd terraform && terraform init

tf-plan:
	cd terraform && terraform plan

tf-apply:
	cd terraform && terraform apply -auto-approve

tf-destroy:
	cd terraform && terraform destroy -auto-approve

# Переменные для удобства
KUBECTL = kubectl -n bulletin-board

# Первичный деплой всех манифестов Kubernetes
k8s-deploy:
	kubectl apply -f k8s/namespace.yaml
	kubectl apply -f k8s/configmap.yaml
	kubectl apply -f k8s/secret.yaml
	kubectl apply -f k8s/postgres/
	kubectl apply -f k8s/app/

# Удаление всех ресурсов приложения
k8s-clean:
	kubectl delete -f k8s/app/ || true
	kubectl delete -f k8s/postgres/ || true
	kubectl delete -f k8s/secret.yaml || true
	kubectl delete -f k8s/configmap.yaml || true
	kubectl delete -f k8s/namespace.yaml || true

# Мониторинг состояния подов в реальном времени
k8s-status:
	$(KUBECTL) get pods,svc,statefulset,deployment -o wide

# Временный проброс портов для локальной проверки приложения
k8s-port-forward:
	@echo "Приложение будет доступно на http://localhost:8080"
	$(KUBECTL) port-forward svc/bulletin-app 8080:80

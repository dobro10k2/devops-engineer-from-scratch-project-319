tf-init:
	cd terraform && terraform init

tf-plan:
	cd terraform && terraform plan

tf-apply:
	cd terraform && terraform apply -auto-approve

tf-destroy:
	cd terraform && terraform destroy -auto-approve

tf-outputs:
	cd terraform && terraform output

KUBECTL = kubectl -n bulletin-board
MASTER_IP = $(shell cd terraform && terraform output -raw master_public_ip 2>/dev/null || echo "localhost")

k8s-get-config:
	@echo "Скачивание kubeconfig с мастера..."
	scp ubuntu@$(MASTER_IP):/etc/rancher/k3s/k3s.yaml ~/.kube/config-k3s
	sed -i.bak 's/127.0.0.1/$(MASTER_IP)/g' ~/.kube/config-k3s
	@echo "✅ Готово! Используйте: export KUBECONFIG=~/.kube/config-k3s"

k8s-namespace:
	kubectl apply -f k8s/namespace.yaml

k8s-install-eso:
	helm repo add external-secrets https://charts.external-secrets.io || true
	helm repo update
	helm upgrade --install external-secrets external-secrets/external-secrets \
	  --namespace external-secrets \
	  --create-namespace \
	  --set installCRDs=true

helm-deploy: k8s-namespace k8s-install-eso
	helm upgrade --install bulletin-board ./k8s/bulletin-board \
	  --namespace bulletin-board

helm-rollback:
	helm rollback bulletin-board 0 --namespace bulletin-board

helm-clean:
	helm uninstall bulletin-board --namespace bulletin-board || true

k8s-status:
	$(KUBECTL) get pods,svc,ingress,hpa,pdb,externalsecrets,secretstores -o wide

k8s-nodes:
	kubectl get nodes -o wide

k8s-pod-distribution:
	kubectl get pods -n bulletin-board -o wide --sort-by=.spec.nodeName

k8s-port-forward:
	@echo "Приложение будет доступно на http://localhost:8080"
	$(KUBECTL) port-forward svc/bulletin-app 8080:8080

k8s-logs:
	$(KUBECTL) logs -f deployment/bulletin-app --all-containers=true

k8s-deploy-monitoring:
	envsubst < k8s/monitoring/prometheus-agent.yaml | kubectl apply -f -

k8s-install-logging:
	@kubectl get namespace kube-system >/dev/null 2>&1 || kubectl create namespace kube-system
	@TOKEN=$$(kubectl get secret observability-secret -n bulletin-board -o jsonpath='{.data.api-key}' | base64 --decode) && \
	helm upgrade --install fluent-bit oci://cr.yandex/yc-marketplace/yandex-cloud/fluent-bit/fluent-bit \
	  --namespace kube-system \
	  --version 4.2.3-1 \
	  --set auth.apiKey=$$TOKEN \
	  --set loggingGroupId=$(LOG_GROUP_ID)

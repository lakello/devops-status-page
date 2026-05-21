SHELL := /bin/bash

TF_DIR := terraform
K8S_DIR := k8s

APP_NAMESPACE := devops-status
INGRESS_NAMESPACE := ingress-nginx
INGRESS_RELEASE := ingress-nginx
INGRESS_HOST_PREFIX := devops-status

.PHONY: up infra kubeconfig ingress app url down destroy clean

up: infra kubeconfig ingress app url

infra:
	cd $(TF_DIR) && terraform init
	cd $(TF_DIR) && terraform fmt
	cd $(TF_DIR) && terraform validate
	cd $(TF_DIR) && terraform apply -auto-approve

kubeconfig:
	cd $(TF_DIR) && yc managed-kubernetes cluster get-credentials \
		--id $$(terraform output -raw cluster_id) \
		--external \
		--force

ingress:
	helm upgrade --install $(INGRESS_RELEASE) ingress-nginx \
		--repo https://kubernetes.github.io/ingress-nginx \
		--namespace $(INGRESS_NAMESPACE) \
		--create-namespace

	@echo "Waiting for ingress-nginx LoadBalancer external IP..."
	@for i in {1..60}; do \
		IP=$$(kubectl get svc $(INGRESS_RELEASE)-controller \
			-n $(INGRESS_NAMESPACE) \
			-o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null); \
		if [[ -n "$$IP" ]]; then \
			echo "$$IP" > .ingress-ip; \
			echo "Ingress external IP: $$IP"; \
			exit 0; \
		fi; \
		echo "Still waiting for external IP..."; \
		sleep 10; \
	done; \
	echo "ERROR: external IP was not assigned"; \
	exit 1

app:
	@IP=$$(cat .ingress-ip); \
	HOST="$(INGRESS_HOST_PREFIX).$$IP.nip.io"; \
	echo "Using host: $$HOST"; \
	kubectl apply -f $(K8S_DIR)/namespace.yaml; \
	kubectl apply -f $(K8S_DIR)/deployment.yaml; \
	kubectl apply -f $(K8S_DIR)/service.yaml; \
	sed "s|__APP_HOST__|$$HOST|g" $(K8S_DIR)/ingress.yaml.tpl | kubectl apply -f -

url:
	@IP=$$(cat .ingress-ip); \
	HOST="$(INGRESS_HOST_PREFIX).$$IP.nip.io"; \
	echo ""; \
	echo "Application URL:"; \
	echo "http://$$HOST"; \
	echo ""; \
	kubectl get pods -n $(APP_NAMESPACE); \
	kubectl get ingress -n $(APP_NAMESPACE)

down:
	kubectl delete -f $(K8S_DIR)/deployment.yaml --ignore-not-found=true
	kubectl delete -f $(K8S_DIR)/service.yaml --ignore-not-found=true
	kubectl delete ingress devops-status-page -n $(APP_NAMESPACE) --ignore-not-found=true
	kubectl delete namespace $(APP_NAMESPACE) --ignore-not-found=true

destroy:
	-kubectl delete namespace $(APP_NAMESPACE) --ignore-not-found=true
	-helm uninstall $(INGRESS_RELEASE) -n $(INGRESS_NAMESPACE)
	-kubectl delete namespace $(INGRESS_NAMESPACE) --ignore-not-found=true
	cd $(TF_DIR) && terraform destroy -auto-approve
	rm -f .ingress-ip

clean:
	rm -f .ingress-ip

###############################################
## Usage:
##     make tag=2.0.0
##     make build_src publish_src
##     make build_src publish_src tag=test
###############################################

# Docker Hub Organization
org ?= otusdevops202002lineate
export ORG=$(org)

# Tag/Version
tag ?= latest
export TAG=$(tag)

SHELL := /bin/bash

###############################################
## Build images from sources
## and push them to docker hub
###############################################
default: build_all publish_all

###############################################
## Build images
###############################################
build_all: build_src

build_src: build_crawler build_ui

# ---------------------------------------------- src
build_crawler:
	@echo Build docker image ${ORG}/search-engine-crawler:${TAG}
	docker build -t ${ORG}/search-engine-crawler:${TAG} -f ./docker/Dockerfile-crawler ./src/search_engine_crawler/

build_ui:
	@echo  Build docker image ${ORG}/search-engine-ui:${TAG}
	docker build -t ${ORG}/search-engine-ui:${TAG} -f ./docker/Dockerfile-ui ./src/search_engine_ui/

###############################################
## Push images to docker hub
###############################################

publish_all: publish_src

publish_src: public_crawler publish_ui

# ---------------------------------------------- src
public_crawler:
	@echo Push docker image ${ORG}/search-engine-crawler:${TAG}
	docker push ${ORG}/search-engine-crawler:${TAG}

publish_ui:
	@echo  Push docker image ${ORG}/search-engine-ui:${TAG}
	docker push ${ORG}/search-engine-ui:${TAG}

###############################################
## Launch the project
###############################################

infra_launch: git_submodules_clone terraform_configure terraform_apply gitlab_launch monitoring_launch project_launch

git_submodules_clone:
	git submodule init
	git submodule update

terraform_copy_variables:
	cp terraform/terraform.tfvars.example terraform/terraform.tfvars
	cp terraform/backend.tf.example terraform/backend.tf
	cp terraform/storage/terraform.tfvars.example terraform/storage/terraform.tfvars

terraform_configure: terraform_copy_variables
	@default_project=$$(sed 's/ / /g' terraform/terraform.tfvars | grep project | cut -d'"' -f 2); \
	read -p 'Enter GCP project ID['"$$default_project"']:' project; \
	[ -n "$$project" ] && sed -i 's/\(project.*= \).*/\1"'"$$project"'"/g' terraform/terraform.tfvars; \
	[ -n "$$project" ] && sed -i 's/\(project.*= \).*/\1"'"$$project"'"/g' terraform/storage/terraform.tfvars \
	|| echo "Using default project ID"
	@default_bucket=$$(sed 's/ / /g' terraform/storage/terraform.tfvars | grep terraform_backend_bucket_name | cut -d'"' -f 2); \
	read -p 'Enter unigue GCP bucket name['"$$default_bucket"']:' bucket; \
	[ -n "$$bucket" ] && sed -i 's/\( *bucket.*= \).*/\1"'"$$bucket"'"/g' terraform/backend.tf; \
	[ -n "$$bucket" ] && sed -i 's/\( *terraform_backend_bucket_name.*= \).*/\1"'"$$bucket"'"/g' terraform/storage/terraform.tfvars  \
	|| echo "Using default bucket name"

terraform_apply:
	cd terraform/storage; \
	terraform init; \
	terraform apply -auto-approve
	cd terraform; \
	terraform init; \
	terraform apply -auto-approve
	@cd terraform; \
	$$(terraform output | cut -d'=' -f 2)

gitlab_launch: gitlab_install gitlab_configure gitlab_set_ssh gitlab_prepare_projects

gitlab_install:
	@cd charts/gitlab-omnibus; \
	helm upgrade gitlab . -i -f values.yaml

gitlab_configure:
	@GITLAB_IP=''; \
	echo "Waiting for gitlab IP (with 60 seconds timeout)..."; \
	STARTTIME=$$(date +%s); \
	while [[ -z "$$GITLAB_IP" && "$$ELAPSED_TIME" -lt 60 ]]; \
	do \
		ENDTIME=$$(date +%s); \
		ELAPSED_TIME=$$(($$ENDTIME - $$STARTTIME)); \
		GITLAB_IP=$$(kubectl get service -n nginx-ingress nginx -o jsonpath="{.status.loadBalancer.ingress[0].ip}"); \
	done; \
	echo "--------------------------------"; \
	echo "==> Please add the following lines to /etc/hosts (requires sudo access):"; \
	echo ""; \
	echo ""; \
	echo "$$GITLAB_IP gitlab.search-engine staging.search-engine production.search-engine"; \
	echo "$$GITLAB_IP grafana.search-engine prometheus.search-engine alertmanager.search-engine"; \
	echo ""; \
	echo ""; \
	read -n 1 -p "==> Whet done with hosts file press any key to continue"; \
	echo ""; \
	echo "Waiting until gitlab is ready (with 10 minutes timeout)..."; \
	GITLAB_STATUS="false"; \
	STARTTIME=$$(date +%s); \
	while [[ "$$GITLAB_STATUS" != "true"  && "$$ELAPSED_TIME" -lt 600 ]]; \
	do \
		ENDTIME=$$(date +%s); \
		ELAPSED_TIME=$$(($$ENDTIME - $$STARTTIME)); \
		GITLAB_STATUS=$$(kubectl get pod -l name=gitlab-gitlab -o jsonpath="{.items[0].status.containerStatuses[0].ready}"); \
	done; \
	[ "$$GITLAB_STATUS" != "true" ] && echo "GITLAB_STATUS: $$GITLAB_STATUS" && echo "Gitlab launch failed. Please check gitlab status using kubectl get pods" && exit 1; \
	echo ""; \
	echo "--------------------------------"; \
	echo "==> Open http://gitlab.search-engine in your browser"; \
	echo "==> Set your root password"; \
	echo "==> Sign in as root using your password"; \
	echo "==> Go to http://gitlab.search-engine/profile/account"; \
	read -p "==> Copy Private token and paste here: " gitlab_private_token; \
	echo $$gitlab_private_token > gitlab-token.secret; \


gitlab_set_ssh:
	@TOKEN=$$(cat gitlab-token.secret); \
	DEFAULT_SSH_FILE="$$HOME/.ssh/id_rsa.pub"; \
	read -p 'Enter your SSH file location (would be used to push to GitLab)['"$$DEFAULT_SSH_FILE"']:' INPUT_SSH_FILE; \
	[ -n "$$INPUT_SSH_FILE" ] && SSH_FILE=$$INPUT_SSH_FILE || SSH_FILE=$$DEFAULT_SSH_FILE; \
	SSH_KEY=$$(cat $$SSH_FILE); \
	curl -X POST --header "PRIVATE-TOKEN: $$TOKEN" --header "Content-Type: application/json" \
		--data '{"title": "default-key", "key": "'"$$SSH_KEY"'"}' \
		http://gitlab.search-engine/api/v4/user/keys; \

gitlab_prepare_projects: gitlab_create_group gitlab_set_variables gitlab_create_projects

gitlab_create_group:
	@TOKEN=$$(cat gitlab-token.secret); \
	DEFAULT_GROUP_NAME='otusdevops202002lineate'; \
	echo "Creating group in GitLab..."; \
	read -p 'Enter Gitlab group name (should be the same as Docker Hub organization/user where images will be stored)['"$$DEFAULT_GROUP_NAME"']:' INPUT_GROUP_NAME; \
	[ -n "$$INPUT_GROUP_NAME" ] && GROUP_NAME=$$INPUT_GROUP_NAME || GROUP_NAME=$$DEFAULT_GROUP_NAME; \
	curl -X POST --header "PRIVATE-TOKEN: $$TOKEN" --header "Content-Type: application/json" \
		--data '{"name": "'"$$GROUP_NAME"'", "path": "'"$$GROUP_NAME"'", "visibility": "public"}' \
		http://gitlab.search-engine/api/v4/groups; \
    echo $$GROUP_NAME > gitlab-group.secret

gitlab_set_variables:
	@TOKEN=$$(cat gitlab-token.secret); \
	GROUP_NAME=$$(cat gitlab-group.secret); \
	echo "Setting variables in GitLab..."; \
	read -p 'Enter Docker Hub user:' CI_REGISTRY_USER; \
	curl -X POST --header "PRIVATE-TOKEN: $$TOKEN" --header "Content-Type: application/json" \
		--data '{"key": "CI_REGISTRY_USER", "value": "'"$$CI_REGISTRY_USER"'"}' \
		http://gitlab.search-engine/api/v4/groups/"$$GROUP_NAME"/variables; \
	read -p 'Enter Docker Hub user password:' CI_REGISTRY_PASSWORD; \
	curl -X POST --header "PRIVATE-TOKEN: $$TOKEN" --header "Content-Type: application/json" \
		--data '{"key": "CI_REGISTRY_PASSWORD", "value": "'"$$CI_REGISTRY_PASSWORD"'"}' \
		http://gitlab.search-engine/api/v4/groups/"$$GROUP_NAME"/variables

gitlab_create_projects:
	@TOKEN=$$(cat gitlab-token.secret); \
	GROUP_NAME=$$(cat gitlab-group.secret); \
	echo "Creating projects in GitLab..."; \
	NAMESPACE_ID=$$(curl -X GET --header "PRIVATE-TOKEN: $$TOKEN" --header "Content-Type: application/json" \
        --silent http://gitlab.search-engine/api/v4/namespaces?search="$$GROUP_NAME" | sed 's/.*"id":\([0-9]\).*/\1/'); \
	curl -X POST --header "PRIVATE-TOKEN: $$TOKEN" --header "Content-Type: application/json" \
		--data '{"name": "search-engine-infra", "namespace_id": "'"$$NAMESPACE_ID"'", "visibility": "public"}' \
		http://gitlab.search-engine/api/v4/projects; \
	echo ""; \
	curl -X POST --header "PRIVATE-TOKEN: $$TOKEN" --header "Content-Type: application/json" \
		--data '{"name": "search-engine-crawler", "namespace_id": "'"$$NAMESPACE_ID"'", "visibility": "public"}' \
		http://gitlab.search-engine/api/v4/projects; \
	echo ""; \
	curl -X POST --header "PRIVATE-TOKEN: $$TOKEN" --header "Content-Type: application/json" \
		--data '{"name": "search-engine-ui", "namespace_id": "'"$$NAMESPACE_ID"'", "visibility": "public"}' \
		http://gitlab.search-engine/api/v4/projects; \
	echo ""

monitoring_launch:
	@helm repo add bitnami https://charts.bitnami.com/bitnami; \
	cd ./charts/prometheus-operator; \
	helm upgrade --install prometheus bitnami/prometheus-operator --version 0.26.0 -f custom_values.yaml; \
	echo "Waiting until prometheus is ready (with 10 minutes timeout)..."; \
	PROMETHEUS_STATUS="false"; \
	STARTTIME=$$(date +%s); \
	while [[ "$$PROMETHEUS_STATUS" != "true"  && "$$ELAPSED_TIME" -lt 600 ]]; \
	do \
		ENDTIME=$$(date +%s); \
		ELAPSED_TIME=$$(($$ENDTIME - $$STARTTIME)); \
		PROMETHEUS_STATUS=$$(kubectl get pod -l "app.kubernetes.io/name=prometheus-operator" -o jsonpath="{.items[0].status.containerStatuses[0].ready}"); \
	done; \
	kubectl apply -f ./search-engine-service-monitors.yaml; \
	echo ""; \
	echo "***** Prometheus is ready! *****"; \
	echo "===> You can access Prometheus at:"; \
	echo "    http://prometheus.search-engine/"; \
	echo ""
	@cd ./charts/grafana; \
	kubectl create secret generic grafana-datasource-secret --from-file=datasources.yaml; \
	kubectl create configmap grafana-kubernetes-deployment-metrics --from-file=./dashboards/kubernetes-deployment-metrics.json; \
	kubectl create configmap grafana-kubernetes-cluster-monitoring --from-file=./dashboards/kubernetes-cluster-monitoring.json; \
	kubectl create configmap grafana-search-engine-metrics --from-file=./dashboards/search-engine-metrics.json; \
	helm upgrade --install grafana bitnami/grafana --version 3.3.1 -f custom-values.yaml; \
	echo "Waiting until Grafana is ready (with 10 minutes timeout)..."; \
	GRAFANA_STATUS="false"; \
	STARTTIME=$$(date +%s); \
	while [[ "$$GRAFANA_STATUS" != "true"  && "$$ELAPSED_TIME" -lt 600 ]]; \
	do \
		ENDTIME=$$(date +%s); \
		ELAPSED_TIME=$$(($$ENDTIME - $$STARTTIME)); \
		GRAFANA_STATUS=$$(kubectl get pod -l "app.kubernetes.io/name=grafana" -o jsonpath="{.items[0].status.containerStatuses[0].ready}"); \
	done; \
	echo ""; \
	echo "***** Grafana is ready! *****"; \
	echo "===> You can access Grafana at:"; \
	echo "    http://grafana.search-engine/"; \
	echo ""

project_launch:
	@ssh-keygen -f "/home/nshvyryaev/.ssh/known_hosts" -R "gitlab.search-engine"; \
	GROUP_NAME=$$(cat gitlab-group.secret); \
	cd src/search_engine_ui; \
	git remote rm gitlab; \
	git remote add gitlab git@gitlab.search-engine:"$$GROUP_NAME"/search-engine-ui.git; \
	git push gitlab master; \
	cd ../search_engine_crawler; \
	git remote rm gitlab; \
	git remote add gitlab git@gitlab.search-engine:"$$GROUP_NAME"/search-engine-crawler.git; \
	git push gitlab master; \
	cd ../..; \
	pwd; \
	TOKEN=$$(cat gitlab-token.secret); \
	PROJECT_UI_ID=$$(curl -X GET --header "PRIVATE-TOKEN: $$TOKEN" --header "Content-Type: application/json" \
        --silent http://gitlab.search-engine/api/v4/projects?search=search-engine-ui | sed 's/.*\[{"id":\([0-9]\).*/\1/'); \
	PROJECT_CRAWLER_ID=$$(curl -X GET --header "PRIVATE-TOKEN: $$TOKEN" --header "Content-Type: application/json" \
        --silent http://gitlab.search-engine/api/v4/projects?search=search-engine-crawler | sed 's/.*\[{"id":\([0-9]\).*/\1/'); \
	echo "Waiting for UI and Crawler builds to finish (with 10 minutes timeout)..."; \
	echo "===> You can check pipelines while waiting:"; \
	echo "    http://gitlab.search-engine/$$GROUP_NAME/search-engine-ui/pipelines"; \
	echo "    http://gitlab.search-engine/$$GROUP_NAME/search-engine-crawler/pipelines"; \
	BUILD_STATUS="running"; \
	STARTTIME=$$(date +%s); \
	while [[ "$$BUILD_STATUS" != "success"  && "$$BUILD_STATUS" != "failed"  && "$$BUILD_STATUS" != "canceled" && "$$BUILD_STATUS" != "manual" && "$$ELAPSED_TIME" -lt 600 ]]; \
	do \
		ENDTIME=$$(date +%s); \
		ELAPSED_TIME=$$(($$ENDTIME - $$STARTTIME)); \
		BUILD_STATUS=$$(curl -X GET --header "PRIVATE-TOKEN: $$TOKEN" --header "Content-Type: application/json" \
			 --silent http://gitlab.search-engine/api/v4/projects/"$$PROJECT_UI_ID"/pipelines | sed 's/.*"status":"\([a-z]*\)".*/\1/'); \
	done; \
	[ "$$BUILD_STATUS" != "success" ] && echo "UI build failed. Please check pipeline at http://gitlab.search-engine/$$GROUP_NAME/search-engine-ui/pipelines" && exit 1; \
	BUILD_STATUS="running"; \
	while [[ "$$BUILD_STATUS" != "success"  && "$$BUILD_STATUS" != "failed"  && "$$BUILD_STATUS" != "canceled" && "$$BUILD_STATUS" != "manual" && "$$ELAPSED_TIME" -lt 600 ]]; \
	do \
		ENDTIME=$$(date +%s); \
		ELAPSED_TIME=$$(($$ENDTIME - $$STARTTIME)); \
		BUILD_STATUS=$$(curl -X GET --header "PRIVATE-TOKEN: $$TOKEN" --header "Content-Type: application/json" \
			 --silent http://gitlab.search-engine/api/v4/projects/"$$PROJECT_CRAWLER_ID"/pipelines | sed 's/.*"status":"\([a-z]*\)".*/\1/'); \
	done; \
	[ "$$BUILD_STATUS" != "success" ] && echo "Crawler build failed. Please check pipeline at http://gitlab.search-engine/$$GROUP_NAME/search-engine-crawler/pipelines" && exit 1; \
	git remote rm gitlab; \
	git remote add gitlab git@gitlab.search-engine:"$$GROUP_NAME"/search-engine-infra.git; \
	git push gitlab master; \
	echo ""; \
	echo "***** Project is almost ready! *****"; \
	echo "===> Now you can open pipeline and wait until staging environment will be deployed:"; \
	echo "    http://gitlab.search-engine/$$GROUP_NAME/search-engine-infra/pipelines"; \
	echo ""; \
	echo "===> You can access Grafana at:"; \
	echo "    http://grafana.search-engine/"; \
	echo ""; \
	echo "===> You can access Prometheus at:"; \
	echo "    http://prometheus.search-engine/"; \
	echo ""

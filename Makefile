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

infra_launch: git_submodules_clone terraform_configure terraform_apply gitlab_launch

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
	[ -n "$$project" ] && sed 's/\(project.*= \).*/\1"'"$$project"'"/g' terraform/terraform.tfvars; \
	[ -n "$$project" ] && sed 's/\(project.*= \).*/\1"'"$$project"'"/g' terraform/storage/terraform.tfvars \
	|| echo "Using default project ID"
	@default_bucket=$$(sed 's/ / /g' terraform/storage/terraform.tfvars | grep terraform_backend_bucket_name | cut -d'"' -f 2); \
	read -p 'Enter unigue GCP bucket name['"$$default_bucket"']:' bucket; \
	[ -n "$$bucket" ] && sed 's/\( *bucket.*= \).*/\1"'"$$bucket"'"/g' terraform/backend.tf; \
	[ -n "$$bucket" ] && sed 's/\( *terraform_backend_bucket_name.*= \).*/\1"'"$$bucket"'"/g' terraform/storage/terraform.tfvars  \
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

gitlab_prepare_projects: gitlab_create_group gitlab_set_variables gitlab_create_projects gitlab_upload_repositories

gitlab_create_group:
	@TOKEN=$$(cat gitlab-token.secret); \
	DEFAULT_GROUP_NAME='otusdevops202002lineate'; \
	echo "Creating group in GitLab..."; \
	read -p 'Enter Gitlab group name['"$$DEFAULT_GROUP_NAME"']:' INPUT_GROUP_NAME; \
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

gitlab_upload_repositories:
	@ssh-keygen -f "/home/nshvyryaev/.ssh/known_hosts" -R "gitlab.search-engine"; \
	GROUP_NAME=$$(cat gitlab-group.secret); \
	git remote rm gitlab; \
	git remote add gitlab git@gitlab.search-engine:"$$GROUP_NAME"/search-engine-infra.git; \
	git push gitlab master; \
	cd src/search_engine_ui; \
	git remote rm gitlab; \
	git remote add gitlab git@gitlab.search-engine:"$$GROUP_NAME"/search-engine-ui.git; \
	git push gitlab master; \
	cd ../search_engine_crawler; \
	git remote rm gitlab; \
	git remote add gitlab git@gitlab.search-engine:"$$GROUP_NAME"/search-engine-crawler.git; \
	git push gitlab master; \
	echo ""; \
	echo "***** Everything is ready! *****"; \
	echo "===> Now you can open pipeline and wait until environment will be deployed:"; \
	echo "    http://gitlab.search-engine/$$GROUP_NAME/search-engine-infra/pipelines"; \
	echo ""

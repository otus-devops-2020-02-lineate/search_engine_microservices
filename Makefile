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


###############################################
## Build images from sources
## and push them to docker hub
###############################################
default: build_all publish_all

###############################################
## Build images
###############################################
build_all: build_src b_monitoring b_logging

build_src: build_crawler build_ui

b_monitoring: b_prometheus b_blackbox-exporter b_cloudprober b_alertmanager b_grafana

b_logging: b_fluentd

# ---------------------------------------------- src
build_crawler:
	@echo Build docker image ${ORG}/search-engine-crawler:${TAG}
	docker build -t ${ORG}/search-engine-crawler:${TAG} -f ./docker/Dockerfile-crawler ./src/search_engine_crawler/

build_ui:
	@echo  Build docker image ${ORG}/search-engine-ui:${TAG}
	docker build -t ${ORG}/search-engine-ui:${TAG} -f ./docker/Dockerfile-ui ./src/search_engine_ui/

# ---------------------------------------------- monitoring
build_prometheus:
	@echo  Build docker image for: prometheus
	docker build -t ${ORG}/prometheus:${TAG} ./monitoring/prometheus

build_blackbox-exporter:
	@echo  Build docker image ${ORG}/blackbox-exporter:${TAG}
	docker build -t ${ORG}/blackbox-exporter:${TAG} ./monitoring/blackbox-exporter

build_cloudprober:
	@echo  Build docker image ${ORG}/cloudprober:${TAG}
	docker build -t ${ORG}/cloudprober:${TAG} ./monitoring/cloudprober

build_alertmanager:
	@echo  Build docker image ${ORG}/alertmanager:${TAG}
	docker build -t ${ORG}/alertmanager:${TAG} ./monitoring/alertmanager

build_telegraf:
	@echo  Build docker image ${ORG}/telegraf:${TAG}
	docker build -t ${ORG}/telegraf:${TAG} ./monitoring/telegraf

build_grafana:
	@echo  Build docker image ${ORG}/grafana:${TAG}
	docker build -t ${ORG}/grafana:${TAG} ./monitoring/grafana

# ---------------------------------------------- logging
build_fluentd:
	@echo  Build docker image ${ORG}/fluentd:${TAG}
	docker build -t ${ORG}/fluentd:${TAG} ./logging/fluentd

###############################################
## Push images to docker hub
###############################################

publish_all: publish_src publish_monitoring publish_logging

publish_src: public_crawler publish_ui

publish_monitoring: publish_prometheus publish_blackbox-exporter publish_cloudprober publish_alertmanager publish_telegraf publish_grafana

publish_logging: publish_fluentd

# ---------------------------------------------- src
public_crawler:
	@echo Push docker image ${ORG}/search-engine-crawler:${TAG}
	docker push ${ORG}/search-engine-crawler:${TAG}

publish_ui:
	@echo  Push docker image ${ORG}/search-engine-ui:${TAG}
	docker push ${ORG}/search-engine-ui:${TAG}

# ---------------------------------------------- monitoring
publish_prometheus:
	@echo  Push docker image ${ORG}/prometheus:${TAG}
	docker push ${ORG}/prometheus:${TAG}

publish_blackbox-exporter:
	@echo  Push docker image ${ORG}/blackbox-exporter:${TAG}
	docker push ${ORG}/blackbox-exporter:${TAG}

publish_cloudprober:
	@echo  Push docker image ${ORG}/cloudprober:${TAG}
	docker push ${ORG}/cloudprober:${TAG}

publish_alertmanager:
	@echo  Push docker image ${ORG}/alertmanager:${TAG}
	docker push ${ORG}/alertmanager:${TAG}

publish_telegraf:
	@echo  Push docker image ${ORG}/telegraf:${TAG}
	docker push ${ORG}/telegraf:${TAG}

publish_grafana:
	@echo  Push docker image ${ORG}/grafana:${TAG}
	docker push ${ORG}/grafana:${TAG}

# ---------------------------------------------- logging
publish_fluentd:
	@echo  Push docker image ${ORG}/fluentd:${TAG}
	docker push ${ORG}/fluentd:${TAG}

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

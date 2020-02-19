DOCKER_IMAGE_NAME       ?= api-server
DOCKER_IMAGE_TAG        ?= $(subst /,-,$(shell git rev-parse --abbrev-ref HEAD))

all: format build test

requirements:
	@echo ">> generate requirements.txt"
	@rm -f requirements/requirements.txt
	pip-compile requirements/requirements.in -o requirements/requirements.txt

docker:
	@echo ">> building docker image"
	@DOCKER_BUILDKIT=1 docker build -t "$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG)" . -f deploy/Dockerfile

.PHONY: all requirements docker

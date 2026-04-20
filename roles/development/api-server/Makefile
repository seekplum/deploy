DOCKER_IMAGE_NAME       ?= api-server
DOCKER_IMAGE_TAG        ?= $(subst /,-,$(shell git rev-parse --abbrev-ref HEAD))

all: lint test

lint:
	@echo ">> linting code"
	uv run ruff check . --fix

format:
	@echo ">> formatting code"
	uv run ruff format

test:
	@echo ">> running tests"

docker:
	@echo ">> building docker image"
	@DOCKER_BUILDKIT=1 docker build -t "$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG)" . -f deploy/Dockerfile

.PHONY: all docker

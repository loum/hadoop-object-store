SERVICE_NAME = hadoop-object-store

include makester/makefiles/base.mk
include makester/makefiles/python-venv.mk

DOCKER := $(shell which docker 2>/dev/null)
COMPOSE_FILES = -f $(SERVICE_NAME)/docker-compose.yml

init: pip-requirements

local-build-config:
	@SERVICE_NAME=$(SERVICE_NAME) \
      HASH=$(HASH) \
      $(DOCKER_COMPOSE) --project-directory $(SERVICE_NAME) \
      $(COMPOSE_FILES) $(COMPOSE_FILES) \
      config

local-build-up: local-build-down
	@SERVICE_NAME=$(SERVICE_NAME) \
      HASH=$(HASH) \
      $(DOCKER_COMPOSE) --project-directory $(SERVICE_NAME) \
      $(COMPOSE_FILES) $(COMPOSE_FILES) \
      up -d

local-build-down:
	@SERVICE_NAME=$(SERVICE_NAME) \
      HASH=$(HASH) \
      $(DOCKER_COMPOSE) --project-directory $(SERVICE_NAME) \
      $(COMPOSE_FILES) $(COMPOSE_FILES) \
      down

MINIO_CONTAINER_NAME := minio
login-minio:
	@$(DOCKER) exec -ti $(MINIO_CONTAINER_NAME)

HADOOP_CONTAINER_NAME = hadoop-pseudo
login-hadoop:
	$(info $(DOCKER) exec -ti hadoop-pseudo su - hdfs)
	@$(DOCKER) exec -ti hadoop-pseudo su - hdfs

help: base-help python-venv-help
	@echo "(Makefile)\n\
  init                 Build the local virtual environment\n\
  local-build-up:      Create a local Kafka Connect pipeline that streams data to an S3-like store (MINIO)\n\
  local-build-down:    Destroy local Kafka Connect pipeline\n\
  local-build-config:  Local Kafka Connect pipeline docker-compose config\n\
  local-rmi:           Remove local Kafka Connect docker image\n\
  login-minio:         Login to container $(MINIO_CONTAINER_NAME)\n\
  login-hadoop:        Login to container $(HADOOP_CONTAINER_NAME) as user \"hdfs\"\n\
	";


.PHONY: help

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
	@$(DOCKER) exec -ti $(MINIO_CONTAINER_NAME) || true

HADOOP_CONTAINER_NAME = hadoop-pseudo
login-hadoop:
	@$(DOCKER) exec -ti $(HADOOP_CONTAINER_NAME) bash || true

conf-key:
	@$(DOCKER) exec $(HADOOP_CONTAINER_NAME) /opt/hadoop/bin/hdfs getconf -confKey $(CONF_KEY) 

hadoop-cmd:
	@$(DOCKER) exec $(HADOOP_CONTAINER_NAME) /opt/hadoop/bin/hadoop fs $(HADOOP_CMD)

help: base-help python-venv-help
	@echo "(Makefile)\n\
  init                 Build the local virtual environment\n\
  local-build-up:      Create local data lake over an S3-like store (MINIO)\n\
  local-build-down:    Destroy local data lake\n\
  local-build-config:  Local data lake\n\
  login-minio:         Login to container $(MINIO_CONTAINER_NAME)\n\
  login-hadoop:        Login to container $(HADOOP_CONTAINER_NAME) as user \"hdfs\"\n\
  conf-key:            Display configuration key defined by CONF_KEY\n\
                       - Example: make confkey CONF_KEY=fs.s3a.endpoint\n\
  hadoop-cmd:          Run hadoop CLI command defined by HADOOP_CMD\n\
                       - Example: make hadoop-cmd HADOOP_CMD="-ls s3a://hive"\n\
	";


.PHONY: help

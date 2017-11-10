# make configs taken from kubernetes
DBG_MAKEFILE ?=
ifeq ($(DBG_MAKEFILE),1)
	$(warning ***** starting Makefile for goal(s) "$(MAKECMDGOALS)")
	$(warning ***** $(shell date))
	$(warning ***** setting debug flags for containers)
	DEBUG = true
else
# If we're not debugging the Makefile, don't echo recipes.
		MAKEFLAGS += -s
		DEBUG = false
endif
# It's necessary to set this because some environments don't link sh -> bash.
SHELL := /bin/bash
# We don't need make's built-in rules.
MAKEFLAGS += --no-builtin-rules

# constants
ELF_NAME = kops-tools
ELF_VERSION ?= 0.0.2
BUILD_TIMEOUT = 1200 # seconds

CONTAINER_IMAGENAME = stefancocora/$(ELF_NAME)
CONTAINER_VERSION = v$(ELF_VERSION)
CONTAINER_NAME := $(ELF_NAME)
CONTAINER_NOCACHE := 'nocache'
container_iterateimage : CONTAINER_NOCACHE = 'withcache'
CI_TARGET_LOCAL := minikube_conc
CI_PIPELINES_PATH := ci
CI_MASTER_PIPELINE := master.yml
PIPELINENAME_MASTER := kops-tools

# define a catchall target
# default: build
default: help

help:
	@echo "---> Help menu:"
	@echo "supported make targets:"
	@echo ""
	@echo "Container build targets:"
	@echo "  make container_image			# builds a container image without caching"
	@echo "  make container_iterateimage		# builds a container image without caching"
	@echo ""
	@echo "CI targets:"
	@echo "  make set_pipeline_branch"
	@echo "  make set_pipeline_master"
	@echo ""

.PHONY: container_iterateimage
container_iterateimage:
	@echo "--> Building container image ..."
ifeq ($(DEBUG),true)
	$(info containerbuildaction: $(CONTAINER_BUILD_ACTION))
	$(info version: $(CONTAINER_VERSION))
	$(info nocache: $(CONTAINER_NOCACHE))
	$(info imagename: $(CONTAINER_IMAGENAME))
	$(info debug: $(DEBUG))
endif
	$(info com: 	timeout --preserve-status 120s sudo docker build -t "$(CONTAINER_IMAGENAME):$(strip $(CONTAINER_VERSION))" .)
	timeout --preserve-status $(BUILD_TIMEOUT) sudo docker build -t $(CONTAINER_IMAGENAME):$(strip $(CONTAINER_VERSION)) .

.PHONY: container_image
container_image:
	@echo "--> Building container image without caches..."
ifeq ($(DEBUG),true)
	$(info version: $(CONTAINER_BUILD_ACTION))
	$(info version: $(CONTAINER_VERSION))
	$(info nocache: $(CONTAINER_NOCACHE))
	$(info imagename: $(CONTAINER_IMAGENAME))
	$(info debug: $(DEBUG))
endif
# timeout --preserve-status 120s util/buildcontainer.sh $(CONTAINER_BUILD_ACTION) $(CONTAINER_VERSION) $(CONTAINER_NOCACHE) $(CONTAINER_IMAGENAME) $(DEBUG)
	$(info com: 	timeout --preserve-status 120s docker build --no-cache --force-rm -t "$(CONTAINER_IMAGENAME):$(CONTAINER_VERSION)" .)
	timeout --preserve-status $(BUILD_TIMEOUT) docker build --no-cache --force-rm -t $(CONTAINER_IMAGENAME):$(CONTAINER_VERSION) .

.PHONY: set_pipeline_master
set_pipeline_master:
ifeq ($(DEBUG),true)
	$(info elf appenvironment: $(ELF_APPENVIRONMENT))
	$(info elf version: $(ELF_VERSION))
	$(info debug: $(DEBUG))
endif
	@echo "---> Applying CI pipeline ..."
	fly -t $(CI_TARGET_LOCAL) set-pipeline -c $(CI_PIPELINES_PATH)/$(CI_MASTER_PIPELINE) -p $(PIPELINENAME_MASTER)
	fly -t $(CI_TARGET_LOCAL) expose-pipeline --pipeline $(PIPELINENAME_MASTER)

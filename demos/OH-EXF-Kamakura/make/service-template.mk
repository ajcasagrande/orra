# Guard to prevent it from being included more than once
ifndef SERVICE_TEMPLATE_MK_DEFINED
SERVICE_TEMPLATE_MK_DEFINED := 1

export SERVICE_NAME ?= $(current_folder_name)
export IMAGE_NAME ?= $(SERVICE_NAME)
export ENTRYPOINT ?= /$(IMAGE_NAME)
export SERVICE_URL ?= $(EDGE_OWNER).$(EDGE_DEPLOY).$(SERVICE_NAME)

export DOCKER_REGISTRY_BASE ?= $(DOCKER_REGISTRY:%=%/)

export VERSION_SUFFIX ?=
export SERVICE_VERSION ?= $(call version_of,$(SERVICE_NAME))
export DOCKER_IMAGE_VERSION ?= $(SERVICE_VERSION)$(VERSION_SUFFIX)

export DOCKER_ORG ?=
export DOCKER_ORG_BASE=$(DOCKER_ORG:%=%/)

# full docker image name including registry, organization, image name, and version
export DOCKER_FULL_IMAGE_NAME=${DOCKER_REGISTRY_BASE}${DOCKER_ORG_BASE}${IMAGE_NAME}:${DOCKER_IMAGE_VERSION}

BUILD_DIR = ../../build
SERVICE_JSON_INPUT = service.definition.json
SERVICE_JSON_OUTPUT = $(BUILD_DIR)/$(SERVICE_NAME).service.json

.PHONY: all publish-service deploy-policy print-service

all: publish-service deploy-policy

# Publish a Horizon service (per service.json) and pull image to get its sha256
publish-service: $(SERVICE_JSON_OUTPUT)
	hzn exchange service publish -O -f "$(SERVICE_JSON_OUTPUT)" --pull-image

# Print out service.json file substituting env variables
print-service: $(SERVICE_JSON_OUTPUT)
	envsubst < "$(SERVICE_JSON_OUTPUT)"

# Only add a deploy policy if one is specified in "service.policy.json"
deploy-policy:
ifneq ("$(wildcard service.policy.json)","")
	hzn exchange deployment addpolicy -f service.policy.json deploy_$(EDGE_OWNER).$(EDGE_DEPLOY).$(IMAGE_NAME)_$(ARCH)
endif

$(BUILD_DIR):
	mkdir -p "$@"

# remove comments from json files (any line starting with 0 or more spaces followed by //)
$(SERVICE_JSON_OUTPUT): $(SERVICE_JSON_INPUT) | $(BUILD_DIR)
	sed -E 's|^\s*//.*||g' "$(SERVICE_JSON_INPUT)" > "$@"

endif # SERVICE_TEMPLATE_MK_DEFINED

#!/usr/bin/env bash
#
# Copyright (C) 2022 Intel Corporation
#
# SPDX-License-Identifier: Apache-2.0
#

#
# Main entrypoint script for the container. Continuously polls the ESS API to check for new
# inference models and pipelines.
#


OBJECT_TYPE=
OBJECT_ID=
OBJECT_IDS=
OBJECT_DIR=
OBJECT_VERSION=

DEBUG=${DEBUG:-0}
DOWNLOAD_DIR="${DOWNLOAD_DIR:-/tmp}"
MODEL_DIR="${MODEL_DIR:-/models}"
PIPELINE_DIR="${PIPELINE_DIR:-/pipelines}"
MODEL_OBJECT_TYPE="${MODEL_OBJECT_TYPE:-${HZN_DEVICE_ID}.model}"
PIPELINE_OBJECT_TYPE="${PIPELINE_OBJECT_TYPE:-${HZN_DEVICE_ID}.pipeline}"
SLEEP_INTERVAL="${SLEEP_INTERVAL:-5}"

source ./utils.sh
source ./manage.sh
source ./ess_api.sh

# A simple Horizon sample edge service that shows how to use a Model Management System (MMS) file with your service.
# In this case we use a MMS file as a config file for this service that can be updated dynamically. The service has a default
# copy of the config file built into the docker image. Once the service starts up it periodically checks for a new version of
# the config file using the local MMS API (aka ESS) that the Horizon agent provides to services. If an updated config file is
# found, it is loaded into the service and the config parameters applied (in this case who to say hello to).

# Of course, MMS can also hold and deliver inference models, which can be used by services in a similar way.

# Repeatedly check to see if any updated models or pipelines were delivered via MMS/ESS
while true; do
    check_mms "${PIPELINE_OBJECT_TYPE}" "${PIPELINE_DIR}"
    check_mms "${MODEL_OBJECT_TYPE}" "${MODEL_DIR}"
    sleep $((SLEEP_INTERVAL))
done

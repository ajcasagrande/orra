#!/usr/bin/env bash
#
# Copyright (C) 2022 Intel Corporation
#
# SPDX-License-Identifier: Apache-2.0
#

#
# Utility functions for communicating with the ESS api for downloading models from MMS
#

# ${HZN_ESS_AUTH} is mounted to this container by the Horizon agent and is a json file with the credentials for authenticating to ESS.
# ESS (Edge Sync Service) is a proxy to MMS that runs in the Horizon agent.
USER=$(jq -r ".id" < "${HZN_ESS_AUTH}")
PASS=$(jq -r ".token" < "${HZN_ESS_AUTH}")

# Some curl parameters for using the ESS REST API
AUTH="-u ${USER}:${PASS}"
# ${HZN_ESS_CERT} is mounted to this container by the Horizon agent and the cert clients use to verify the identity of ESS.
CERT="--cacert ${HZN_ESS_CERT}"
SOCKET="--unix-socket ${HZN_ESS_API_ADDRESS}"
BASEURL='https://localhost/api/v1/objects'

# Usage: acknowledge <ack_type>
acknowledge() {
    log_debug "Acknowledge receipt of ${OBJECT_ID} for ${OBJECT_TYPE}"
    # shellcheck disable=SC2086 # we want to split AUTH, CERT and SOCKET arguments
    HTTP_CODE=$(curl -sSLw "%{http_code}" -X PUT ${AUTH} ${CERT} $SOCKET "$BASEURL/${OBJECT_TYPE}/${OBJECT_ID}/$1")
    if [[ "$HTTP_CODE" != '200' && "$HTTP_CODE" != '204' ]]; then
        log_error "HTTP code $HTTP_CODE from: curl -sSLw %{http_code} -X PUT ${AUTH} ${CERT} $SOCKET $BASEURL/${OBJECT_TYPE}/${OBJECT_ID}/$1"
    fi
}

# Usage: check_mms <object_type> <directory>
check_mms() {
    OBJECT_TYPE=$1
    OBJECT_DIR=$2

    local META_FILE="${DOWNLOAD_DIR}/${OBJECT_TYPE}.meta"

    log_debug "Checking for MMS updates for objects of type: ${OBJECT_TYPE}"
    # shellcheck disable=SC2086 # we want to split AUTH, CERT and SOCKET arguments
    HTTP_CODE=$(curl -sSLw "%{http_code}" -o "${META_FILE}" ${AUTH} ${CERT} ${SOCKET} "$BASEURL/${OBJECT_TYPE}")  # will only get changes that we haven't acknowledged (see below)
    if [[ "$HTTP_CODE" == '404' ]]; then
        log_debug "No updates for objects of type ${OBJECT_TYPE} found"
        return
    elif [[ "$HTTP_CODE" != '200' ]]; then
        log_error "HTTP code $HTTP_CODE from: curl -sSLw %{http_code} -o ${META_FILE} ${AUTH} ${CERT} $SOCKET $BASEURL/${OBJECT_TYPE}"
        return
    fi

    log_debug "MMS metadata=$(cat "${META_FILE}")"

    # todo: double check for loop code

    # "${META_FILE}" is a json array of all MMS files of OBJECT_TYPE that have been updated. Search for the ID we are interested in
    OBJECT_IDS=$(jq -r ".[] | .objectID" "${META_FILE}")  # if not found, jq returns 0 exit code, but blank value

    for OBJECT_ID in ${OBJECT_IDS}; do
        log_debug "Received new metadata for ${OBJECT_ID}"

        # Handle the case in which MMS is telling us the config file was deleted
        local DELETED
        DELETED=$(jq -r ".[] | select(.objectID == \"$OBJECT_ID\") | .deleted" "${META_FILE}")  # if not found, jq returns 0 exit code, but blank value
        OBJECT_VERSION=$(jq -r ".[] | select(.objectID == \"$OBJECT_ID\") | .version" "${META_FILE}")

        if [[ "$DELETED" == "true" ]]; then
            handle_delete
        else
            handle_update
        fi
    done
}

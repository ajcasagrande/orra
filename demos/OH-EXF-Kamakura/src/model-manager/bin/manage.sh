#!/usr/bin/env bash
#
# Copyright (C) 2022 Intel Corporation
#
# SPDX-License-Identifier: Apache-2.0
#

#
# Functions to handle the updates and deletions of models and pipelines
#


handle_delete() {
    log_notice "MMS file ${OBJECT_ID} of type ${OBJECT_TYPE} was deleted"

    log_debug "Deleting ${OBJECT_DIR}/${OBJECT_ID}"
    rm -rf "${OBJECT_DIR:?}/${OBJECT_ID:?}"
    log_debug "$(ls -lRh "${OBJECT_DIR}")"

    # Acknowledge that we saw that it was deleted, so it won't keep telling us
    acknowledge "deleted"
}

handle_update() {
    log_notice "Received new/updated ${OBJECT_ID} from MMS"

    if [[ "${OBJECT_TYPE}" == "${PIPELINE_OBJECT_TYPE}" ]]; then
        update_pipeline
    elif [[ "${OBJECT_TYPE}" == "${MODEL_OBJECT_TYPE}" ]]; then
        update_model
    else
        log_error "Received object of unknown type ${OBJECT_TYPE}!"
    fi
}

update_model() {
    local TEMP_FILE="${DOWNLOAD_DIR}/${OBJECT_ID}_${OBJECT_VERSION}"

    log_info "Downloading ${OBJECT_TYPE}/${OBJECT_ID} to ${TEMP_FILE}"
    # Read the new file from MMS
    # shellcheck disable=SC2086 # we want to split AUTH, CERT and SOCKET arguments
    HTTP_CODE=$(curl -sSLw "%{http_code}" -o "${TEMP_FILE}" ${AUTH} ${CERT} ${SOCKET} "${BASEURL}/${OBJECT_TYPE}/${OBJECT_ID}/data")
    if [[ "$HTTP_CODE" != '200' ]]; then
        log_error "HTTP code $HTTP_CODE from: curl -sSLw %{http_code} -o ${TEMP_FILE} ${AUTH} ${CERT} ${SOCKET} ${BASEURL}/${OBJECT_TYPE}/${OBJECT_ID}/data"
        return
    fi

    log_info "Finished downloading ${TEMP_FILE}"
    # todo: sha hash check!!!

    local OUTPUT_DIR="${MODEL_DIR}/${OBJECT_ID}/${OBJECT_VERSION}"
    log_info "Extracting ${TEMP_FILE} to ${OUTPUT_DIR}"
    mkdir -p "${OUTPUT_DIR}"
    tar -C "${OUTPUT_DIR}" -xvf "${TEMP_FILE}"

    log_debug "$(ls -lRh "${OUTPUT_DIR}")"

    # Acknowledge that we got the new file, so it won't keep telling us
    acknowledge "received"
}

update_pipeline() {
    local TEMP_FILE="${DOWNLOAD_DIR}/${OBJECT_ID}_${OBJECT_VERSION}"
    mkdir -p "${OBJECT_DIR}/${OBJECT_ID}/${OBJECT_VERSION}"
    local OUTPUT_FILE="${OBJECT_DIR}/${OBJECT_ID}/${OBJECT_VERSION}/pipeline.json"

    log_info "Downloading ${OBJECT_TYPE}/${OBJECT_ID} to ${TEMP_FILE}"
    # Read the new file from MMS
    # shellcheck disable=SC2086 # we want to split AUTH, CERT and SOCKET arguments
    HTTP_CODE=$(curl -sSLw "%{http_code}" -o "${TEMP_FILE}" ${AUTH} ${CERT} ${SOCKET} "${BASEURL}/${OBJECT_TYPE}/${OBJECT_ID}/data")
    if [[ "$HTTP_CODE" != '200' ]]; then
        log_error "HTTP code $HTTP_CODE from: curl -sSLw %{http_code} -o ${TEMP_FILE} ${AUTH} ${CERT} ${SOCKET} ${BASEURL}/${OBJECT_TYPE}/${OBJECT_ID}/data"
        return
    fi

    log_info "Finished downloading ${TEMP_FILE}"
    # todo: sha hash check!!!

    log_info "Moving ${TEMP_FILE} to ${OUTPUT_FILE}"
    mv -f "${TEMP_FILE}" "${OUTPUT_FILE}"
    log_debug "$(ls -lh "${OUTPUT_FILE}")"
    log_debug "$(ls -lRh "${OBJECT_DIR}")"

    # Acknowledge that we got the new file, so it won't keep telling us
    acknowledge "received"
}

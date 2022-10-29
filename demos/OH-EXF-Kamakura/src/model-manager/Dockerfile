# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0

FROM alpine:latest

RUN apk --no-cache --update add jq curl bash

COPY bin/*.sh /

WORKDIR /

ENTRYPOINT ["/entrypoint.sh"]

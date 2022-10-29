#!/usr/bin/env bash
#
# Copyright (C) 2022 Intel Corporation
#
# SPDX-License-Identifier: Apache-2.0
#

#
# Common utility functions for use in other scripts
#

DATE_FORMAT="${DATE_FORMAT:-}"

# ANSI colors
red="\033[31m"
green="\033[32m"
yellow="\033[33m"
blue="\033[34m"
lt_cyan="\033[96m"
clear="\033[0m"
bold="\033[1m"
dim="\033[2m"
normal="\e[22;24m"

# Function outputs date in specified format for logging purposes
pretty_date() {
    if [ -n "${DATE_FORMAT}" ]; then
        date "$DATE_FORMAT"
    else
        date +%X
    fi
}

log_internal() {
    echo -e "${dim}[$(pretty_date)]${normal} ${1:-}${clear}"
}

# Function takes debug message as argument
log_debug() {
    if [ "$DEBUG" -eq 1 ]; then
        log_internal "${dim}${bold}  [DEBUG]${clear}${dim} ${1:-}"
    fi
}

# Function takes info message as argument
log_info() {
    log_internal "${blue}${bold}   [INFO]${clear} ${1:-}"
}

# Function takes warning message as argument
log_warn() {
    log_internal "${yellow}${bold}[WARNING]${clear} ${1:-}"
}

# Function takes notice message as argument
log_notice() {
    log_internal "${lt_cyan}${bold} [NOTICE]${clear} ${1:-}"
}

# Function takes error message as argument
log_error() {
    log_internal "${red}${bold}  [ERROR]${clear} ${1:-}"
}

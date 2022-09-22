#!/bin/bash

ENV_FILE="/.env"
CRON_CONFIG_FILE="${HOME}/crontabs"

function color() {
    case $1 in
        red)     echo -e "\033[31m$2\033[0m" ;;
        green)   echo -e "\033[32m$2\033[0m" ;;
        yellow)  echo -e "\033[33m$2\033[0m" ;;
        blue)    echo -e "\033[34m$2\033[0m" ;;
        none)    echo "$2" ;;
    esac
}

function export_env_file() {
    if [[ -f "${ENV_FILE}" ]]; then
        color blue "find \"${ENV_FILE}\" file and export variables"
        set -a
        source <(cat "${ENV_FILE}" | sed -e '/^#/d;/^\s*$/d' -e 's/\(\w*\)[ \t]*=[ \t]*\(.*\)/DOTENV_\1=\2/')
        set +a
    fi
}

function get_env() {
    local VAR="$1"
    local VAR_FILE="${VAR}_FILE"
    local VAR_DOTENV="DOTENV_${VAR}"
    local VAR_DOTENV_FILE="DOTENV_${VAR_FILE}"
    local VALUE=""

    if [[ -n "${!VAR:-}" ]]; then
        VALUE="${!VAR}"
    elif [[ -n "${!VAR_FILE:-}" ]]; then
        VALUE="$(cat "${!VAR_FILE}")"
    elif [[ -n "${!VAR_DOTENV_FILE:-}" ]]; then
        VALUE="$(cat "${!VAR_DOTENV_FILE}")"
    elif [[ -n "${!VAR_DOTENV:-}" ]]; then
        VALUE="${!VAR_DOTENV}"
    fi

    export "${VAR}=${VALUE}"
}

function init_env() {
    # export
    export_env_file

    init_env_mail

    # CRON
    get_env CRON
    CRON="${CRON:-"0 12 * * *"}"

    # PING_URL
    get_env PING_URL
    PING_URL="${PING_URL:-""}"

    # TIMEZONE
    get_env TIMEZONE
    local TIMEZONE_MATCHED_COUNT=$(ls "/usr/share/zoneinfo/${TIMEZONE}" 2> /dev/null | wc -l)
    if [[ "${TIMEZONE_MATCHED_COUNT}" -ne 1 ]]; then
        TIMEZONE="UTC"
    fi

    color yellow "========================================"
    color yellow "TIMEZONE: ${TIMEZONE}"
    color yellow "CRON: ${CRON}"

    if [[ -n "${PING_URL}" ]]; then
        color yellow "PING_URL: ${PING_URL}"
    fi
    color yellow "MAIL_FROM: ${MAIL_SMTP_FROM}"
    color yellow "MAIL_TO: ${MAIL_TO}"
    color yellow "========================================"
}

function init_env_mail() {
    get_env MAIL_SMTP_FROM
    get_env MAIL_TO
    get_env MAIL_SMTP_HOST
    get_env MAIL_SMTP_PORT
    get_env MAIL_SMTP_SECURITY
    get_env MAIL_SMTP_AUTH_MECHANISM
    get_env MAIL_SMTP_USERNAME
    get_env MAIL_SMTP_PASSWORD
}

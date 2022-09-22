#!/bin/bash

. /app/includes.sh

function configure_cron() {
    local FIND_CRON_COUNT="$(grep -c 'main.rb' "${CRON_CONFIG_FILE}" 2> /dev/null)"
    if [[ "${FIND_CRON_COUNT}" -eq 0 ]]; then
        echo "${CRON} /app/ldm.rb" >> "${CRON_CONFIG_FILE}"
    fi
}

function configure_timezone() {
    ln -sf "/usr/share/zoneinfo/${TIMEZONE}" "${LOCALTIME_FILE}"
}

init_env
configure_timezone
configure_cron

# foreground run crond
supercronic -passthrough-logs -quiet "${CRON_CONFIG_FILE}"

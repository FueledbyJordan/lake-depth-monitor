#!/bin/bash

. /app/includes.sh

# mailx test
if [[ "$1" == "mail" ]]; then
    export_env_file
    init_env_mail

    MAIL_SMTP_ENABLE="TRUE"
    MAIL_DEBUG="TRUE"

    if [[ -n "$2" ]]; then
        MAIL_TO="$2"
    fi

    send_mail "lake depth monitor test" "SMTP looks configured correctly."

    exit 0
fi

function configure_cron() {
    local FIND_CRON_COUNT="$(grep -c 'main.rb' "${CRON_CONFIG_FILE}" 2> /dev/null)"
    if [[ "${FIND_CRON_COUNT}" -eq 0 ]]; then
        echo "${CRON} /app/main.rb" >> "${CRON_CONFIG_FILE}"
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

#!/usr/bin/env bash

set -euo pipefail

readonly LOG_FILE="$HOME/server-automation/logs/service-health.log"
readonly -a DEFAULT_SERVICES=("nginx" "ssh" "fail2ban")

log() {
    local level="$1"
    local message="$2"

    printf '%s [%s] %s\n' \
        "$(date '+%F %T')" "$level" "$message" |
        tee -a "$LOG_FILE"
}

main() {
    local -a services

    if (($# > 0)); then
        services=("$@")
    else
        services=("${DEFAULT_SERVICES[@]}")
    fi

    local failed=0
    local service

    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service"; then
            log "OK" "$service is active."
        else
            log "ERROR" "$service is not active."
            failed=1
        fi
    done

    if ((failed != 0)); then
        exit 1
    fi

    exit 0
}

main "$@"

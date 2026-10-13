#!/usr/bin/env bash

set -euo pipefail

readonly THRESHOLD="${1:-80}"
readonly MOUNT_POINT="/"
readonly LOG_FILE="$HOME/server-automation/logs/disk-monitor.log"

log() {
    local level="$1"
    local message="$2"

    printf '%s [%s] %s\n' \
        "$(date '+%F %T')" "$level" "$message" |
        tee -a "$LOG_FILE"
}

main() {
    if ! [[ "$THRESHOLD" =~ ^[0-9]+$ ]] ||
        ((THRESHOLD < 1 || THRESHOLD > 100)); then
        log "ERROR" "Threshold must be a number between 1 and 100."
        exit 2
    fi

    local usage
    usage=$(df -P "$MOUNT_POINT" |
        awk 'NR == 2 {gsub(/%/, "", $5); print $5}')

    if ((usage >= THRESHOLD)); then
        log "WARNING" \
            "$MOUNT_POINT usage is ${usage}% (threshold: ${THRESHOLD}%)."
        exit 1
    fi

    log "OK" \
        "$MOUNT_POINT usage is ${usage}% (threshold: ${THRESHOLD}%)."
    exit 0
}

main "$@"

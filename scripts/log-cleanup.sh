#!/usr/bin/env bash

set -euo pipefail

readonly LOG_DIR="$HOME/server-automation/logs"
readonly MODE="${1:---dry-run}"
readonly RETENTION_DAYS="${2:-7}"

log() {
    local level="$1"
    local message="$2"

    printf '%s [%s] %s\n' \
        "$(date '+%F %T')" "$level" "$message"

    logger -t log-cleanup "[$level] $message"
}

main() {
    if [[ "$MODE" != "--dry-run" && "$MODE" != "--delete" ]]; then
        log "ERROR" "Usage: $0 [--dry-run|--delete] [retention-days]"
        exit 2
    fi

    if ! [[ "$RETENTION_DAYS" =~ ^[0-9]+$ ]] ||
        ((RETENTION_DAYS < 1 || RETENTION_DAYS > 365)); then
        log "ERROR" "Retention days must be between 1 and 365."
        exit 2
    fi

    if [[ "$LOG_DIR" != "$HOME/server-automation/logs" ||
          ! -d "$LOG_DIR" ]]; then
        log "ERROR" "Unsafe or missing log directory: $LOG_DIR"
        exit 1
    fi

    local -a files=()

    mapfile -d '' -t files < <(
        find "$LOG_DIR" \
            -maxdepth 1 \
            -type f \
            -name '*.log' \
            -mtime +"$RETENTION_DAYS" \
            -print0
    )

    if ((${#files[@]} == 0)); then
        log "OK" "No log files older than $RETENTION_DAYS days."
        exit 0
    fi

    local file

    if [[ "$MODE" == "--dry-run" ]]; then
        for file in "${files[@]}"; do
            printf 'WOULD DELETE: %s\n' "$file"
        done

        log "INFO" "${#files[@]} old log file(s) found; nothing deleted."
        exit 0
    fi

    for file in "${files[@]}"; do
        rm -- "$file"
        log "DELETED" "$file"
    done

    log "OK" "${#files[@]} old log file(s) deleted."
    exit 0
}

main "$@"

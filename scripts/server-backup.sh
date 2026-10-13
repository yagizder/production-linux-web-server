#!/usr/bin/env bash

set -euo pipefail

readonly BACKUP_DIR="/var/backups/devops-lab"
readonly TIMESTAMP="$(date '+%F_%H-%M-%S')"
readonly ARCHIVE="$BACKUP_DIR/server-backup_$TIMESTAMP.tar.gz"

readonly -a SOURCES=(
    "/etc/nginx"
    "/etc/ssh/sshd_config"
    "/etc/ssh/sshd_config.d"
    "/var/www/devops-lab"
)

log() {
    local level="$1"
    local message="$2"

    printf '%s [%s] %s\n' \
        "$(date '+%F %T')" "$level" "$message"

    logger -t server-backup "[$level] $message"
}

main() {
    if ((EUID != 0)); then
        printf 'ERROR: This script must be run with sudo.\n' >&2
        exit 2
    fi

    local source

    for source in "${SOURCES[@]}"; do
        if [[ ! -e "$source" ]]; then
            log "ERROR" "Source does not exist: $source"
            exit 1
        fi
    done

    install -d -m 700 "$BACKUP_DIR"

    if ! tar -czf "$ARCHIVE" "${SOURCES[@]}"; then
        log "ERROR" "Backup archive could not be created."
        exit 1
    fi

    if ! tar -tzf "$ARCHIVE" >/dev/null; then
        log "ERROR" "Backup archive failed verification."
        exit 1
    fi

    log "OK" "Backup created and verified: $ARCHIVE"
    exit 0
}

main "$@"

#!/usr/bin/env bash

set -euo pipefail

readonly LOG_DIR="$HOME/server-automation/logs"
readonly LOG_FILE="$LOG_DIR/system-info.log"

section() {
    printf '\n=== %s ===\n' "$1"
}

main() {
    mkdir -p "$LOG_DIR"

    {
        printf 'Generated at: %s\n' "$(date '+%F %T')"
        printf 'Host: %s\n' "$(hostname)"
        printf 'User: %s\n' "$(whoami)"

        section "Uptime"
        uptime -p

        section "Memory"
        free -h

        section "Root filesystem"
        df -h /

        section "IP addresses"
        ip -brief address show scope global
    } | tee -a "$LOG_FILE"
}

main "$@"

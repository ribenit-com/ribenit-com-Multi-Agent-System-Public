#!/bin/bash

LOG_LEVEL="${LOG_LEVEL:-INFO}"

_timestamp() {
    date +"%Y-%m-%d %H:%M:%S"
}

_log() {
    local level="$1"
    local color="$2"
    shift 2
    echo -e "$( _timestamp ) ${color}[$level]\033[0m $*"
}

log_info()  { _log "INFO"  "\033[36m" "$@"; }
log_warn()  { _log "WARN"  "\033[33m" "$@"; }
log_error() { _log "ERROR" "\033[31m" "$@"; }
log_debug() { [[ "$LOG_LEVEL" == "DEBUG" ]] && _log "DEBUG" "\033[90m" "$@"; }

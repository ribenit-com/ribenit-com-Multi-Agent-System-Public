#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/logger.sh"
source "$(dirname "$0")/error_codes.sh"

git_safe() {
    if ! "$@"; then
        log_error "Git 命令失败: $*"
        return $E_GIT_ERROR
    fi
}

git_add_all() { git_safe git add .; }

git_commit() {
    local msg="$1"
    git commit -m "$msg" || true
}

git_push() {
    local branch="$1"
    git_safe git push origin "$branch" || return $E_PUSH_FAIL
}

git_set_remote() {
    local user="$1"
    local repo="$2"
    git_safe git remote set-url origin "https://${user}@${repo#https://}"
}

git_ls_remote() {
    local repo="$1"
    git ls-remote "$repo" &>/dev/null
}

#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/logger.sh"
source "$(dirname "$0")/error_codes.sh"
source "$(dirname "$0")/git_exec.sh"

detect_os_helper() {
    case "$(uname)" in
        Darwin) echo "osxkeychain" ;;
        Linux)  echo "cache --timeout=3600" ;;
        *)      echo "store" ;;
    esac
}

upload_to_github() {

    local dir="$1"
    local msg="$2"
    local user="$3"
    local pat="$4"
    local repo="$5"
    local branch="${6:-main}"

    log_info "进入目录: $dir"
    cd "$dir"

    helper=$(detect_os_helper)
    git config credential.helper "$helper"

    git_set_remote "$user" "$repo"

    printf "protocol=https\nhost=github.com\nusername=%s\npassword=%s\n\n" "$user" "$pat" | git credential approve

    if git_ls_remote "$repo"; then
        log_info "认证成功"
    else
        log_error "认证失败"
        return $E_AUTH_FAIL
    fi

    git_add_all
    git_commit "$msg"
    git_push "$branch"

    log_info "上传完成"
    return $E_OK
}

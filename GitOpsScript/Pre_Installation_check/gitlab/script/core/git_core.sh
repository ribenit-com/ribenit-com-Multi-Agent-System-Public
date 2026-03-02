#!/bin/bash
# ==========================================
# git_core.sh - Git 上传核心函数（增强版）
# 自动读取 ~/git_constants.sh
# 支持回滚机制 + 默认 commit message
# ==========================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 加载日志模块和错误码
source "$SCRIPT_DIR/logger.sh"
source "$SCRIPT_DIR/error_codes.sh"
source "$SCRIPT_DIR/git_exec.sh"

# 自动识别操作系统
detect_os_helper() {
    case "$(uname)" in
        Darwin) echo "osxkeychain" ;;
        Linux)  echo "cache --timeout=3600" ;;
        *)      echo "store" ;;
    esac
}

# 上传函数
upload_to_github() {
    local dir="$1"                             # 本地目录
    local msg="${2:-自动提交 $(date)}"         # 提交信息

    local user="$3"                            # GitHub 用户名
    local pat="$4"                             # GitHub PAT
    local repo="$5"                            # 仓库 URL
    local branch="${6:-main}"                  # 分支默认 main

    log_info "进入目录: $dir"
    cd "$dir" || { log_error "目录不存在: $dir"; return 1; }

    # 配置 credential helper
    helper=$(detect_os_helper)
    git config credential.helper "$helper"

    # 设置远程仓库
    git_set_remote "$user" "$repo"

    # 注入 PAT
    printf "protocol=https\nhost=github.com\nusername=%s\npassword=%s\n\n" \
           "$user" "$pat" | git credential approve

    # 测试远程仓库
    if git_ls_remote "$repo"; then
        log_info "认证成功"
    else
        log_error "认证失败"
        return $E_AUTH_FAIL
    fi

    # 回滚机制
    log_info "创建临时 stash 备份（如果有未提交更改）"
    git stash push -m "pre-upload backup" || log_info "没有需要 stash 的更改"

    # 执行 Git 操作
    set +e
    git_add_all
    git_commit "$msg"
    git_push "$branch"
    status=$?
    set -e

    if [ $status -ne 0 ]; then
        log_error "上传失败，开始回滚"
        git reset --hard HEAD~1
        git stash pop || log_warn "没有 stash 可恢复"
        return $E_PUSH_FAIL
    fi

    log_info "上传完成"
    return $E_OK
}

#!/bin/bash
# ==========================================
# git_core.sh - Git 上传核心函数（增强版）
# 自动读取 ~/git_constants.sh
# 支持回滚机制 + 默认 commit message
# ==========================================

set -euo pipefail

# -----------------------------
# 获取当前脚本目录
# -----------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# -----------------------------
# 加载日志模块和错误码
# -----------------------------
source "$SCRIPT_DIR/logger.sh"
source "$SCRIPT_DIR/error_codes.sh"

# -----------------------------
# 工具函数：检测操作系统，返回 Git credential helper
# -----------------------------
detect_os_helper() {
    case "$(uname)" in
        Darwin) echo "osxkeychain" ;;
        Linux)  echo "cache --timeout=3600" ;;
        *)      echo "store" ;;
    esac
}

# -----------------------------
# upload_to_github 函数
# -----------------------------
upload_to_github() {
    # -----------------------------
    # 参数
    # -----------------------------
    local dir="$1"                             # 本地目录
    local msg="${2:-自动提交 $(date)}"         # 提交信息，默认值

    # -----------------------------
    # 从 ~/git_constants.sh 读取 GitHub 配置
    # -----------------------------
    if [ ! -f "${HOME}/git_constants.sh" ]; then
        log_error "未找到 git_constants.sh，请先创建 ~/git_constants.sh"
        return 1
    fi
    source "${HOME}/git_constants.sh"

    # 确认必须变量存在
    : "${GITLAB_USER:?请在 git_constants.sh 设置 GITLAB_USER}"
    : "${GITLAB_PAT:?请在 git_constants.sh 设置 GITLAB_PAT}"
    : "${REPO_URL:?请在 git_constants.sh 设置 REPO_URL}"
    BRANCH="${BRANCH:-main}"  # 分支默认 main

    # -----------------------------
    # 进入目录
    # -----------------------------
    log_info "进入目录: $dir"
    cd "$dir" || { log_error "目录不存在: $dir"; return 1; }

    # -----------------------------
    # 配置 credential helper
    # -----------------------------
    helper=$(detect_os_helper)
    git config credential.helper "$helper"

    # -----------------------------
    # 设置远程仓库地址
    # -----------------------------
    git_set_remote "$GITLAB_USER" "$REPO_URL"

    # -----------------------------
    # 注入 GitHub PAT 到凭证缓存
    # -----------------------------
    printf "protocol=https\nhost=github.com\nusername=%s\npassword=%s\n\n" \
           "$GITLAB_USER" "$GITLAB_PAT" | git credential approve

    # -----------------------------
    # 测试远程仓库连接
    # -----------------------------
    if git_ls_remote "$REPO_URL"; then
        log_info "认证成功"
    else
        log_error "认证失败"
        return $E_AUTH_FAIL
    fi

    # -----------------------------
    # 回滚机制：stash 未提交更改
    # -----------------------------
    log_info "创建临时 stash 备份（如果有未提交更改）"
    git stash push -m "pre-upload backup" || log_info "没有需要 stash 的更改"

    # -----------------------------
    # 执行 Git 操作
    # -----------------------------
    set +e                         # 关闭严格模式
    git_add_all                     # git add .
    git_commit "$msg"               # git commit -m "<msg>"
    git_push "$BRANCH"              # git push
    status=$?                       # 捕获 push 状态
    set -e                          # 恢复严格模式

    # -----------------------------
    # push 失败回滚
    # -----------------------------
    if [ $status -ne 0 ]; then
        log_error "上传失败，开始回滚"
        git reset --hard HEAD~1
        git stash pop || log_warn "没有 stash 可恢复"
        return $E_PUSH_FAIL
    fi

    log_info "上传完成"
    return $E_OK
}

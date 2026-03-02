#!/bin/bash
# ==========================================
# git_core.sh - Git 上传核心函数（增强版）
# 自动读取 ~/git_constants.sh
# 支持回滚机制 + 默认 commit message
# 修复首次 push main 分支与干净工作区问题
# ==========================================

set -euo pipefail  # 开启严格模式：-e 出错停止，-u 未定义变量报错，-o pipefail 管道失败报错

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
    local dir="$1"                             # 本地目录
    local msg="${2:-自动提交 $(date)}"         # 提交信息

    # -----------------------------
    # 从 ~/git_constants.sh 读取 GitHub 配置
    # -----------------------------
    if [ ! -f "${HOME}/git_constants.sh" ]; then
        log_error "未找到 git_constants.sh，请先创建 ~/git_constants.sh"
        return 1
    fi
    source "${HOME}/git_constants.sh"

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
    # 确保本地分支为 main
    # -----------------------------
    git branch -m main 2>/dev/null || true  # 如果已经是 main，忽略错误

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
    # 判断是否有变更需要 commit
    # -----------------------------
    push_required=false
    if ! git diff --cached --quiet; then        # 如果有 staged 改动
        git_add_all                             # 添加修改
        git_commit "$msg"                        # 提交
        push_required=true
    else
        log_info "没有需要提交的更改"
    fi

    # -----------------------------
    # 执行 push（首次 push 设置 upstream）
    # -----------------------------
    status=0
    if [ "$push_required" = true ]; then
        git_push -u origin "$BRANCH"
        status=$?
    fi

    # -----------------------------
    # push 失败回滚（仅在有 commit 时）
    # -----------------------------
    if [ $status -ne 0 ] && [ "$push_required" = true ]; then
        log_error "上传失败，开始回滚"
        git reset --hard HEAD~1                  # 回退 commit
        git stash pop || log_warn "没有 stash 可恢复"
        return $E_PUSH_FAIL
    fi

    log_info "上传完成"
    return $E_OK
}

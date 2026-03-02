#!/bin/bash
# ==========================================
# git_core.sh - Git 上传核心函数（增强版）
# 自动读取 ~/git_constants.sh
# 支持回滚机制 + 默认 commit message
# 支持首次 push main 分支，并改为 URL 注入用户名+PAT 方式
# 完整安全版，增加详细调试打印
# ==========================================

set -euo pipefail  # 开启严格模式：-e 出错停止，-u 未定义变量报错，-o pipefail 管道失败报错

# -----------------------------
# 获取当前脚本目录
# -----------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"   # 获取当前脚本所在目录绝对路径
echo "[DEBUG] SCRIPT_DIR=$SCRIPT_DIR"

# -----------------------------
# 加载日志模块和错误码
# -----------------------------
source "$SCRIPT_DIR/logger.sh"        # 加载日志工具
source "$SCRIPT_DIR/error_codes.sh"   # 加载错误码定义
source "$SCRIPT_DIR/git_exec.sh"      # 提供 git_set_remote、git_add_all、git_commit 等函数

# -----------------------------
# 工具函数：检测操作系统，返回 Git credential helper
# -----------------------------
detect_os_helper() {
    case "$(uname)" in
        Darwin) echo "osxkeychain" ;;          # macOS 使用 osxkeychain
        Linux)  echo "cache --timeout=3600" ;; # Linux 使用缓存 1 小时
        *)      echo "store" ;;                 # 其他系统使用 store
    esac
}

# -----------------------------
# upload_to_github 函数
# -----------------------------
upload_to_github() {
    local dir="$1"                             # 本地目录
    local msg="${2:-自动提交 $(date)}"         # 提交信息，默认值防止空

    echo "[DEBUG] 目标目录 dir=$dir"

    # -----------------------------
    # 从 ~/git_constants.sh 读取 GitHub 配置
    # -----------------------------
    if [ ! -f "${HOME}/git_constants.sh" ]; then
        log_error "未找到 git_constants.sh，请先创建 ~/git_constants.sh"
        return 1
    fi

    echo "[DEBUG] 加载 ${HOME}/git_constants.sh"
    source "${HOME}/git_constants.sh"

    # -----------------------------
    # 打印调试信息
    # -----------------------------
    echo "[DEBUG] GITLAB_USER=$GITLAB_USER"
    echo "[DEBUG] GITLAB_PAT=${GITLAB_PAT:0:4}****"  # 只打印前4位
    echo "[DEBUG] REPO_URL=$REPO_URL"
    echo "[DEBUG] BRANCH=${BRANCH:-main}"

    : "${GITLAB_USER:?请在 git_constants.sh 设置 GITLAB_USER}"   # 必须变量检查
    : "${GITLAB_PAT:?请在 git_constants.sh 设置 GITLAB_PAT}"
    : "${REPO_URL:?请在 git_constants.sh 设置 REPO_URL}"
    BRANCH="${BRANCH:-main}"                  # 分支默认 main

    # -----------------------------
    # 进入目录
    # -----------------------------
    log_info "进入目录: $dir"
    cd "$dir" || { log_error "目录不存在: $dir"; return 1; }

    # -----------------------------
    # 确保本地分支为 main
    # -----------------------------
    git branch -m main 2>/dev/null || true   # 如果已经是 main，忽略错误
    echo "[DEBUG] 当前分支:"
    git branch

    # -----------------------------
    # 设置远程仓库地址（使用 USERNAME+PAT 注入 URL）
    # -----------------------------
    REPO_WITH_PAT="https://${GITLAB_USER}:${GITLAB_PAT}@$(echo "$REPO_URL" | sed 's#^https://##;s#/$##')"
    git_set_remote "$GITLAB_USER" "$REPO_WITH_PAT"
    echo "[DEBUG] origin URL:"
    git remote -v

    # -----------------------------
    # 打印最终 push URL 便于调试
    # -----------------------------
    log_info "调试：最终远程仓库 URL = $REPO_WITH_PAT"
    echo "调试：最终远程仓库 URL = $REPO_WITH_PAT"

    # -----------------------------
    # 测试远程仓库连接
    # -----------------------------
    echo "[DEBUG] 测试远程仓库连接..."
    git_ls_remote "$REPO_WITH_PAT" || { log_error "认证失败，请检查 GITLAB_USER、GITLAB_PAT 或 URL 是否正确"; return $E_AUTH_FAIL; }
    log_info "认证成功"

    # -----------------------------
    # 回滚机制：stash 未提交更改
    # -----------------------------
    log_info "创建临时 stash 备份（如果有未提交更改）"
    git stash push -m "pre-upload backup" || log_info "没有需要 stash 的更改"

    # -----------------------------
    # 执行 Git 操作
    # -----------------------------
    set +e
    git_add_all
    git_commit "$msg"

    # -----------------------------
    # 首次 push 指定 upstream
    # -----------------------------
    echo "[DEBUG] 执行 push 到远程分支 $BRANCH"
    git push -u origin "$BRANCH"
    status=$?
    set -e

    # -----------------------------
    # push 失败回滚
    # -----------------------------
    if [ $status -ne 0 ]; then
        log_error "上传失败，开始回滚"
        if git rev-parse HEAD >/dev/null 2>&1; then
            git reset --hard HEAD~1
        fi
        git stash pop || log_warn "没有 stash 可恢复"
        return $E_PUSH_FAIL
    fi

    log_info "上传完成"
    return $E_OK
}

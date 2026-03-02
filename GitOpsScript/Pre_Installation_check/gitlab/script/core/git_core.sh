#!/bin/bash
# ==========================================
# git_core.sh - Git 上传核心函数（增强版）
# 版本: v1.4
# 修改日期: 2026-03-02 16:50
# 作者: ribenit-com
# 说明:
#   - 自动读取 git_constants.sh，可通过 GIT_CONST_PATH 覆盖默认路径
#   - 支持回滚机制 + 默认 commit message
#   - 支持首次 push main 分支，并改为 URL 注入用户名+PAT 方式
#   - 完整安全版，增加详细调试打印与 PAT URL encode
#   - 输出 Bash 版本用于调试
#   - 打印 git_constants.sh 读取值，PAT 明文显示
# ==========================================

set -euo pipefail  # 开启严格模式

# -----------------------------
# 输出版本信息
# -----------------------------
echo "[DEBUG] git_core.sh v1.4, last modified 2026-03-02 16:50"
echo "[DEBUG] Bash version: $BASH_VERSION"

# -----------------------------
# 获取当前脚本目录
# -----------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "[DEBUG] SCRIPT_DIR=$SCRIPT_DIR"

# -----------------------------
# 加载日志模块和错误码
# -----------------------------
source "$SCRIPT_DIR/logger.sh"
source "$SCRIPT_DIR/error_codes.sh"
source "$SCRIPT_DIR/git_exec.sh"

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
# URL encode PAT（简单处理 @ -> %40, : -> %3A, / -> %2F）
# -----------------------------
url_encode() {
    local str="$1"
    str="${str//@/%40}"
    str="${str//:/%3A}"
    str="${str//\//%2F}"
    echo "$str"
}

# -----------------------------
# upload_to_github 函数
# -----------------------------
upload_to_github() {
    local dir="$1"
    local msg="${2:-自动提交 $(date)}"

    echo "[DEBUG] 目标目录 dir=$dir"

    # -----------------------------
    # 加载 git_constants.sh
    # 支持外部环境变量 GIT_CONST_PATH，默认 ~/git_constants.sh
    # -----------------------------
    GIT_CONST_PATH="${GIT_CONST_PATH:-$HOME/git_constants.sh}"
    if [ ! -f "$GIT_CONST_PATH" ]; then
        log_error "未找到 $GIT_CONST_PATH，请先创建"
        return 1
    fi
    echo "[DEBUG] 加载 $GIT_CONST_PATH"
    source "$GIT_CONST_PATH"

    # -----------------------------
    # 打印实际读取的值（PAT 明文显示）
    # -----------------------------
    echo "【GITLAB_USER：$GITLAB_USER】"
    echo "【GITLAB_PAT：$GITLAB_PAT】"
    echo "【REPO_URL：$REPO_URL】"
    echo "【BRANCH：${BRANCH:-main}】"

    : "${GITLAB_USER:?请在 git_constants.sh 设置 GITLAB_USER}"
    : "${GITLAB_PAT:?请在 git_constants.sh 设置 GITLAB_PAT}"
    : "${REPO_URL:?请在 git_constants.sh 设置 REPO_URL}"
    BRANCH="${BRANCH:-main}"

    # -----------------------------
    # 进入目录
    # -----------------------------
    log_info "进入目录: $dir"
    cd "$dir" || { log_error "目录不存在: $dir"; return 1; }

    # -----------------------------
    # 确保本地分支为 main
    # -----------------------------
    git branch -m main 2>/dev/null || true
    echo "[DEBUG] 当前分支:"
    git branch

    # -----------------------------
    # URL encode PAT 并拼接远程仓库 URL
    # -----------------------------
    GITLAB_PAT_ENCODED="$(url_encode "$GITLAB_PAT")"
    REPO_WITH_PAT="https://${GITLAB_USER}:${GITLAB_PAT_ENCODED}@$(echo "$REPO_URL" | sed 's#^https://##;s#/$##')"

    git_set_remote "$GITLAB_USER" "$REPO_WITH_PAT"

    echo "[DEBUG] origin URL:"
    git remote -v

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

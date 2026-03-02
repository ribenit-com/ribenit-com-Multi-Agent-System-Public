#!/bin/bash
# ==========================================
# git_cli.sh - Git 上传入口
# ==========================================

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"  # 项目根目录
source "$BASE_DIR/core/git_core.sh"          # 核心上传逻辑

if [ $# -lt 1 ]; then
    echo "用法: ./git_cli.sh <目录> [commit]"
    exit 30
fi

TARGET="$1"                                  # 目录参数
COMMIT="${2:-自动提交 $(date)}"              # commit 信息

echo "[DEBUG] TARGET=$TARGET"
echo "[DEBUG] COMMIT=$COMMIT"

# 加载 GitHub 配置
if [ ! -f "$HOME/git_constants.sh" ]; then
    echo "[ERROR] git_constants.sh 不存在"
    exit 31
fi
source "$HOME/git_constants.sh"

# -----------------------------
# 调用核心函数
# -----------------------------
# 修改点：首次 push 到远程 main 时加 -u origin main，其他逻辑不变
upload_to_github \
    "$TARGET" \
    "$COMMIT" \
    "$GITLAB_USER" \
    "$GITLAB_PAT" \
    "$REPO_URL" \
    "${BRANCH:-main}"

exit $?

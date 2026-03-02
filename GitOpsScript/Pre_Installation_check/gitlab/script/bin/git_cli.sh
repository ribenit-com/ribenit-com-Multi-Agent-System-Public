#!/bin/bash
set -euo pipefail                     # 严格模式

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
                                      # 获取项目根目录

source "$BASE_DIR/core/git_core.sh"  # 引入核心逻辑

if [ $# -lt 1 ]; then                 # 如果参数少于1
    echo "用法: ./git_cli.sh <目录> [commit]"
    exit 30                           # 返回参数错误
fi

TARGET="$1"                           # 第一个参数：目录
COMMIT="${2:-自动提交 $(date)}"        # 第二个参数：提交信息

source "$HOME/git_constants.sh"       # 加载用户配置
                                      # GITLAB_USER
                                      # GITLAB_PAT
                                      # REPO_URL
                                      # BRANCH

upload_to_github \                    # 调用核心函数
    "$TARGET" \
    "$COMMIT" \
    "$GITLAB_USER" \
    "$GITLAB_PAT" \
    "$REPO_URL" \
    "${BRANCH:-main}"

exit $?                                # 返回函数执行结果

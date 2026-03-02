#!/bin/bash
set -euo pipefail

# ====== 配置 ======
REPO_RAW_BASE="https://raw.githubusercontent.com/ribenit-com/ribenit-com-Multi-Agent-System-Public/refs/heads/main/GitOpsScript/Pre_Installation_check/gitlab/script"
CONSTANTS_URL="https://raw.githubusercontent.com/ribenit-com/ribenit-com-Multi-Agent-System-Public/refs/heads/main/GitOpsScript/config/git_constants.sh"

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
CORE_DIR="$BASE_DIR/core"
BIN_DIR="$BASE_DIR/bin"
CONFIG_DIR="$BASE_DIR/config"

echo "========== 开始刷新远程代码 =========="

# 删除旧 core 和 bin
rm -rf "$CORE_DIR"
rm -rf "$BIN_DIR"

# 重新创建目录
mkdir -p "$CORE_DIR"
mkdir -p "$BIN_DIR"
mkdir -p "$CONFIG_DIR"

# 下载 core 文件
for file in error_codes.sh git_core.sh git_exec.sh logger.sh; do
    echo "下载 core/$file ..."
    curl -fsSL "$REPO_RAW_BASE/core/$file" -o "$CORE_DIR/$file"
done

# 下载 bin 文件
echo "下载 bin/git_cli.sh ..."
curl -fsSL "$REPO_RAW_BASE/bin/git_cli.sh" -o "$BIN_DIR/git_cli.sh"

echo "========== 下载 Token 文件 =========="

# 下载 git_constants.sh
curl -fsSL "$CONSTANTS_URL" -o "$CONFIG_DIR/git_constants.sh"

if [[ ! -f "$CONFIG_DIR/git_constants.sh" ]]; then
    echo "❌ Token 文件下载失败"
    exit 1
fi

# 设置权限防止泄露
chmod 600 "$CONFIG_DIR/git_constants.sh"

echo "✅ Token 文件下载完成"

# 赋执行权限
chmod +x "$CORE_DIR"/*.sh
chmod +x "$BIN_DIR"/*.sh

echo "========== 代码刷新完成 =========="
echo "========== 开始执行单元测试 =========="

# ====== 引入 Token ======
source "$CONFIG_DIR/git_constants.sh"

# ====== 下面是 mock 测试（如果你想真实 push，请删除这些函数） ======
git_add_all() { echo "MOCK add"; }
git_commit() { echo "MOCK commit"; }
git_push() { echo "MOCK push"; }
git_set_remote() { echo "MOCK set remote"; }
git_ls_remote() { return 0; }

# 加载核心逻辑
source "$CORE_DIR/git_core.sh"

# 使用真实 Token 变量
upload_to_github "/tmp" "test commit" "$GITLAB_USER" "$GITLAB_PAT" "$REPO_URL" "${BRANCH:-main}"

echo "✅ 单元测试通过"

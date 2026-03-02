#!/bin/bash
set -euo pipefail

# ====== 配置 ======
REPO_RAW_BASE="https://raw.githubusercontent.com/ribenit-com/ribenit-com-Multi-Agent-System-Public/refs/heads/main/GitOpsScript/Pre_Installation_check/gitlab/script"
BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CORE_DIR="$BASE_DIR/core"
BIN_DIR="$BASE_DIR/bin"

echo "========== 开始刷新远程代码 =========="

# 删除旧 core 和 bin
rm -rf "$CORE_DIR"
rm -rf "$BIN_DIR"

# 重新创建目录
mkdir -p "$CORE_DIR"
mkdir -p "$BIN_DIR"

# 下载 core 文件
for file in error_codes.sh git_core.sh git_exec.sh logger.sh; do
    echo "下载 core/$file ..."
    curl -fsSL "$REPO_RAW_BASE/core/$file" -o "$CORE_DIR/$file"
done

# 下载 bin 文件
echo "下载 bin/git_cli.sh ..."
curl -fsSL "$REPO_RAW_BASE/bin/git_cli.sh" -o "$BIN_DIR/git_cli.sh"

# 赋执行权限
chmod +x "$CORE_DIR"/*.sh
chmod +x "$BIN_DIR"/*.sh

echo "========== 代码刷新完成 =========="

echo "========== 开始执行单元测试 =========="

# ====== 下面是 mock 测试 ======

git_add_all() { echo "MOCK add"; }
git_commit() { echo "MOCK commit"; }
git_push() { echo "MOCK push"; }
git_set_remote() { echo "MOCK set remote"; }
git_ls_remote() { return 0; }

source "$CORE_DIR/git_core.sh"

upload_to_github "/tmp" "test commit" "user" "pat" "https://github.com/x/y.git" "main"

echo "✅ 单元测试通过"

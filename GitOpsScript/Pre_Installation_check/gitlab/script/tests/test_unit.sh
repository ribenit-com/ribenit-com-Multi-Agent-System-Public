#!/bin/bash
# ==========================================
# test_unit.sh - 单元测试脚本
# 自动刷新 core/ 脚本 + 下载 Token + 执行 git_exec.sh
# ==========================================

# ====== 切换到脚本所在目录 ======
cd "$(dirname "${BASH_SOURCE[0]}")"

# ====== 设置远程仓库基础 URL ======
REPO_BASE="https://raw.githubusercontent.com/ribenit-com/ribenit-com-Multi-Agent-System-Public/main/GitOpsScript/Pre_Installation_check/gitlab/script"

echo "========== 开始刷新远程代码 =========="

# ====== 刷新 core/ 脚本 ======
CORE_DIR="./core"
mkdir -p "$CORE_DIR"  # 如果 core/ 不存在就创建

# 定义 core/ 文件列表
CORE_FILES=("error_codes.sh" "git_core.sh" "git_exec.sh" "logger.sh")

# 循环下载每个文件
for file in "${CORE_FILES[@]}"; do
    echo "下载 core/$file ..."
    curl -sSfL "$REPO_BASE/core/$file" -o "$CORE_DIR/$file" \
        && echo "✅ core/$file 下载完成" \
        || echo "❌ core/$file 下载失败"
done

# ====== 刷新 bin/ 脚本 ======
BIN_DIR="./bin"
mkdir -p "$BIN_DIR"
BIN_FILES=("git_cli.sh")

for file in "${BIN_FILES[@]}"; do
    echo "下载 bin/$file ..."
    curl -sSfL "$REPO_BASE/bin/$file" -o "$BIN_DIR/$file" \
        && echo "✅ bin/$file 下载完成" \
        || echo "❌ bin/$file 下载失败"
done

echo "========== 下载 Token 文件 =========="
TOKEN_FILE="token.txt"
curl -sSfL "$REPO_BASE/$TOKEN_FILE" -o "$TOKEN_FILE" \
    && echo "✅ Token 文件下载完成" \
    || echo "❌ Token 文件下载失败"

echo "========== 代码刷新完成 =========="

echo "========== 开始执行单元测试 =========="

# ====== 执行 git_exec.sh 单元测试 ======
bash "$CORE_DIR/git_exec.sh"

echo "========== 单元测试完成 =========="

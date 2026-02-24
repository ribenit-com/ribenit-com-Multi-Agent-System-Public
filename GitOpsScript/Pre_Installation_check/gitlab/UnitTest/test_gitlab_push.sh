#!/bin/bash
# ===============================================
# upload.sh 自动化测试脚本 
# ===============================================

set -euo pipefail

# ====== 测试配置 ======
SCRIPT_PATH="./upload.sh"
TEST_DIR="/tmp/test_git_upload_$$"
REMOTE_DIR="/tmp/test_remote_repo_$$"
BRANCH="main"

echo "🔹 创建测试目录"
mkdir -p "$TEST_DIR"
mkdir -p "$REMOTE_DIR"

echo "🔹 初始化远程裸仓库"
git init --bare "$REMOTE_DIR"

echo "🔹 初始化本地测试仓库"
cd "$TEST_DIR"
git init
git remote add origin "$REMOTE_DIR"

echo "hello world" > test.txt
git add test.txt
git commit -m "init commit"

echo "🔹 执行被测试脚本"
"$SCRIPT_PATH" "$TEST_DIR" "$BRANCH" "test commit"

echo "🔹 验证远程仓库是否收到提交"

if git --git-dir="$REMOTE_DIR" log &>/dev/null; then
    echo "✅ 测试通过：代码成功推送到远程仓库"
else
    echo "❌ 测试失败：远程仓库没有提交记录"
    exit 1
fi

echo "🔹 清理测试目录"
rm -rf "$TEST_DIR"
rm -rf "$REMOTE_DIR"

echo "🎉 所有测试完成"

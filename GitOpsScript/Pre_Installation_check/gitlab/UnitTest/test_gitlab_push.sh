#!/bin/bash
# ===============================================
# 标准 Git 上传脚本（支持单元测试 + 真实远程）
# ===============================================

set -euo pipefail

########################################
# 参数说明
# $1: 本地仓库路径
# $2: 远程仓库地址
# $3: 分支名（默认 master）
########################################

LOCAL_DIR="${1:-}"
REMOTE_URL="${2:-}"
BRANCH="${3:-master}"

if [[ -z "$LOCAL_DIR" || -z "$REMOTE_URL" ]]; then
    echo "❌ 用法: ./upload.sh <本地目录> <远程地址> [分支]"
    exit 1
fi

echo "🔹 进入目录: $LOCAL_DIR"
cd "$LOCAL_DIR"

########################################
# 初始化仓库（如果还没有）
########################################
if [ ! -d ".git" ]; then
    echo "🔹 初始化 Git 仓库"
    git init
fi

########################################
# 添加远程（如果不存在）
########################################
if ! git remote | grep -q origin; then
    echo "🔹 添加远程仓库"
    git remote add origin "$REMOTE_URL"
else
    echo "🔹 更新远程仓库地址"
    git remote set-url origin "$REMOTE_URL"
fi

########################################
# 添加文件并提交
########################################
echo "🔹 添加文件"
git add .

if git diff --cached --quiet; then
    echo "⚠️ 没有变更可提交"
else
    echo "🔹 提交变更"
    git commit -m "auto commit"
fi

########################################
# 推送
########################################
echo "🔹 推送到 $BRANCH"
git push -u origin "$BRANCH"

echo "✅ 上传完成"

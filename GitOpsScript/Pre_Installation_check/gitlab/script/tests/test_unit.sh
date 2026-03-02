#!/bin/bash
# ==========================================
# test_unit.sh - 一键执行 Git 上传测试（含回滚）
# 动态 token + 支持首次 push main
# ==========================================

set -euo pipefail

# ====== 基础路径 ======
BASE_DIR="$HOME/test_git_upload"
mkdir -p "$BASE_DIR"
cd "$BASE_DIR"

# ====== 下载 core/ 和 bin/ 脚本 ======
REPO_BASE="https://raw.githubusercontent.com/ribenit-com/ribenit-com-Multi-Agent-System-Public/main/GitOpsScript/Pre_Installation_check/gitlab/script"
CORE_DIR="$BASE_DIR/core"
BIN_DIR="$BASE_DIR/bin"
mkdir -p "$CORE_DIR" "$BIN_DIR"

CORE_FILES=("error_codes.sh" "git_core.sh" "git_exec.sh" "logger.sh")
BIN_FILES=("git_cli.sh")

for f in "${CORE_FILES[@]}"; do
    curl -sSfL "$REPO_BASE/core/$f" -o "$CORE_DIR/$f" || echo "⚠️ 下载 core/$f 失败"
done

for f in "${BIN_FILES[@]}"; do
    curl -sSfL "$REPO_BASE/bin/$f" -o "$BIN_DIR/$f" || echo "⚠️ 下载 bin/$f 失败"
done

# ====== 动态生成或加载 git_constants.sh ======
GIT_CONST="$HOME/git_constants.sh"

if [ -f "$HOME/token.txt" ]; then
    # token.txt 存在，生成或更新 git_constants.sh
    cp "$HOME/token.txt" "$GIT_CONST"
    echo "[INFO] ✅ 已从 token.txt 生成 git_constants.sh"
elif [ -f "$GIT_CONST" ]; then
    # token.txt 不存在，但 git_constants.sh 已存在，直接使用
    echo "[INFO] ℹ️ 使用已有 git_constants.sh"
else
    # token.txt 和 git_constants.sh 都不存在，生成占位文件
    echo "GITLAB_USER=\"你的GitHub用户名\"" > "$GIT_CONST"
    echo "GITLAB_PAT=\"你的GitHub PAT\"" >> "$GIT_CONST"
    echo "REPO_URL=\"https://github.com/username/repo.git\"" >> "$GIT_CONST"
    echo "BRANCH=\"main\"" >> "$GIT_CONST"
    echo "[WARN] ⚠️ token.txt 不存在，已生成占位 git_constants.sh，请确认内容"
fi

# ====== 初始化测试仓库 ======
TEST_REPO="$BASE_DIR/test_repo"
mkdir -p "$TEST_REPO"
cd "$TEST_REPO"
git init
echo "测试文件 $(date)" > test.txt

# ====== 执行上传 ======
echo "[INFO] 开始执行上传测试..."
bash "$BIN_DIR/git_cli.sh" "$TEST_REPO" "测试提交 $(date)"

echo "[INFO] 上传测试完成，日志请查看控制台输出"

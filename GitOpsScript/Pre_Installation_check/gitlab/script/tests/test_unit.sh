#!/bin/bash
# ==========================================
# test_unit.sh - 一键执行 Git 上传测试（含回滚）
# 每次执行都强制下载最新 core/ 和 bin/ 脚本
# ==========================================

set -euo pipefail  # 开启严格模式

# ====== 基础路径 ======
BASE_DIR="$HOME/test_git_upload"         # 定义基础目录
mkdir -p "$BASE_DIR"                     # 确保目录存在
cd "$BASE_DIR"                           # 切换到基础目录

# ====== 下载 core/ 和 bin/ 脚本 ======
REPO_BASE="https://raw.githubusercontent.com/ribenit-com/ribenit-com-Multi-Agent-System-Public/main/GitOpsScript/Pre_Installation_check/gitlab/script"
CORE_DIR="$BASE_DIR/core"                # 核心脚本存放目录
BIN_DIR="$BASE_DIR/bin"                  # 命令入口脚本存放目录
CONFIG_DIR="$BASE_DIR/config"            # config 目录
mkdir -p "$CORE_DIR" "$BIN_DIR" "$CONFIG_DIR"  # 创建目录

# 定义核心脚本列表
CORE_FILES=("error_codes.sh" "git_core.sh" "git_exec.sh" "logger.sh")
# 定义 bin 脚本列表
BIN_FILES=("git_cli.sh")
# 定义 config 文件
CONFIG_FILE="git_constants.sh"

# ====== 下载 core 脚本（每次强制下载最新） ======
for f in "${CORE_FILES[@]}"; do
    curl -sSfL "$REPO_BASE/core/$f" -o "$CORE_DIR/$f" || echo "⚠️ 下载 core/$f 失败"
done

# ====== 下载 bin 脚本（每次强制下载最新） ======
for f in "${BIN_FILES[@]}"; do
    curl -sSfL "$REPO_BASE/bin/$f" -o "$BIN_DIR/$f" || echo "⚠️ 下载 bin/$f 失败"
done

# ====== 下载 config/git_constants.sh（如果不存在才生成占位） ======
GIT_CONST="$CONFIG_DIR/$CONFIG_FILE"
if [ ! -f "$GIT_CONST" ]; then
    echo "GITLAB_USER=\"你的GitHub用户名\"" > "$GIT_CONST"
    echo "GITLAB_PAT=\"你的GitHub PAT\"" >> "$GIT_CONST"
    echo "REPO_URL=\"https://github.com/username/repo.git\"" >> "$GIT_CONST"
    echo "BRANCH=\"main\"" >> "$GIT_CONST"
    echo "[WARN] ⚠️ git_constants.sh 不存在，已生成占位文件，请确认内容"
else
    echo "[INFO] ℹ️ 使用已有 git_constants.sh"
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

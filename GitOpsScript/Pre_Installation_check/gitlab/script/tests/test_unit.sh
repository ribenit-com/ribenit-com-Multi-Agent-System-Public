#!/bin/bash
# ==========================================
# test_unit.sh - 一键执行 Git 上传测试（含回滚）
# 每次执行都强制下载最新 core/ 和 bin/ 脚本
# 自动下载 git_constants.sh（如果不存在）
# 支持安全 push（SSH 或 credential helper）
# 版本: v1.4
# 修改日期: 2026-03-02 19:30
# ==========================================

set -euo pipefail  # 严格模式

# ====== 版本信息打印 ======
SCRIPT_VERSIONS=(
    "test_unit.sh:v1.4:2026-03-02 19:30"
    "git_core.sh:v1.4:2026-03-02 18:30"
    "git_cli.sh:v1.0:2026-03-02 16:00"
    "logger.sh:v1.2:2026-03-02 15:45"
    "error_codes.sh:v1.0:2026-03-02 15:30"
    "git_exec.sh:v1.1:2026-03-02 15:50"
)
echo "===== 当前脚本及依赖版本 ====="
for v in "${SCRIPT_VERSIONS[@]}"; do
    IFS=':' read -r file version modified <<< "$v"
    echo "■■■$file■■■：■■■$version■■■：■■■$modified■■■"
done
echo "================================="

# ====== 基础路径 ======
BASE_DIR="$HOME/test_git_upload"
mkdir -p "$BASE_DIR"
cd "$BASE_DIR"

# ====== 下载 core/ 和 bin/ 脚本 ======
REPO_BASE="https://raw.githubusercontent.com/ribenit-com/ribenit-com-Multi-Agent-System-Public/main/GitOpsScript/Pre_Installation_check/gitlab/script"
CORE_DIR="$BASE_DIR/core"
BIN_DIR="$BASE_DIR/bin"
CONFIG_DIR="$BASE_DIR/config"
mkdir -p "$CORE_DIR" "$BIN_DIR" "$CONFIG_DIR"

CORE_FILES=("error_codes.sh" "git_core.sh" "git_exec.sh" "logger.sh")
BIN_FILES=("git_cli.sh")
CONFIG_FILE="git_constants.sh"

# 下载 core
for f in "${CORE_FILES[@]}"; do
    curl -sSfL "$REPO_BASE/core/$f" -o "$CORE_DIR/$f" || echo "⚠️ 下载 core/$f 失败"
done

# 下载 bin
for f in "${BIN_FILES[@]}"; do
    curl -sSfL "$REPO_BASE/bin/$f" -o "$BIN_DIR/$f" || echo "⚠️ 下载 bin/$f 失败"
done

# ====== 自动下载配置文件（如果不存在） ======
GIT_CONST="$CONFIG_DIR/$CONFIG_FILE"

if [ ! -f "$GIT_CONST" ]; then
    echo "[INFO] ℹ️ 配置文件 $GIT_CONST 不存在，尝试自动下载..."
    curl -sSfL "$REPO_BASE/config/$CONFIG_FILE" -o "$GIT_CONST" \
        && echo "[INFO] 配置文件已下载到 $GIT_CONST" \
        || { echo "[ERROR] 下载 config/$CONFIG_FILE 失败，请手动创建"; exit 1; }
    echo "[WARN] ⚠️ 配置文件可能是模板，请填写真实 Git 信息（SSH 或 HTTPS PAT）后才能上传成功"
fi

# 输出加载信息
echo "[INFO] ℹ️ 使用配置文件 $GIT_CONST，内容如下："
cat "$GIT_CONST"

# ====== 设置环境变量，让 git_core.sh 使用下载路径 ======
export GIT_CONST_PATH="$GIT_CONST"

# -----------------------------
# 初始化测试仓库
# -----------------------------
TEST_REPO="$BASE_DIR/test_repo"
mkdir -p "$TEST_REPO"
cd "$TEST_REPO"
git init
echo "测试文件 $(date)" > test.txt

# -----------------------------
# 检查是否有 SSH key 或 HTTPS credential helper
# -----------------------------
if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
    echo "[INFO] ℹ️ 检测到可用 SSH Key，将使用 SSH 推送"
else
    echo "[INFO] ℹ️ 未检测到 SSH Key，请确保已配置 HTTPS credential helper 或 gh CLI 登录"
fi

# -----------------------------
# 执行上传
# -----------------------------
echo "[INFO] 开始执行上传测试..."
# 使用 git_cli.sh 进行上传
bash "$BIN_DIR/git_cli.sh" "$TEST_REPO" "测试提交 $(date)"

echo "[INFO] 上传测试完成，日志请查看控制台输出"

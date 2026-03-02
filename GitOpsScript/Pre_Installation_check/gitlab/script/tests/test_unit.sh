#!/bin/bash
# ==========================================
# test_unit.sh - 一键执行 Git 上传测试（含回滚）
# 每次执行都强制下载最新 core/ 和 bin/ 脚本
# 版本: v1.2
# 修改日期: 2026-03-02 17:45
# ==========================================

set -euo pipefail  # 开启严格模式

# ====== 版本信息打印 ======
SCRIPT_VERSIONS=(
    "test_unit.sh:v1.2:2026-03-02 17:45"
    "git_core.sh:v1.4:2026-03-02 16:50"
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

# ====== 统一读取配置文件 ======
GIT_CONST="$CONFIG_DIR/$CONFIG_FILE"

# 只读取，不生成任何占位符
if [ ! -f "$GIT_CONST" ]; then
    echo "[ERROR] ⚠️ 配置文件 $GIT_CONST 不存在，请先创建并填写真实 Git 信息"
    exit 1
fi

# 输出加载信息
echo "[INFO] ℹ️ 使用配置文件 $GIT_CONST，内容如下："
cat "$GIT_CONST"

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

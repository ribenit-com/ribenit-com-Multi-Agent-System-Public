#!/bin/bash
# ==========================================
# test_unit.sh - 单元测试脚本
# 自动刷新 core/ 脚本 + 下载 Token(git_constants.sh) + 执行 git_exec.sh
# 如果本地已有 token.txt 会直接使用
# ==========================================

# ====== 切换到脚本所在目录 ======
cd "$(dirname "${BASH_SOURCE[0]}")"

# ====== 设置远程仓库基础 URL ======
REPO_BASE="https://raw.githubusercontent.com/ribenit-com/ribenit-com-Multi-Agent-System-Public/main/GitOpsScript/Pre_Installation_check/gitlab/script"
TOKEN_URL="https://raw.githubusercontent.com/ribenit-com/ribenit-com-Multi-Agent-System-Public/refs/heads/main/GitOpsScript/config/git_constants.sh"
TOKEN_FILE="token.txt"

# ====== 日志函数（简化彩色提示） ======
log_info()  { echo -e "\033[36m[INFO]\033[0m $*"; }
log_warn()  { echo -e "\033[33m[WARN]\033[0m $*"; }
log_error() { echo -e "\033[31m[ERROR]\033[0m $*"; }

log_info "========== 开始刷新远程代码 =========="

# ====== 刷新 core/ 脚本 ======
CORE_DIR="./core"
mkdir -p "$CORE_DIR"
CORE_FILES=("error_codes.sh" "git_core.sh" "git_exec.sh" "logger.sh")

for file in "${CORE_FILES[@]}"; do
    log_info "下载 core/$file ..."
    if curl -sSfL "$REPO_BASE/core/$file" -o "$CORE_DIR/$file"; then
        log_info "✅ core/$file 下载完成"
    else
        log_warn "⚠️ core/$file 下载失败，检查网络或文件是否存在"
    fi
done

# ====== 刷新 bin/ 脚本 ======
BIN_DIR="./bin"
mkdir -p "$BIN_DIR"
BIN_FILES=("git_cli.sh")

for file in "${BIN_FILES[@]}"; do
    log_info "下载 bin/$file ..."
    if curl -sSfL "$REPO_BASE/bin/$file" -o "$BIN_DIR/$file"; then
        log_info "✅ bin/$file 下载完成"
    else
        log_warn "⚠️ bin/$file 下载失败，检查网络或文件是否存在"
    fi
done

# ====== 下载 Token 文件 ======
log_info "========== 下载 Token 文件 =========="

if curl -sSfL "$TOKEN_URL" -o "$TOKEN_FILE"; then
    log_info "✅ Token 文件下载完成，保存为 $TOKEN_FILE"
else
    if [ -f "$TOKEN_FILE" ]; then
        log_warn "⚠️ 远程 Token 文件不存在，使用本地已有文件 $TOKEN_FILE"
    else
        log_error "❌ Token 文件下载失败，且本地不存在，请手动提供 $TOKEN_FILE"
    fi
fi

log_info "========== 代码刷新完成 =========="

log_info "========== 开始执行单元测试 =========="

# ====== 执行 git_exec.sh 单元测试 ======
bash "$CORE_DIR/git_exec.sh"

log_info "========== 单元测试完成 =========="

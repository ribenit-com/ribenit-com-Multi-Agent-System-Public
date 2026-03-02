#!/bin/bash
# ==========================================
# test_unit.sh - 一键执行 Git 上传测试（含回滚）
# 全局静态 token + 支持首次 push main
# ==========================================

set -euo pipefail  # 开启严格模式：-e 出错停止，-u 未定义变量报错，-o pipefail 管道失败报错

# ====== 基础路径 ======
BASE_DIR="$HOME/test_git_upload"         # 定义基础目录
mkdir -p "$BASE_DIR"                     # 确保目录存在
cd "$BASE_DIR"                           # 切换到基础目录

# ====== 下载 core/ 和 bin/ 脚本 ======
REPO_BASE="https://raw.githubusercontent.com/ribenit-com/ribenit-com-Multi-Agent-System-Public/main/GitOpsScript/Pre_Installation_check/gitlab/script"
CORE_DIR="$BASE_DIR/core"                # 核心脚本存放目录
BIN_DIR="$BASE_DIR/bin"                  # 命令入口脚本存放目录
mkdir -p "$CORE_DIR" "$BIN_DIR"          # 创建目录（如果不存在）

# 定义核心脚本列表
CORE_FILES=("error_codes.sh" "git_core.sh" "git_exec.sh" "logger.sh")
# 定义 bin 脚本列表
BIN_FILES=("git_cli.sh")

# 下载 core 脚本
for f in "${CORE_FILES[@]}"; do
    curl -sSfL "$REPO_BASE/core/$f" -o "$CORE_DIR/$f" || echo "⚠️ 下载 core/$f 失败"
done

# 下载 bin 脚本
for f in "${BIN_FILES[@]}"; do
    curl -sSfL "$REPO_BASE/bin/$f" -o "$BIN_DIR/$f" || echo "⚠️ 下载 bin/$f 失败"
done

# ====== 加载全局静态 git_constants.sh ======
GIT_CONST="$HOME/git_constants.sh"      # 定义全局常量路径

if [ -f "$GIT_CONST" ]; then             # 如果 git_constants.sh 存在
    echo "[INFO] ℹ️ 使用已有 git_constants.sh"
else                                     # 否则生成占位文件
    echo "GITLAB_USER=\"你的GitHub用户名\"" > "$GIT_CONST"
    echo "GITLAB_PAT=\"你的GitHub PAT\"" >> "$GIT_CONST"
    echo "REPO_URL=\"https://github.com/username/repo.git\"" >> "$GIT_CONST"
    echo "BRANCH=\"main\"" >> "$GIT_CONST"
    echo "[WARN] ⚠️ git_constants.sh 不存在，已生成占位文件，请确认内容"
fi

# ====== 初始化测试仓库 ======
TEST_REPO="$BASE_DIR/test_repo"          # 测试仓库目录
mkdir -p "$TEST_REPO"                    # 确保目录存在
cd "$TEST_REPO"                           # 切换到测试仓库
git init                                  # 初始化 Git 仓库
echo "测试文件 $(date)" > test.txt       # 生成测试文件

# ====== 执行上传 ======
echo "[INFO] 开始执行上传测试..."
bash "$BIN_DIR/git_cli.sh" "$TEST_REPO" "测试提交 $(date)"  # 调用 git_cli.sh 上传

echo "[INFO] 上传测试完成，日志请查看控制台输出"

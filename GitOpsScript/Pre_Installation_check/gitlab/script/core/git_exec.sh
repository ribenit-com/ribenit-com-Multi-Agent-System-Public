#!/bin/bash
# ==========================================
# git_exec.sh - Git 执行工具脚本
# 彩色日志 + 绝对路径引用依赖
# ==========================================

# ====== 获取当前脚本所在目录 ======
# BASH_SOURCE[0] 获取当前脚本路径
# cd + pwd 获取绝对路径
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# ====== 加载 logger.sh ======
# 使用绝对路径，保证无论从哪运行都能找到
source "$SCRIPT_DIR/logger.sh"

# ====== Git 执行函数 ======
git_exec() {
    local cmd="$1"  # $1 是要执行的 Git 命令

    log_info "执行 Git 命令: $cmd"  # 打印执行信息

    eval "$cmd"                     # 执行命令

    local status=$?                 # 捕获执行状态码
    if [ $status -ne 0 ]; then
        log_error "Git 命令失败，状态码: $status"  # 打印错误
    else
        log_info "Git 命令执行成功"             # 打印成功信息
    fi
}

# ====== 如果脚本被直接执行，示例调用 ======
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    git_exec "git --version"
fi

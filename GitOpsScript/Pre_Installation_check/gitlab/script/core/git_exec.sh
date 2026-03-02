#!/bin/bash
# ==========================================
# git_exec.sh - Git 执行工具脚本
# 修复路径问题，确保依赖 logger.sh 可用
# ==========================================

# ====== 获取当前脚本所在目录 ======
# BASH_SOURCE[0] 获取当前脚本路径
# cd + pwd 获取绝对路径
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# ====== 加载 logger.sh ======
# 依赖文件在同一目录下，用绝对路径引用
source "$SCRIPT_DIR/logger.sh"

# ====== 示例函数：执行 Git 命令并打印 ======
git_exec() {
    # $1 是 Git 命令
    local cmd="$1"
    
    # 打印正在执行的命令
    log_info "执行 Git 命令: $cmd"
    
    # 执行命令
    eval "$cmd"
    
    # 捕获执行状态
    local status=$?
    if [ $status -ne 0 ]; then
        log_error "Git 命令失败，状态码: $status"
    else
        log_info "Git 命令执行成功"
    fi
}

# ====== 如果脚本被直接执行，示例调用 ======
# 可在测试或调试时使用
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    git_exec "git --version"
fi

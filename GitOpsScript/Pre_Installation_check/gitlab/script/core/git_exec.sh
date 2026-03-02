#!/bin/bash
# ==========================================
# git_exec.sh - Git 执行工具脚本
# 彩色日志 + Git 工具函数
# 每行均带注释，便于理解
# ==========================================

set -euo pipefail                     # 开启严格模式：-e 出错停止，-u 未定义变量报错，-o pipefail 管道失败报错

# ====== 获取当前脚本所在目录 ======
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)   # 获取脚本绝对路径，保证无论从哪运行都能找到依赖

# ====== 加载日志模块 ======
source "$SCRIPT_DIR/logger.sh"        # 加载 logger.sh，提供 log_info/log_warn/log_error 等日志函数

# ====== 基本 Git 命令封装函数 ======
git_exec() {                          # 定义函数 git_exec，用于执行任意 Git 命令
    local cmd="$1"                     # 获取第一个参数作为 Git 命令
    log_info "执行 Git 命令: $cmd"     # 打印日志，显示即将执行的命令
    eval "$cmd"                        # 使用 eval 执行命令
    local status=$?                     # 捕获执行状态码
    if [ $status -ne 0 ]; then         # 如果状态码非 0，说明命令失败
        log_error "Git 命令失败，状态码: $status"  # 打印错误日志
    else
        log_info "Git 命令执行成功"   # 命令成功，打印信息日志
    fi
    return $status                      # 返回 Git 命令的状态码
}

# ====== 常用 Git 工具函数 ======
git_add_all()   { git add .; }                 # 添加当前目录下所有修改到 Git 暂存区
git_commit()    { git commit -m "$1"; }       # 提交修改，$1 是 commit 信息
git_push()      { git push "$1"; }            # 推送到指定分支，$1 是分支名
git_ls_remote() { git ls-remote "$1" &>/dev/null; }  # 测试远程仓库是否可访问，输出重定向丢弃
git_set_remote(){                              # 设置远程仓库 origin
    local user="$1"                            # Git 用户名
    local repo="$2"                            # 仓库 URL
    git remote remove origin &>/dev/null || true   # 先删除 origin（不存在也不报错）
    git remote add origin "$repo"             # 添加 origin 指向指定仓库
}

# ====== 如果直接执行脚本，显示 Git 版本 ======
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then   # 判断是否直接运行脚本
    git_exec "git --version"                   # 调用 git_exec 打印 Git 版本
fi

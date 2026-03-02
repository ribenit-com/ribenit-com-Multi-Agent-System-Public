#!/bin/bash                          # 使用 bash
set -euo pipefail                    # 严格模式：
                                     # -e  出错立即退出
                                     # -u  未定义变量报错
                                     # -o pipefail 管道错误捕获

source "$(dirname "$0")/logger.sh"       # 引入日志模块
source "$(dirname "$0")/error_codes.sh"  # 引入错误码

git_safe() {                         # 安全执行 git 命令
    if ! "$@"; then                  # 执行传入命令
        log_error "Git 命令失败: $*" # 如果失败打印错误
        return $E_GIT_ERROR          # 返回 Git 错误码
    fi
}

git_add_all() {                      # git add .
    git_safe git add .               # 通过安全封装执行
}

git_commit() {                       # 提交函数
    local msg="$1"                   # 提交信息
    git commit -m "$msg" || true     # 如果没有变更避免报错
}

git_push() {                         # 推送函数
    local branch="$1"                # 目标分支
    git_safe git push origin "$branch" || return $E_PUSH_FAIL
                                     # 执行 push，失败返回错误码
}

git_set_remote() {                   # 设置远程地址
    local user="$1"                  # 用户名
    local repo="$2"                  # 仓库 URL
    git_safe git remote set-url origin "https://${user}@${repo#https://}"
                                     # 替换 https:// 并插入用户名
}

git_ls_remote() {                    # 测试远程连接
    local repo="$1"                  # 仓库地址
    git ls-remote "$repo" &>/dev/null
                                     # 检查是否可访问
}

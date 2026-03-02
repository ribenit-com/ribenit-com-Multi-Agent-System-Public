#!/bin/bash
set -euo pipefail                   # 开启严格模式

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/logger.sh"      # 日志模块
source "$SCRIPT_DIR/error_codes.sh" # 错误码
source "$SCRIPT_DIR/git_exec.sh"    # Git 执行层

detect_os_helper() {                # 自动识别操作系统
    case "$(uname)" in
        Darwin) echo "osxkeychain" ;;
        Linux)  echo "cache --timeout=3600" ;;
        *)      echo "store" ;;
    esac
}

# ====== 替换为增强版 upload_to_github 函数 ======
upload_to_github() {                # 主函数（增强版，带回滚机制）

    local dir="$1"                  # 本地目录参数
    local msg="$2"                  # 提交信息参数
    local user="$3"                 # GitHub 用户名
    local pat="$4"                  # GitHub PAT（Token）
    local repo="$5"                 # 仓库 URL
    local branch="${6:-main}"       # 分支名称，默认 main

    log_info "进入目录: $dir"        # 打印日志，提示进入目录
    cd "$dir"                       # 切换到目标目录

    helper=$(detect_os_helper)      # 自动检测操作系统并返回 credential helper
    git config credential.helper "$helper"  # 配置 Git 凭证缓存方式

    git_set_remote "$user" "$repo"  # 设置远程仓库地址（origin URL）

    # 注入 GitHub PAT 到凭证缓存，避免 push 需要输入密码
    printf "protocol=https\nhost=github.com\nusername=%s\npassword=%s\n\n" \
           "$user" "$pat" | git credential approve

    # 测试远程仓库连接是否成功
    if git_ls_remote "$repo"; then
        log_info "认证成功"         # 认证成功，打印日志
    else
        log_error "认证失败"        # 认证失败，打印日志
        return $E_AUTH_FAIL         # 返回认证失败错误码
    fi

    # -----------------------------
    # 回滚机制：先备份当前未提交更改
    # -----------------------------
    log_info "创建临时 stash 备份（如果有未提交更改）"
    git stash push -m "pre-upload backup" || log_info "没有需要 stash 的更改"

    # -----------------------------
    # 执行 Git 操作，捕获错误，保证失败可以回滚
    # -----------------------------
    set +e                         # 关闭严格模式，允许捕获 git 命令失败
    git_add_all                     # 执行 git add .，添加所有修改
    git_commit "$msg"               # 执行 git commit -m "<msg>"
    git_push "$branch"              # 执行 git push 到指定分支
    status=$?                       # 捕获 git_push 的返回状态码
    set -e                          # 恢复严格模式

    # 如果 push 失败，则执行回滚
    if [ $status -ne 0 ]; then
        log_error "上传失败，开始回滚"   # 打印上传失败日志

        git reset --hard HEAD~1        # 回退 commit（撤销刚才的提交）
        git stash pop || log_warn "没有 stash 可恢复"  
        # 恢复之前 stash，如果没有 stash 会打印警告

        return $E_PUSH_FAIL            # 返回 push 失败的错误码
    fi

    log_info "上传完成"                  # 成功完成上传，打印日志
    return $E_OK                         # 返回成功状态码
}

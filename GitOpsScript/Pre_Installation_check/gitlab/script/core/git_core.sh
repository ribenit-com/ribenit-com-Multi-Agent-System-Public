#!/bin/bash
set -euo pipefail                   # 开启严格模式

source "$(dirname "$0")/logger.sh"      # 日志模块
source "$(dirname "$0")/error_codes.sh" # 错误码
source "$(dirname "$0")/git_exec.sh"    # Git 执行层

detect_os_helper() {                # 自动识别操作系统
    case "$(uname)" in              # 获取系统名称
        Darwin) echo "osxkeychain" ;;       # macOS
        Linux)  echo "cache --timeout=3600" ;; # Linux
        *)      echo "store" ;;             # 其他
    esac
}

upload_to_github() {                # 主函数

    local dir="$1"                  # 本地目录
    local msg="$2"                  # 提交信息
    local user="$3"                 # GitHub 用户
    local pat="$4"                  # GitHub Token
    local repo="$5"                 # 仓库 URL
    local branch="${6:-main}"       # 默认 main 分支

    log_info "进入目录: $dir"        # 日志
    cd "$dir"                       # 切换目录

    helper=$(detect_os_helper)      # 获取凭证存储方式
    git config credential.helper "$helper"
                                     # 设置凭证缓存方式

    git_set_remote "$user" "$repo"  # 设置远程地址

    printf "protocol=https\nhost=github.com\nusername=%s\npassword=%s\n\n" \
           "$user" "$pat" | git credential approve
                                     # 注入 PAT 到 Git 凭证缓存

    if git_ls_remote "$repo"; then  # 测试远程连接
        log_info "认证成功"
    else
        log_error "认证失败"
        return $E_AUTH_FAIL
    fi

    git_add_all                     # git add .
    git_commit "$msg"               # git commit
    git_push "$branch"              # git push

    log_info "上传完成"              # 成功日志
    return $E_OK                    # 返回成功
}

#!/bin/bash
# ==========================================
# git_core.sh - Git 上传核心函数（增强版）
# 支持回滚机制 + 默认 commit message
# ==========================================

upload_to_github() {
    # -----------------------------
    # 参数
    # -----------------------------
    local dir="$1"                             # 本地目录
    local msg="${2:-自动提交 $(date)}"         # 提交信息，默认值防止 $2 unbound variable
    local user="$3"                            # GitHub 用户名
    local pat="$4"                             # GitHub PAT（Token）
    local repo="$5"                            # 仓库 URL
    local branch="${6:-main}"                  # 分支名称，默认 main

    # -----------------------------
    # 进入目录 & 配置凭证
    # -----------------------------
    log_info "进入目录: $dir"
    cd "$dir" || { log_error "目录不存在: $dir"; return 1; }

    # 自动识别操作系统，配置 credential helper
    case "$(uname)" in
        Darwin) helper="osxkeychain" ;;
        Linux)  helper="cache --timeout=3600" ;;
        *)      helper="store" ;;
    esac
    git config credential.helper "$helper"

    # 设置远程仓库地址
    git_set_remote "$user" "$repo"

    # 注入 GitHub PAT 到凭证缓存
    printf "protocol=https\nhost=github.com\nusername=%s\npassword=%s\n\n" \
           "$user" "$pat" | git credential approve

    # 测试远程仓库连接
    if git_ls_remote "$repo"; then
        log_info "认证成功"
    else
        log_error "认证失败"
        return $E_AUTH_FAIL
    fi

    # -----------------------------
    # 回滚机制：备份当前未提交更改
    # -----------------------------
    log_info "创建临时 stash 备份（如果有未提交更改）"
    git stash push -m "pre-upload backup" || log_info "没有需要 stash 的更改"

    # -----------------------------
    # 执行 Git 操作，捕获错误
    # -----------------------------
    set +e                         # 关闭严格模式，允许捕获失败
    git_add_all                     # git add .
    git_commit "$msg"               # git commit -m "<msg>"
    git_push "$branch"              # git push
    status=$?                       # 捕获 push 状态
    set -e                          # 恢复严格模式

    # -----------------------------
    # push 失败回滚
    # -----------------------------
    if [ $status -ne 0 ]; then
        log_error "上传失败，开始回滚"
        git reset --hard HEAD~1
        git stash pop || log_warn "没有 stash 可恢复"
        return $E_PUSH_FAIL
    fi

    log_info "上传完成"
    return $E_OK
}

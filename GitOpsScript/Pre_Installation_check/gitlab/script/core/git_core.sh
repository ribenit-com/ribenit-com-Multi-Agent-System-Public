upload_to_github() {
    # -----------------------------
    # 参数
    # -----------------------------
    local dir="$1"                              # 本地目录
    local msg="${2:-自动提交 $(date)}"          # 提交信息，默认值防止 $2 unbound variable

    # -----------------------------
    # 从固定路径读取 GitHub 配置
    # -----------------------------
    source "${HOME}/git_constants.sh"
    : "${GITLAB_USER:?请在 git_constants.sh 设置 GITLAB_USER}"
    : "${GITLAB_PAT:?请在 git_constants.sh 设置 GITLAB_PAT}"
    : "${REPO_URL:?请在 git_constants.sh 设置 REPO_URL}"
    BRANCH="${BRANCH:-main}"

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
    git_set_remote "$GITLAB_USER" "$REPO_URL"

    # 注入 GitHub PAT 到凭证缓存
    printf "protocol=https\nhost=github.com\nusername=%s\npassword=%s\n\n" \
           "$GITLAB_USER" "$GITLAB_PAT" | git credential approve

    # 测试远程仓库连接
    if git_ls_remote "$REPO_URL"; then
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
    set +e
    git_add_all
    git_commit "$msg"
    git_push "$BRANCH"
    status=$?
    set -e

    # push 失败回滚
    if [ $status -ne 0 ]; then
        log_error "上传失败，开始回滚"
        git reset --hard HEAD~1
        git stash pop || log_warn "没有 stash 可恢复"
        return $E_PUSH_FAIL
    fi

    log_info "上传完成"
    return $E_OK
}

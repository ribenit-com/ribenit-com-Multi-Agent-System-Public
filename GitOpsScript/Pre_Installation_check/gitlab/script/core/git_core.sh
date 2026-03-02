#!/bin/bash
# ==========================================
# git_core.sh - Git 上传核心函数（增强版）
# 自动读取 ~/git_constants.sh
# 支持回滚机制 + 默认 commit message
# 已修改支持首次 push 到 main 分支
# 每行都加详细注释，便于理解
# ==========================================

set -euo pipefail  # 开启严格模式：-e 出错停止，-u 未定义变量报错，-o pipefail 管道失败也报错

# -----------------------------
# 获取当前脚本所在目录
# -----------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" 
# cd "$(dirname "${BASH_SOURCE[0]}")" 获取脚本所在目录
# pwd 输出绝对路径
# 组合保证无论从哪运行脚本都能找到相对依赖文件

# -----------------------------
# 加载日志模块和错误码
# -----------------------------
source "$SCRIPT_DIR/logger.sh"        # 加载日志函数 log_info/log_warn/log_error
source "$SCRIPT_DIR/error_codes.sh"   # 加载错误码，例如 $E_OK, $E_AUTH_FAIL, $E_PUSH_FAIL

# -----------------------------
# 加载 Git 执行工具函数
# -----------------------------
source "$SCRIPT_DIR/git_exec.sh"      # 加载 git_add_all/git_commit/git_push/git_ls_remote/git_set_remote 等工具函数

# -----------------------------
# 工具函数：检测操作系统，返回 Git credential helper
# -----------------------------
detect_os_helper() {
    case "$(uname)" in
        Darwin) echo "osxkeychain" ;;          # macOS 使用 osxkeychain
        Linux)  echo "cache --timeout=3600" ;; # Linux 使用缓存 1 小时
        *)      echo "store" ;;                # 其他系统使用 store
    esac
}

# -----------------------------
# 主函数：上传到 GitHub（增强版，带回滚机制）
# -----------------------------
upload_to_github() {
    local dir="$1"                             # 本地目录
    local msg="${2:-自动提交 $(date)}"         # commit 信息，默认自动提交加时间

    # -----------------------------
    # 检查并加载 GitHub 配置
    # -----------------------------
    if [ ! -f "${HOME}/git_constants.sh" ]; then
        log_error "未找到 git_constants.sh，请先创建 ~/git_constants.sh"
        return 1
    fi
    source "${HOME}/git_constants.sh"        # 加载用户配置
    : "${GITLAB_USER:?请在 git_constants.sh 设置 GITLAB_USER}"  # 确保用户名存在
    : "${GITLAB_PAT:?请在 git_constants.sh 设置 GITLAB_PAT}"    # 确保 PAT 存在
    : "${REPO_URL:?请在 git_constants.sh 设置 REPO_URL}"        # 确保仓库 URL 存在
    BRANCH="${BRANCH:-main}"                 # 分支默认 main，如果未设置

    # -----------------------------
    # 切换到目标目录
    # -----------------------------
    log_info "进入目录: $dir"                 # 打印日志
    cd "$dir" || { log_error "目录不存在: $dir"; return 1; } # 如果目录不存在返回错误

    # -----------------------------
    # 配置 Git credential helper
    # -----------------------------
    helper=$(detect_os_helper)               # 自动检测操作系统
    git config credential.helper "$helper"   # 配置凭证助手

    # -----------------------------
    # 确保本地分支为 main
    # -----------------------------
    git branch -m main 2>/dev/null || true  # 如果当前分支不是 main，则重命名为 main；已有 main 则忽略错误

    # -----------------------------
    # 设置远程仓库地址
    # -----------------------------
    git_set_remote "$GITLAB_USER" "$REPO_URL"  # 调用工具函数设置 origin

    # -----------------------------
    # 注入 GitHub PAT 到凭证缓存
    # -----------------------------
    printf "protocol=https\nhost=github.com\nusername=%s\npassword=%s\n\n" \
           "$GITLAB_USER" "$GITLAB_PAT" | git credential approve
    # 直接将用户名和 PAT 写入 git credential，避免 push 时输入

    # -----------------------------
    # 测试远程仓库连接
    # -----------------------------
    if git_ls_remote "$REPO_URL"; then
        log_info "认证成功"                   # 可访问远程仓库
    else
        log_error "认证失败"                  # 无法访问仓库
        return $E_AUTH_FAIL
    fi

    # -----------------------------
    # 回滚机制：先 stash 未提交的更改
    # -----------------------------
    log_info "创建临时 stash 备份（如果有未提交更改）"
    git stash push -m "pre-upload backup" || log_info "没有需要 stash 的更改"

    # -----------------------------
    # 执行 Git 操作
    # -----------------------------
    set +e                                   # 关闭严格模式，允许命令失败
    git_add_all                               # git add .
    git_commit "$msg"                         # git commit -m "<msg>"

    # 首次 push 时指定 upstream
    git_push -u origin "$BRANCH"              # push 到远程仓库，设置 upstream
    status=$?                                 # 捕获 push 状态
    set -e                                    # 恢复严格模式

    # -----------------------------
    # push 失败回滚
    # -----------------------------
    if [ $status -ne 0 ]; then
        log_error "上传失败，开始回滚"
        git reset --hard HEAD~1               # 回退 commit
        git stash pop || log_warn "没有 stash 可恢复"  # 恢复未提交的更改
        return $E_PUSH_FAIL
    fi

    log_info "上传完成"                         # 打印上传完成
    return $E_OK                               # 返回成功状态码
}

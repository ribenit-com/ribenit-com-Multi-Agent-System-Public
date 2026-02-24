
#!/bin/bash
# ===============================================
# 一键安全上传 GitHub 代码脚本（PAT 自动配置 + Push） 
# 使用场景：安全、跨平台，一次执行完成 PAT 配置和代码上传
# ===============================================
###############################################################################
# 脚本名称：
#   GitHub 一键安全上传脚本（PAT 自动配置 + Push）
#
# 脚本核心目标：
#   自动完成 GitHub Personal Access Token（PAT）的安全配置，
#   并将当前本地代码提交并推送到指定远程仓库分支。
#
# 本脚本要完成的任务：
#
#   1️⃣ 自动识别当前操作系统
#      - macOS → 使用 osxkeychain
#      - Linux → 使用 cache（默认缓存1小时）
#      - Windows → 使用 manager-core
#      - 未识别系统 → fallback 到 store（明文）
#
#   2️⃣ 自动配置 Git Credential Helper
#      - 将 PAT 写入 Git 凭证系统
#      - 避免每次 push 都输入密码
#      - 实现一次认证，自动复用
#
#   3️⃣ 自动更新远程仓库 URL
#      - 将远程地址改为带用户名的 HTTPS 形式
#      - 确保 GitHub 能正确识别账户
#
#   4️⃣ 写入 Personal Access Token (PAT)
#      - 通过 git credential approve 注入凭证
#      - 避免明文写入 .git/config
#
#   5️⃣ 测试远程仓库访问
#      - 使用 git ls-remote 验证权限
#      - 如果失败立即退出
#
#   6️⃣ 自动提交并推送代码
#      - git add .
#      - 自动生成 commit 信息（可自定义）
#      - git push 到指定分支（默认 main）
#
#
# 预期达到的效果：
#
#   ✅ 一次执行完成：
#        - PAT 配置
#        - 认证验证
#        - 自动提交
#        - 自动推送
#
#   ✅ 跨平台兼容（Mac / Linux / Windows）
#   ✅ 减少人工输入密码
#   ✅ 可作为 CI/CD 前置步骤
#
#
# 适用场景：
#
#   - 本地开发环境快速初始化
#   - 自动化脚本批量上传
#   - DevOps 一键部署流程
#   - 新机器初始化 GitHub 权限
#
#
# 安全说明：
#
#   ⚠️ 当前脚本中 PAT 明文写在脚本内（存在泄露风险）
#   ⚠️ 推荐生产环境改为：
#        - 使用环境变量读取 PAT
#        - 或通过 Secret 管理工具注入
#   ⚠️ 切勿将本脚本提交到公共仓库
#
#
# 工作流程逻辑图：
#
#   本地代码
#        ↓
#   Git add / commit
#        ↓
#   Git Credential 注入 PAT
#        ↓
#   GitHub 远程仓库
#
#
# 本脚本特点：
#
#   ✔ 幂等性：重复执行不会破坏仓库
#   ✔ 自动处理无修改 commit 情况
#   ✔ 自动检测认证失败
#
###############################################################################

# ===============================================
# 一键安全上传 GitHub 代码脚本（PAT 安全注入 + Push）
# 使用场景：安全、跨平台，一次执行完成 PAT 配置和代码上传
# ===============================================

set -euo pipefail

# ====== 参数读取 ======
if [ $# -lt 1 ]; then
    echo "❌ 请提供要上传的目录路径"
    echo "用法: ./upload.sh <目录路径> [分支] [commit信息]"
    exit 1
fi

TARGET_DIR="$1"
BRANCH="${2:-main}"
COMMIT_MSG="${3:-自动上传代码 $(date '+%Y-%m-%d %H:%M:%S')}"

if [ ! -d "$TARGET_DIR/.git" ]; then
    echo "❌ 目录 $TARGET_DIR 不是一个 Git 仓库"
    exit 1
fi

echo "🔹 切换到目录: $TARGET_DIR"
cd "$TARGET_DIR"

# ====== 环境变量 PAT 和用户名 ======
GITLAB_USER="${GITLAB_USER:-}"
GITLAB_PAT="${GITLAB_PAT:-}"

if [[ -z "$GITLAB_USER" || -z "$GITLAB_PAT" ]]; then
    echo "❌ 请先设置环境变量 GITLAB_USER 和 GITLAB_PAT"
    exit 1
fi

REPO_URL="https://github.com/ribenit-com/Multi-Agent-System.git"

# ====== 自动选择安全凭证 helper ======
OS_TYPE=$(uname | tr '[:upper:]' '[:lower:]')
if [[ "$OS_TYPE" == "darwin" ]]; then
    CRED_HELPER="osxkeychain"
elif [[ "$OS_TYPE" == "linux" ]]; then
    CRED_HELPER="cache --timeout=3600"
elif [[ "$OS_TYPE" == "mingw"* || "$OS_TYPE" == "cygwin"* || "$OS_TYPE" == "msys"* ]]; then
    CRED_HELPER="manager-core"
else
    echo "⚠️ 未知系统，默认使用 store（明文）"
    CRED_HELPER="store"
fi

echo "🔹 使用凭证 helper: $CRED_HELPER"
git config credential.helper "$CRED_HELPER"

# ====== 更新远程 URL 带用户名 ======
echo "🔹 设置远程 URL 带用户名"
git remote set-url origin "https://${GITLAB_USER}@${REPO_URL#https://}"

# ====== 注入 PAT ======
echo "🔹 注入 PAT 到凭证缓存"
printf "protocol=https\nhost=github.com\nusername=%s\npassword=%s\n\n" "$GITLAB_USER" "$GITLAB_PAT" | git credential approve

# ====== 测试仓库访问 ======
echo "🔹 测试拉取仓库..."
if git ls-remote "$REPO_URL" &>/dev/null; then
    echo "✅ PAT 认证成功，仓库可访问"
else
    echo "❌ PAT 认证失败，请检查用户名、PAT 或权限"
    exit 1
fi

# ====== 自动提交并推送 ======
echo "🔹 添加修改并提交"
git add .

echo "🔹 提交信息: $COMMIT_MSG"
git commit -m "$COMMIT_MSG" || echo "⚠️ 没有新修改，跳过 commit"

echo "🔹 推送到远程分支: $BRANCH"
git push origin "$BRANCH"

echo "🎉 代码已成功上传到 $BRANCH 分支"

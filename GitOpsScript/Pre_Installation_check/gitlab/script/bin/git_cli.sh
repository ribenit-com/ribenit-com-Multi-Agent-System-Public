#!/bin/bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"

source "$BASE_DIR/core/git_core.sh"

if [ $# -lt 1 ]; then
    echo "用法: ./git_cli.sh <目录> [commit]"
    exit 30
fi

TARGET="$1"
COMMIT="${2:-自动提交 $(date)}"

source "$HOME/git_constants.sh"

upload_to_github \
    "$TARGET" \
    "$COMMIT" \
    "$GITLAB_USER" \
    "$GITLAB_PAT" \
    "$REPO_URL" \
    "${BRANCH:-main}"

exit $?

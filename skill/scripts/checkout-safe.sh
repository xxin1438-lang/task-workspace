#!/usr/bin/env bash
# 安全切分支：先 fetch → checkout → pull --ff-only → init 骨架
# 用法:
#   checkout-safe.sh origin/feature/AIDN-17
#   checkout-safe.sh feature/AIDN-67
#   checkout-safe.sh -b feature/AIDN-99-docs origin/feature/AIDN-99
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INIT="$SCRIPT_DIR/init-task-workspace.sh"

if [[ $# -lt 1 ]]; then
  echo "Usage: checkout-safe.sh <git-checkout-args...>" >&2
  echo "  例: checkout-safe.sh origin/test/AIDN-17" >&2
  echo "  例: checkout-safe.sh -b test/AIDN-17-docs origin/test/AIDN-17" >&2
  exit 2
fi

if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "不在 git 仓库中" >&2
  exit 1
fi

echo "==> git fetch --prune"
git fetch --prune || {
  echo "fetch 失败，中止切分支（门禁）" >&2
  exit 1
}

echo "==> git checkout $*"
if ! git checkout "$@"; then
  echo "checkout 失败。若提示 branch is already used by worktree，请用 -b <新本地名> <远程分支>。" >&2
  exit 1
fi

upstream="$(git rev-parse --abbrev-ref '@{upstream}' 2>/dev/null || true)"
if [[ -n "$upstream" ]]; then
  echo "==> git pull --ff-only ($upstream)"
  if ! git pull --ff-only; then
    echo "pull --ff-only 失败：请先处理本地与远程分歧，再跑 init，以免 tasks/ 冲突。" >&2
    exit 1
  fi
else
  echo "==> 无上游，跳过 pull"
fi

echo "==> init task workspace"
if [[ -x "$INIT" ]]; then
  # 刚 pull 过，init 可 --no-sync 避免重复；仍默认 sync 一次也无妨
  "$INIT" --no-sync || "$INIT"
else
  echo "找不到 init-task-workspace.sh" >&2
  exit 1
fi

echo "==> 完成: $(git branch --show-current)"

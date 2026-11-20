#!/usr/bin/env bash
# 安装 post-checkout / post-merge，调用 init-task-workspace.sh --hook
# 兼容 worktree：hooks 目录用 git rev-parse --git-path hooks；
# hook 正文通过 git rev-parse --show-toplevel 定位当前工作树内的脚本。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INIT_SCRIPT="$SCRIPT_DIR/init-task-workspace.sh"
MARKER="# task-workspace hook"
REL_INIT=".cursor/skills/task-workspace/scripts/init-task-workspace.sh"

if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "不在 git 仓库中" >&2
  exit 1
fi

chmod +x "$INIT_SCRIPT" || true

HOOKS_DIR="$(git rev-parse --git-path hooks)"
mkdir -p "$HOOKS_DIR"

# hook 在任意 worktree 触发时，用该 worktree 根下的脚本
HOOK_BODY=$(cat <<EOF
$MARKER
_tw_root=\$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
_tw_init="\$_tw_root/$REL_INIT"
if [ -x "\$_tw_init" ]; then
  "\$_tw_init" --hook || true
fi
# end task-workspace hook
EOF
)

install_one() {
  local name="$1"
  local path="$HOOKS_DIR/$name"

  if [[ -f "$path" ]] && grep -qF "$MARKER" "$path"; then
    echo "已存在，跳过: $path"
    return 0
  fi

  if [[ -f "$path" ]]; then
    {
      printf '%s\n' "$HOOK_BODY"
      printf '\n'
      cat "$path"
    } >"$path.task-workspace.tmp"
    mv "$path.task-workspace.tmp" "$path"
    chmod +x "$path"
    echo "已串联到现有 hook: $path"
  else
    {
      printf '%s\n' '#!/bin/sh'
      printf '%s\n' "$HOOK_BODY"
    } >"$path"
    chmod +x "$path"
    echo "已创建: $path"
  fi
}

install_one post-checkout
install_one post-merge

echo "hooks 目录: $HOOKS_DIR"
echo "完成。切到带工单号的分支时将自动补齐 tasks/<id>/。"

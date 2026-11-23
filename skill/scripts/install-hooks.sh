#!/usr/bin/env bash
# 安装 post-checkout / post-merge，调用 init-task-workspace.sh --hook
# 兼容 worktree；在项目内按 .cursor / .claude / .agents 顺序查找脚本。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INIT_SCRIPT="$SCRIPT_DIR/init-task-workspace.sh"
MARKER="# task-workspace hook"

if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "不在 git 仓库中" >&2
  exit 1
fi

chmod +x "$INIT_SCRIPT" || true

HOOKS_DIR="$(git rev-parse --git-path hooks)"
mkdir -p "$HOOKS_DIR"

# hook：优先项目内多端 skill 路径，再回退用户目录
HOOK_BODY=$(cat <<'EOF'
# task-workspace hook
_tw_root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
_tw_init=""
for _tw_rel in \
  .cursor/skills/task-workspace/scripts/init-task-workspace.sh \
  .claude/skills/task-workspace/scripts/init-task-workspace.sh \
  .agents/skills/task-workspace/scripts/init-task-workspace.sh
do
  if [ -x "$_tw_root/$_tw_rel" ]; then
    _tw_init="$_tw_root/$_tw_rel"
    break
  fi
done
if [ -z "$_tw_init" ]; then
  for _tw_home in "$HOME/.cursor" "$HOME/.claude" "$HOME/.agents"; do
    if [ -x "$_tw_home/skills/task-workspace/scripts/init-task-workspace.sh" ]; then
      _tw_init="$_tw_home/skills/task-workspace/scripts/init-task-workspace.sh"
      break
    fi
  done
fi
if [ -n "$_tw_init" ] && [ -x "$_tw_init" ]; then
  "$_tw_init" --hook || true
fi
# end task-workspace hook
EOF
)

install_one() {
  local name="$1"
  local path="$HOOKS_DIR/$name"

  if [[ -f "$path" ]] && grep -qF "$MARKER" "$path"; then
    # 已安装旧版 hook：替换为多路径版本
    {
      printf '%s\n' '#!/bin/sh'
      printf '%s\n' "$HOOK_BODY"
    } >"$path.task-workspace.tmp"
    mv "$path.task-workspace.tmp" "$path"
    chmod +x "$path"
    echo "已更新 hook: $path"
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

#!/usr/bin/env bash
# 按分支工单号在 monorepo 顶层幂等创建 tasks/<id>/ 骨架。
# Hook 调用请加 --hook（始终 exit 0）。

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATES_DIR="$SKILL_ROOT/templates"

HOOK_MODE=0
CHECK_MODE=0
SELF_TEST=0
NO_SYNC=0
TASK_ID=""
ROOT_OVERRIDE=""

LEAF_DIRS=(
  "process/grillme"
  "process/prd"
  "process/tech/frontend"
  "process/tech/backend"
  "process/tech/api"
  "process/tech/deploy"
  "process/tech/deploy/sql"
  "review"
  "handoff/docs"
  "handoff/test-cases"
  "handoff/test-cases/results"
)

# 关键正文文件（相对 task 根）；校验用
KEY_FILES=(
  "process/grillme/clarify.md"
  "process/prd/prd.md"
  "process/tech/frontend/design.md"
  "process/tech/backend/design.md"
  "process/tech/api/api.md"
  "process/tech/deploy/deploy.md"
  "handoff/docs/handoff.md"
  "handoff/test-cases/cases.md"
)

usage() {
  cat <<'EOF'
Usage: init-task-workspace.sh [--id TASK_ID] [--root PATH] [--check] [--hook] [--no-sync] [--self-test]

  --id        手动指定工单号（小写规范化）
  --root      指定 monorepo 顶层（默认自动探测）
  --check     校验骨架与关键文件，不创建
  --hook      Git hook 模式：出错也 exit 0
  --no-sync   跳过 fetch / pull（默认会同步远程，避免本地空骨架盖住远程 tasks/）
  --self-test 跑内置断言后退出
EOF
}

# 建骨架前同步远程：先拿到远程已有的 tasks/<id>/，再幂等补缺
sync_from_remote() {
  if [[ "$NO_SYNC" -eq 1 ]]; then
    return 0
  fi
  if ! git rev-parse --git-dir >/dev/null 2>&1; then
    return 0
  fi
  printf 'task-workspace: git fetch...\n' >&2
  if ! git fetch --prune 2>/dev/null; then
    log_err "task-workspace: fetch 失败（继续本地建骨架；建议先恢复网络后再切分支）"
    return 0
  fi
  local upstream
  upstream="$(git rev-parse --abbrev-ref '@{upstream}' 2>/dev/null || true)"
  if [[ -z "$upstream" ]]; then
    printf 'task-workspace: 无上游分支，跳过 pull\n' >&2
    return 0
  fi
  printf 'task-workspace: git pull --ff-only (%s)...\n' "$upstream" >&2
  if ! git pull --ff-only 2>/dev/null; then
    log_err "task-workspace: pull --ff-only 未成功（可能有本地提交/冲突）。未强行改写工作区；请先处理后再 init，以免与远程 tasks/ 冲突。"
    # hook 模式不阻断；手动模式仍继续补骨架但不覆盖已有文件
    return 0
  fi
}

log_err() { printf '%s\n' "$*" >&2; }

extract_task_id() {
  local branch="$1"
  local match
  match="$(printf '%s' "$branch" | grep -oiE '[a-z]+-[0-9]+' | head -n 1 || true)"
  if [[ -z "$match" ]]; then
    printf ''
    return 0
  fi
  printf '%s' "$match" | tr '[:upper:]' '[:lower:]'
}

find_monorepo_root() {
  if [[ -n "$ROOT_OVERRIDE" ]]; then
    printf '%s' "$ROOT_OVERRIDE"
    return 0
  fi
  local dir
  dir="$(pwd)"
  while [[ "$dir" != "/" ]]; do
    if [[ -d "$dir/java" && -d "$dir/web" ]]; then
      printf '%s' "$dir"
      return 0
    fi
    dir="$(dirname "$dir")"
  done
  if git rev-parse --show-toplevel >/dev/null 2>&1; then
    git rev-parse --show-toplevel
    return 0
  fi
  printf ''
  return 1
}

normalize_id() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]'
}

write_link_stub() {
  local dest="$1"
  local template="$2"
  if [[ -f "$dest" || ! -f "$template" ]]; then
    return 0
  fi
  sed "s/{{TASK_ID}}/${TASK_ID}/g" "$template" >"$dest"
}

ensure_skeleton() {
  local task_root="$1"
  local rel template dest
  mkdir -p "$task_root"
  for rel in "${LEAF_DIRS[@]}"; do
    mkdir -p "$task_root/$rel"
    template="$TEMPLATES_DIR/$rel/README.md"
    dest="$task_root/$rel/README.md"
    if [[ ! -f "$dest" ]]; then
      if [[ -f "$template" ]]; then
        cp "$template" "$dest"
      else
        printf '# %s\n\n（模板缺失，请补 templates）\n' "$(basename "$rel")" >"$dest"
      fi
    fi
  done
  # 部署主文档：有模板则拷为 deploy.md（不覆盖已有）
  dest="$task_root/process/tech/deploy/deploy.md"
  template="$TEMPLATES_DIR/process/tech/deploy/deploy.md.template"
  if [[ ! -f "$dest" && -f "$template" ]]; then
    cp "$template" "$dest"
  fi
  # 设计与接口只生成链接草稿，不写正文（不覆盖已有）
  write_link_stub "$task_root/process/tech/frontend/design.md" \
    "$TEMPLATES_DIR/process/tech/frontend/design.md.template"
  write_link_stub "$task_root/process/tech/backend/design.md" \
    "$TEMPLATES_DIR/process/tech/backend/design.md.template"
  write_link_stub "$task_root/process/tech/api/api.md" \
    "$TEMPLATES_DIR/process/tech/api/api.md.template"
  # 语言路由（阶段 0）；不覆盖已有
  write_link_stub "$task_root/process/stack-routing.md" \
    "$TEMPLATES_DIR/process/stack-routing.md.template"
  # 测试结果不强制预置正文；仅保证 results/ 目录存在（见 LEAF_DIRS）
}

is_readme_only_or_missing() {
  # 若关键文件不存在，或内容仍像空模板占位，则视为缺失
  local path="$1"
  if [[ ! -f "$path" ]]; then
    return 0
  fi
  return 1
}

run_check() {
  local task_root="$1"
  local missing=0
  local rel path

  printf 'Task root: %s\n' "$task_root"
  printf '\n## 目录\n'
  for rel in "${LEAF_DIRS[@]}"; do
    if [[ -d "$task_root/$rel" ]]; then
      printf '[ok] %s\n' "$rel"
    else
      printf '[MISSING] %s\n' "$rel"
      missing=1
    fi
  done

  printf '\n## 关键文件\n'
  for rel in "${KEY_FILES[@]}"; do
    path="$task_root/$rel"
    if is_readme_only_or_missing "$path"; then
      printf '[MISSING] %s\n' "$rel"
      missing=1
    else
      printf '[ok] %s\n' "$rel"
    fi
  done

  path="$task_root/process/stack-routing.md"
  printf '\n## 语言路由（缺则 warn，不阻断旧工单）\n'
  if is_readme_only_or_missing "$path"; then
    printf '[warn] process/stack-routing.md 缺失；新工单阶段 0 应填写（见 delivery-pipeline §2.1）\n'
  else
    printf '[ok] process/stack-routing.md\n'
  fi

  local handoff="$task_root/handoff/docs/handoff.md"
  printf '\n## handoff.md 最小章节\n'
  if [[ ! -f "$handoff" ]]; then
    printf '[MISSING] handoff.md 不存在\n'
    missing=1
  else
    local section
    for section in '背景' '目标' '非目标' '验收' '相关'; do
      if grep -q "$section" "$handoff"; then
        printf '[ok] 含「%s」\n' "$section"
      else
        printf '[MISSING] 未见「%s」\n' "$section"
        missing=1
      fi
    done
  fi

  return "$missing"
}

run_self_test() {
  local failed=0
  local got

  got="$(extract_task_id 'feature/aidn-17')"
  [[ "$got" == 'aidn-17' ]] || { log_err "FAIL feature/aidn-17 => [$got]"; failed=1; }

  got="$(extract_task_id 'fix/AIDN-17-login')"
  [[ "$got" == 'aidn-17' ]] || { log_err "FAIL fix/AIDN-17-login => [$got]"; failed=1; }

  got="$(extract_task_id 'xingxin/文档规范')"
  [[ -z "$got" ]] || { log_err "FAIL 无工单分支应为空 => [$got]"; failed=1; }

  got="$(normalize_id 'AIDN-99')"
  [[ "$got" == 'aidn-99' ]] || { log_err "FAIL normalize => [$got]"; failed=1; }

  if [[ "$failed" -eq 0 ]]; then
    printf 'self-test: OK\n'
    return 0
  fi
  printf 'self-test: FAILED\n' >&2
  return 1
}

finish() {
  local code="$1"
  if [[ "$HOOK_MODE" -eq 1 ]]; then
    exit 0
  fi
  exit "$code"
}

# --- parse args ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    --id)
      TASK_ID="$(normalize_id "${2:-}")"
      shift 2
      ;;
    --root)
      ROOT_OVERRIDE="${2:-}"
      shift 2
      ;;
    --check)
      CHECK_MODE=1
      shift
      ;;
    --hook)
      HOOK_MODE=1
      shift
      ;;
    --no-sync)
      NO_SYNC=1
      shift
      ;;
    --self-test)
      SELF_TEST=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      log_err "未知参数: $1"
      usage
      finish 2
      ;;
  esac
done

if [[ "$SELF_TEST" -eq 1 ]]; then
  run_self_test
  finish $?
fi

if [[ -z "$TASK_ID" ]]; then
  branch="$(git branch --show-current 2>/dev/null || true)"
  TASK_ID="$(extract_task_id "$branch")"
fi

if [[ -z "$TASK_ID" ]]; then
  if [[ "$HOOK_MODE" -eq 1 ]]; then
    finish 0
  fi
  log_err "当前分支无工单号，请传 --id <taskId>"
  finish 1
fi

root="$(find_monorepo_root)" || true
if [[ -z "$root" ]]; then
  log_err "无法定位 monorepo 根目录"
  finish 1
fi

task_root="$root/tasks/$TASK_ID"

if [[ "$CHECK_MODE" -eq 1 ]]; then
  if [[ ! -d "$task_root" ]]; then
    log_err "不存在: $task_root"
    finish 1
  fi
  run_check "$task_root"
  finish $?
fi

# 先同步远程，再补骨架（绝不覆盖已有文件）
(
  cd "$root" || exit 0
  sync_from_remote
)
ensure_skeleton "$task_root"
printf 'task-workspace ready: %s\n' "$task_root"
finish 0

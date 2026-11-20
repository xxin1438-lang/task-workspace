#!/usr/bin/env bash
# 兼容入口：委托给 npm CLI（需 Node.js >= 18）
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLI=(node "$SCRIPT_DIR/bin/task-workspace.js")

if [[ $# -eq 0 ]]; then
  exec "${CLI[@]}" install
fi

case "${1:-}" in
  install|install-project|checkout|init|check|install-hooks|help|-h|--help)
    exec "${CLI[@]}" "$@"
    ;;
  *)
    echo "未知参数: $*" >&2
    exec "${CLI[@]}" help
    ;;
esac

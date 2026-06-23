#!/usr/bin/env bash
set -euo pipefail

# Prereq: bash 4+ (mapfile を使うため。macOS デフォルトは 3.2)
if ((BASH_VERSINFO[0] < 4)); then
  echo "bash 4+ required (macOS default is 3.2 — install via: brew install bash)" >&2
  exit 2
fi

# Move to repo root (cwd 非依存にするため)
cd "$(git rev-parse --show-toplevel 2>/dev/null)" || {
  echo "Error: not in a git repository" >&2
  exit 2
}

# Prereq: jq
command -v jq >/dev/null 2>&1 || {
  echo "jq is required. Install via: brew install jq" >&2
  exit 2
}

usage() {
  cat <<EOF >&2
Usage: $(basename "$0") {sync|verify|status} [<collection>]

Commands:
  sync [<col>]    shared/ から各 collection へ取り込み
  verify [<col>]  drift 検知（drift で exit 1）
  status [<col>]  synced/drifted/missing 表示
EOF
  exit 2
}

cmd_sync()   { echo "sync not yet implemented" >&2; exit 2; }
cmd_verify() { echo "verify not yet implemented" >&2; exit 2; }
cmd_status() { echo "status not yet implemented" >&2; exit 2; }

case "${1:-}" in
  sync)   shift; cmd_sync   "${1:-}" ;;
  verify) shift; cmd_verify "${1:-}" ;;
  status) shift; cmd_status "${1:-}" ;;
  *)      usage ;;
esac

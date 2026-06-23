#!/usr/bin/env bash
set -euo pipefail

if ((BASH_VERSINFO[0] < 4)); then
  echo "bash 4+ required (macOS default is 3.2 — install via: brew install bash)" >&2
  exit 2
fi

cd "$(git rev-parse --show-toplevel 2>/dev/null)" || {
  echo "Error: not in a git repository" >&2
  exit 2
}

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

# OS 差を吸収（macOS: shasum、Linux: sha256sum）。引数なしで呼ぶと stdin を読む
if command -v sha256sum >/dev/null 2>&1; then
  _sha256() { sha256sum "$@" | awk '{print $1}'; }
else
  _sha256() { shasum -a 256 "$@" | awk '{print $1}'; }
fi

# ファイル全体の hash
file_hash() {
  echo "sha256:$(_sha256 "$1")"
}

# body 部分（closing --- 以降）の hash。手編集検知用
body_hash() {
  local h
  h=$(awk '
    BEGIN { fm = 0 }
    /^---$/ { fm++; next }
    fm >= 2 { print }
  ' "$1" | _sha256)
  echo "sha256:$h"
}

# *.claude-plugin/dependencies.json を持つ collection を発見
discover_collections() {
  for dep in */.claude-plugin/dependencies.json; do
    [ -f "$dep" ] || continue
    dirname "$(dirname "$dep")"
  done
}

# dependencies.json の shared.agents[] を読む（重複検知付き）
read_picked_agents() {
  local dep_file="$1"
  jq -e '.shared.agents | type == "array"' "$dep_file" >/dev/null 2>&1 || {
    echo "dependencies.json: shared.agents must be an array ($dep_file)" >&2
    return 2
  }
  jq -r '.shared.agents[]' "$dep_file"
}

# generated file かどうか（frontmatter に x-source 行があれば true）
is_generated() {
  local file="$1"
  [ -f "$file" ] && head -50 "$file" | grep -q '^x-source:'
}

# generated file から x-source-hash 行を取り出す
read_source_hash() {
  head -50 "$1" | awk '/^x-source-hash:/ {print $2; exit}'
}

# generated file から x-body-hash 行を取り出す（古い generated file には無い場合あり、その時は empty）
read_body_hash() {
  head -50 "$1" | awk '/^x-body-hash:/ {print $2; exit}'
}

# 1 エージェントを 1 collection に sync
sync_one() {
  local collection="$1"
  local name="$2"
  local src="shared/agents/$name.md"
  local dst="$collection/agents/$name.md"

  if [ ! -f "$src" ]; then
    echo "Unknown agent: $name (not in shared/agents/)" >&2
    return 2
  fi

  if [ -f "$dst" ] && ! is_generated "$dst"; then
    echo "Collision: $dst exists as handwritten file. Either rename it or remove from dependencies.json." >&2
    return 2
  fi

  local hash bhash now
  hash=$(file_hash "$src")
  bhash=$(body_hash "$src")
  now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  # Idempotent skip: dst の source-hash と body-hash が両方一致しているなら書き直さない
  # body-hash が一致していない場合は master always wins で上書き（手編集を検知したい場合は verify を使う）
  if [ -f "$dst" ] && is_generated "$dst"; then
    local existing_hash existing_bhash dst_bhash
    existing_hash=$(read_source_hash "$dst")
    existing_bhash=$(read_body_hash "$dst")
    dst_bhash=$(body_hash "$dst")
    if [ "$existing_hash" = "$hash" ] && [ -n "$existing_bhash" ] && [ "$existing_bhash" = "$dst_bhash" ]; then
      echo "  unchanged: $dst"
      return 0
    fi
  fi

  mkdir -p "$collection/agents"

  local tmp="$dst.tmp.$$"

  if ! awk -v src="$src" -v hash="$hash" -v bhash="$bhash" -v now="$now" '
    BEGIN { fm_state = 0 }
    NR == 1 && /^---$/ { fm_state = 1; print; next }
    fm_state == 1 && /^---$/ {
      print "x-source: " src
      print "x-source-hash: " hash
      print "x-body-hash: " bhash
      print "x-synced-at: " now
      print
      fm_state = 2
      next
    }
    fm_state == 1 && /^x-source:|^x-source-hash:|^x-body-hash:|^x-synced-at:/ { next }
    { print }
    END {
      if (fm_state != 2) exit 3
    }
  ' "$src" > "$tmp"; then
    rm -f "$tmp"
    echo "Malformed source: $src (no closing --- delimiter)" >&2
    return 2
  fi

  mv "$tmp" "$dst"

  echo "  synced: $dst"
}

cmd_sync() {
  local target="${1:-}"
  local collections=()
  if [ -n "$target" ]; then
    [ -f "$target/.claude-plugin/dependencies.json" ] || {
      echo "Error: $target/.claude-plugin/dependencies.json not found" >&2
      exit 2
    }
    collections=("$target")
  elif [ -t 0 ]; then
    # TTY 環境では interactive picker（fzf 優先 / 未インストール時は select fallback）
    # non-TTY (CI/pipe) では下の else に落ちて全 collection
    local discovered=()
    mapfile -t discovered < <(discover_collections)
    if [ "${#discovered[@]}" -eq 0 ]; then
      echo "No collections found (no */.claude-plugin/dependencies.json)" >&2
      return 0
    fi
    local options=("(all collections)" "${discovered[@]}")
    local choice=""
    if command -v fzf >/dev/null 2>&1; then
      # 矢印キー + fuzzy search。Esc/Ctrl-C で fzf が非 0 終了 → cancel として return
      choice=$(printf '%s\n' "${options[@]}" | fzf --height=40% --reverse --prompt="Sync> " --no-multi) || return 0
    else
      echo "Select collection to sync:" >&2
      local PS3="#? "
      select choice in "${options[@]}"; do
        if [ -z "$choice" ]; then
          echo "Invalid selection. Try again." >&2
          continue
        fi
        break
      done
    fi
    if [ "$choice" = "(all collections)" ]; then
      collections=("${discovered[@]}")
    else
      collections=("$choice")
    fi
  else
    mapfile -t collections < <(discover_collections)
  fi

  local collection
  for collection in "${collections[@]}"; do
    local dep="$collection/.claude-plugin/dependencies.json"
    local agents=()
    mapfile -t agents < <(read_picked_agents "$dep")

    # Duplicate check (only meaningful with at least 1 element)
    if [ "${#agents[@]}" -gt 0 ]; then
      local uniq_count
      uniq_count=$(printf "%s\n" "${agents[@]}" | sort -u | wc -l | tr -d ' ')
      if [ "$uniq_count" -ne "${#agents[@]}" ]; then
        echo "dependencies.json: duplicate agent name in $dep" >&2
        exit 2
      fi
    fi

    echo "$collection:"
    local name
    for name in "${agents[@]}"; do
      sync_one "$collection" "$name"
    done
  done
}

cmd_verify() {
  local target="${1:-}"
  local collections=()
  if [ -n "$target" ]; then
    [ -f "$target/.claude-plugin/dependencies.json" ] || {
      echo "Error: $target/.claude-plugin/dependencies.json not found" >&2
      exit 2
    }
    collections=("$target")
  else
    mapfile -t collections < <(discover_collections)
  fi

  local has_drift=0
  local collection name

  for collection in "${collections[@]}"; do
    local dep="$collection/.claude-plugin/dependencies.json"
    local agents=()
    mapfile -t agents < <(read_picked_agents "$dep")

    for name in "${agents[@]}"; do
      local dst="$collection/agents/$name.md"
      local src="shared/agents/$name.md"

      if [ ! -f "$src" ]; then
        echo "Unknown agent: $name (not in shared/agents/)" >&2
        exit 2
      fi
      if [ ! -f "$dst" ]; then
        echo "Missing: $dst" >&2
        has_drift=1
        continue
      fi
      local recorded_src current_src
      recorded_src=$(read_source_hash "$dst")
      current_src=$(file_hash "$src")
      if [ "$recorded_src" != "$current_src" ]; then
        echo "Drifted: $dst (source-hash mismatch — shared/ updated, run 'make sync')" >&2
        has_drift=1
      fi

      # Body 手編集検知（x-body-hash が無い古い generated file はスキップ、次回 sync で付与される）
      local recorded_body current_body
      recorded_body=$(read_body_hash "$dst")
      current_body=$(body_hash "$dst")
      if [ -n "$recorded_body" ] && [ "$recorded_body" != "$current_body" ]; then
        echo "Edited: $dst (body modified — revert via 'git checkout $dst' or move change to shared/)" >&2
        has_drift=1
      fi
    done
  done

  if [ "$has_drift" -eq 1 ]; then
    return 1
  fi
  echo "All synced files are up-to-date."
}
cmd_status() {
  local target="${1:-}"
  local collections=()
  if [ -n "$target" ]; then
    [ -f "$target/.claude-plugin/dependencies.json" ] || {
      echo "Error: $target/.claude-plugin/dependencies.json not found" >&2
      exit 2
    }
    collections=("$target")
  else
    mapfile -t collections < <(discover_collections)
  fi

  local collection name
  for collection in "${collections[@]}"; do
    local dep="$collection/.claude-plugin/dependencies.json"
    local agents=()
    mapfile -t agents < <(read_picked_agents "$dep")
    echo "$collection:"
    local synced=0 drifted=0 edited=0 missing=0
    for name in "${agents[@]}"; do
      local dst="$collection/agents/$name.md"
      local src="shared/agents/$name.md"
      if [ ! -f "$src" ]; then
        printf "  ? %-25s (unknown in shared/)\n" "$name"
        continue
      fi
      if [ ! -f "$dst" ]; then
        printf "  ! %-25s (missing in collection)\n" "$name"
        missing=$((missing+1))
        continue
      fi
      local recorded_src current_src recorded_body current_body
      recorded_src=$(read_source_hash "$dst")
      current_src=$(file_hash "$src")
      recorded_body=$(read_body_hash "$dst")
      current_body=$(body_hash "$dst")

      local body_edited=0
      if [ -n "$recorded_body" ] && [ "$recorded_body" != "$current_body" ]; then
        body_edited=1
      fi

      if [ "$recorded_src" != "$current_src" ]; then
        printf "  ✗ %-25s (drifted — source updated)\n" "$name"
        drifted=$((drifted+1))
      elif [ "$body_edited" -eq 1 ]; then
        printf "  ✎ %-25s (edited — body modified)\n" "$name"
        edited=$((edited+1))
      else
        printf "  ✓ %-25s (synced)\n" "$name"
        synced=$((synced+1))
      fi
    done
    echo "  Summary: $synced synced / $drifted drifted / $edited edited / $missing missing"
  done
}

case "${1:-}" in
  sync)   shift; cmd_sync   "${1:-}" ;;
  verify) shift; cmd_verify "${1:-}" ;;
  status) shift; cmd_status "${1:-}" ;;
  *)      usage ;;
esac

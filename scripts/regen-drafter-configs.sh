#!/usr/bin/env bash
# release-drafter の per-collection config を template から再生成する。
#
# 使い方:
#   scripts/regen-drafter-configs.sh           # 全 collection 再生成
#   scripts/regen-drafter-configs.sh --check   # 再生成して git diff があれば exit 1 (CI 用)
#
# 動作:
#   1. リポジトリ root の `*/.claude-plugin/plugin.json` を持つ dir を collection と判定
#   2. .github/release-drafter-template.yml の {{COLLECTION}} を各名前に sed 置換し
#      .github/release-drafter-<collection>.yml として書き出す
#   3. template 先頭に "自動生成、手編集禁止" コメントを差し込む
#
# 設計判断 (ADR-0006 を extends した形): release-drafter@v6 が config を
# default branch (= main) から API 経由で読む制約があるため、runtime sed render
# は機能しない。よって per-collection config を commit する。template + 本スクリプト
# + Makefile target + CI check で「再生成忘れ」を構造的に塞ぐ。

set -euo pipefail

cd "$(dirname "$0")/.."

TEMPLATE=".github/release-drafter-template.yml"
GENERATED_HEADER="# !!! GENERATED FILE — DO NOT EDIT !!!
# Source: $TEMPLATE
# Regenerate: make regen-drafter-configs
"

CHECK_MODE=false
if [ "${1:-}" = "--check" ]; then
  CHECK_MODE=true
fi

if [ ! -f "$TEMPLATE" ]; then
  echo "error: template not found at $TEMPLATE" >&2
  exit 1
fi

# top-level dir で .claude-plugin/plugin.json を持つもの = collection
collections=()
for dir in */; do
  d="${dir%/}"
  if [ -e "$d/.claude-plugin/plugin.json" ]; then
    collections+=("$d")
  fi
done

if [ "${#collections[@]}" -eq 0 ]; then
  echo "No collections found; pruning generated drafter configs (if any)." >&2
  # 注: ここで早期 exit してはいけない。最後の collection を消すケースで
  # stale config が残ってしまう。下の prune 処理に処理を引き継ぐ。
else
  # サニティ: collection 名は kebab-case 系のみ ([a-z0-9][a-z0-9_-]*)
  for c in "${collections[@]}"; do
    if ! [[ "$c" =~ ^[a-z0-9][a-z0-9_-]*$ ]]; then
      echo "error: invalid collection name '$c' — must match [a-z0-9][a-z0-9_-]*" >&2
      exit 2
    fi
  done
fi

# 既存の per-collection config を全削除 (古い collection の残骸防止)
# template と collection に対応するものだけが残るようにする
shopt -s nullglob
for f in .github/release-drafter-*.yml; do
  # template 自体は残す
  if [ "$f" = "$TEMPLATE" ]; then
    continue
  fi
  # collection 名抽出: .github/release-drafter-<name>.yml の <name>
  name=$(printf '%s\n' "$f" | sed -nE 's|^\.github/release-drafter-(.+)\.yml$|\1|p')
  if [ -z "$name" ]; then
    continue
  fi
  # 現在の collection 一覧に該当しなければ削除
  match=false
  for c in "${collections[@]}"; do
    if [ "$c" = "$name" ]; then
      match=true
      break
    fi
  done
  if ! $match; then
    rm -f "$f"
    echo "removed stale: $f"
  fi
done
shopt -u nullglob

# template から各 collection の config を生成
for c in "${collections[@]}"; do
  out=".github/release-drafter-$c.yml"
  {
    printf '%s' "$GENERATED_HEADER"
    sed "s|{{COLLECTION}}|$c|g" "$TEMPLATE"
  } > "$out"
  echo "generated: $out"
done

if $CHECK_MODE; then
  # CI モード: git で差分があれば fail
  # 注: glob は shell ではなく git に展開させる (quote する)。shell 側で展開すると
  # 削除された tracked file (= stale config の prune) が pathspec から落ちて
  # 削除差分を検知できないバグになる。
  if ! git diff --quiet --exit-code -- '.github/release-drafter-*.yml' 2>/dev/null; then
    echo ""
    echo "ERROR: drafter configs are out of sync with template / collections" >&2
    echo "Run 'make regen-drafter-configs' and commit the result." >&2
    echo ""
    git diff -- '.github/release-drafter-*.yml' >&2 || true
    exit 1
  fi
  if [ -n "$(git ls-files --others --exclude-standard -- '.github/release-drafter-*.yml' 2>/dev/null)" ]; then
    echo ""
    echo "ERROR: untracked drafter configs detected (new collection without committed config?)" >&2
    git ls-files --others --exclude-standard -- '.github/release-drafter-*.yml' >&2 || true
    exit 1
  fi
  echo ""
  echo "OK: drafter configs in sync"
fi

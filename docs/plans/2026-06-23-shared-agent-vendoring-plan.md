# shared-agent-vendoring Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** indie-studio から engineering 系 13 エージェントを `shared/agents/` に切り出し、`dependencies.json` 駆動の sync スクリプトで各 collection に generated file として展開する vendoring system を構築する。

**Architecture:** 真実源は `shared/agents/`。各 collection は `<collection>/.claude-plugin/dependencies.json` で pick 宣言。`scripts/sync-shared.sh`（bash + jq）が generated file（frontmatter に `x-source` / `x-source-hash` / `x-synced-at` を埋め込み）を `<collection>/agents/` に書き出す。`make sync` / `make verify` / `make status` が統一窓口。CI で drift を機械的に検知。

**Tech Stack:** bash 4+ / jq / GNU Make / GitHub Actions (ubuntu-latest)

## Global Constraints

- **Spec の真実源**：[docs/specs/2026-06-23-shared-agent-vendoring-design.md](../specs/2026-06-23-shared-agent-vendoring-design.md)。実装上の判断はここを参照
- **ADR-0004**：[docs/adr/0004-shared-agent-vendoring.md](../adr/0004-shared-agent-vendoring.md) の決定を前提とする
- **依存ツール**：bash + jq + git + make のみ。他言語 runtime は導入しない
- **cwd 非依存**：scripts は `cd "$(git rev-parse --show-toplevel)"` で内部的に repo root に移動
- **履歴保全**：エージェント移動は必ず `git mv`（`git log --follow` で追跡可能にする）
- **Conventional Commits**：`feat:` / `docs:` / `chore:` 等のプレフィックス。既存履歴と整合
- **頻繁なコミット**：各 Task の末尾で 1 コミット。ブランチは `feat/shared-agent-vendoring`（作成済み）
- **frontmatter 形式**：generated file は元 frontmatter を順序含めて保持し、closing `---` の直前に `x-source` / `x-source-hash` / `x-synced-at` の 3 行を追加。`x-source-hash` は `sha256:<hex lowercase>` 形式。`x-synced-at` は ISO 8601 UTC（秒精度）
- **shared に上げる 13 エージェント**：backend-engineer / frontend-engineer / mobile-engineer / infrastructure-engineer / performance-engineer / qa-engineer / code-reviewer / reviewer / security-engineer / principal-engineer / software-architect / tech-lead / engineering-manager
- **indie-studio に残す 5 エージェント**：business-strategist / product-manager / product-designer / visual-designer / ux-researcher

---

## Task 1: shared/agents/ を作成し、13 エージェントを git mv で移動

**Files:**
- Create: `shared/agents/` (新規ディレクトリ)
- Move: `indie-studio/agents/backend-engineer.md` → `shared/agents/backend-engineer.md`
- Move: `indie-studio/agents/code-reviewer.md` → `shared/agents/code-reviewer.md`
- Move: `indie-studio/agents/engineering-manager.md` → `shared/agents/engineering-manager.md`
- Move: `indie-studio/agents/frontend-engineer.md` → `shared/agents/frontend-engineer.md`
- Move: `indie-studio/agents/infrastructure-engineer.md` → `shared/agents/infrastructure-engineer.md`
- Move: `indie-studio/agents/mobile-engineer.md` → `shared/agents/mobile-engineer.md`
- Move: `indie-studio/agents/performance-engineer.md` → `shared/agents/performance-engineer.md`
- Move: `indie-studio/agents/principal-engineer.md` → `shared/agents/principal-engineer.md`
- Move: `indie-studio/agents/qa-engineer.md` → `shared/agents/qa-engineer.md`
- Move: `indie-studio/agents/reviewer.md` → `shared/agents/reviewer.md`
- Move: `indie-studio/agents/security-engineer.md` → `shared/agents/security-engineer.md`
- Move: `indie-studio/agents/software-architect.md` → `shared/agents/software-architect.md`
- Move: `indie-studio/agents/tech-lead.md` → `shared/agents/tech-lead.md`

**Interfaces:**
- Consumes: 既存の indie-studio/agents/*.md（18 ファイル）
- Produces: `shared/agents/*.md`（13 ファイル、frontmatter は無加工）、indie-studio/agents/*.md は 5 ファイルに減る

- [ ] **Step 1: shared/agents/ ディレクトリを作成**

```bash
mkdir -p shared/agents
```

- [ ] **Step 2: 13 エージェントを git mv で移動**

```bash
for name in backend-engineer code-reviewer engineering-manager \
            frontend-engineer infrastructure-engineer mobile-engineer \
            performance-engineer principal-engineer qa-engineer \
            reviewer security-engineer software-architect tech-lead; do
  git mv "indie-studio/agents/$name.md" "shared/agents/$name.md"
done
```

- [ ] **Step 3: 移動後の状態を確認**

```bash
ls shared/agents/ | wc -l   # 期待値: 13
ls indie-studio/agents/     # 期待値: 5 ファイル（business-strategist, product-manager, product-designer, visual-designer, ux-researcher）
```

- [ ] **Step 4: git log --follow で履歴保全を確認**

```bash
git log --follow --oneline shared/agents/backend-engineer.md | head -5
```

期待出力：移動前の indie-studio/agents/backend-engineer.md 時代のコミット履歴が表示される。

- [ ] **Step 5: コミット**

```bash
git add -A shared/ indie-studio/
git commit -m "$(cat <<'EOF'
refactor: 共有エージェント 13 件を shared/agents/ に切り出し

ADR-0004 / docs/specs/2026-06-23-shared-agent-vendoring-design.md に基づき、
indie-studio から engineering 系 13 エージェントを shared/agents/ へ git mv。
indie-studio に残るのは Product/Design/Discovery 系 5 エージェント
（business-strategist / product-manager / product-designer /
visual-designer / ux-researcher）。

この時点では sync 機構未実装のため、indie-studio/agents/ に 13 件が
存在しない状態が一時的に発生する。続く Task で sync スクリプトを
実装し、generated file として復元する。
EOF
)"
```

---

## Task 2: scripts/sync-shared.sh のスケルトン作成

**Files:**
- Create: `scripts/sync-shared.sh`

**Interfaces:**
- Consumes: 引数（subcommand + optional collection）
- Produces: 起動時の prereq チェック（jq 存在）、usage 表示、subcommand dispatcher（実体は次タスク以降で実装）

- [ ] **Step 1: scripts/ ディレクトリを作成**

```bash
mkdir -p scripts
```

- [ ] **Step 2: sync-shared.sh のスケルトンを書く**

`scripts/sync-shared.sh` を以下の内容で作成：

```bash
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
```

- [ ] **Step 3: 実行権限を付与**

```bash
chmod +x scripts/sync-shared.sh
```

- [ ] **Step 4: 引数なし → usage 表示 + exit 2 を確認**

```bash
./scripts/sync-shared.sh; echo "exit=$?"
```

期待出力：
```
Usage: sync-shared.sh {sync|verify|status} [<collection>]

Commands:
  sync [<col>]    shared/ から各 collection へ取り込み
  verify [<col>]  drift 検知（drift で exit 1）
  status [<col>]  synced/drifted/missing 表示
exit=2
```

- [ ] **Step 5: 引数 `sync` → placeholder error を確認**

```bash
./scripts/sync-shared.sh sync; echo "exit=$?"
```

期待出力：
```
sync not yet implemented
exit=2
```

- [ ] **Step 6: cwd 非依存を確認**

```bash
(cd /tmp && /Users/goto/ghq/github.com/gotomts/claude-collections/scripts/sync-shared.sh); echo "exit=$?"
```

期待出力：usage が表示される（cwd が異なってもエラーにならない）。

- [ ] **Step 7: コミット**

```bash
git add scripts/sync-shared.sh
git commit -m "$(cat <<'EOF'
feat(scripts): sync-shared.sh のスケルトンを追加

cwd 非依存（git rev-parse でリポジトリ root に移動）、jq prereq チェック、
usage 表示、subcommand dispatcher を実装。実体は後続 Task で。
EOF
)"
```

---

## Task 3: sync subcommand 実装（helper 関数 + sync 本体）

**Files:**
- Modify: `scripts/sync-shared.sh`

**Interfaces:**
- Consumes: `<collection>/.claude-plugin/dependencies.json`（`shared.agents[]` を読む）、`shared/agents/<name>.md`
- Produces: `<collection>/agents/<name>.md`（generated file、frontmatter に `x-source` / `x-source-hash` / `x-synced-at` を merge）。標準出力に "synced: <path>" を 1 行ずつ

- [ ] **Step 1: failing test として、indie-studio にダミー dependencies.json を仮置きして sync を試す**

まずは Task 1 後の状態を確認：

```bash
ls indie-studio/.claude-plugin/  # 期待: plugin.json のみ
ls indie-studio/agents/          # 期待: 5 ファイル
```

`indie-studio/.claude-plugin/dependencies.json` を仮置き（後続 Task 7 で正式版に上書き）：

```bash
cat > indie-studio/.claude-plugin/dependencies.json <<'EOF'
{
  "shared": {
    "agents": ["backend-engineer"]
  }
}
EOF
```

現状で sync は placeholder なので：

```bash
./scripts/sync-shared.sh sync indie-studio; echo "exit=$?"
```

期待出力：
```
sync not yet implemented
exit=2
```

- [ ] **Step 2: scripts/sync-shared.sh の helper 関数とコマンド本体を実装**

`scripts/sync-shared.sh` を以下の内容で**完全に置き換え**る：

```bash
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

# OS 差を吸収（macOS: shasum、Linux: sha256sum）
if command -v sha256sum >/dev/null 2>&1; then
  _sha256() { sha256sum "$1" | awk '{print $1}'; }
else
  _sha256() { shasum -a 256 "$1" | awk '{print $1}'; }
fi

file_hash() {
  echo "sha256:$(_sha256 "$1")"
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

  local hash now
  hash=$(file_hash "$src")
  now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  mkdir -p "$collection/agents"

  # frontmatter parse: 元の x-source/x-source-hash/x-synced-at は削ぎ落として再注入
  awk -v src="$src" -v hash="$hash" -v now="$now" '
    BEGIN { fm_state = 0 }
    NR == 1 && /^---$/ { fm_state = 1; print; next }
    fm_state == 1 && /^---$/ {
      print "x-source: " src
      print "x-source-hash: " hash
      print "x-synced-at: " now
      print
      fm_state = 2
      next
    }
    fm_state == 1 && /^x-source:|^x-source-hash:|^x-synced-at:/ { next }
    { print }
  ' "$src" > "$dst"

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
  else
    mapfile -t collections < <(discover_collections)
  fi

  local collection
  for collection in "${collections[@]}"; do
    local dep="$collection/.claude-plugin/dependencies.json"
    local agents=()
    mapfile -t agents < <(read_picked_agents "$dep")

    # 重複検知
    local uniq_count
    uniq_count=$(printf "%s\n" "${agents[@]}" | sort -u | wc -l | tr -d ' ')
    if [ "$uniq_count" -ne "${#agents[@]}" ]; then
      echo "dependencies.json: duplicate agent name in $dep" >&2
      exit 2
    fi

    echo "$collection:"
    local name
    for name in "${agents[@]}"; do
      sync_one "$collection" "$name"
    done
  done
}

cmd_verify() { echo "verify not yet implemented" >&2; exit 2; }
cmd_status() { echo "status not yet implemented" >&2; exit 2; }

case "${1:-}" in
  sync)   shift; cmd_sync   "${1:-}" ;;
  verify) shift; cmd_verify "${1:-}" ;;
  status) shift; cmd_status "${1:-}" ;;
  *)      usage ;;
esac
```

- [ ] **Step 3: sync を実行して indie-studio/agents/backend-engineer.md が生成されることを確認**

```bash
./scripts/sync-shared.sh sync indie-studio; echo "exit=$?"
ls indie-studio/agents/backend-engineer.md
head -15 indie-studio/agents/backend-engineer.md
```

期待出力（順に）：
```
indie-studio:
  synced: indie-studio/agents/backend-engineer.md
exit=0
indie-studio/agents/backend-engineer.md
---
（元 frontmatter の各行）
...
x-source: shared/agents/backend-engineer.md
x-source-hash: sha256:<64文字の hex>
x-synced-at: 2026-06-23T...Z
---
```

- [ ] **Step 4: 存在しない agent name → error を確認**

```bash
cat > indie-studio/.claude-plugin/dependencies.json <<'EOF'
{
  "shared": {
    "agents": ["nonexistent-agent"]
  }
}
EOF

./scripts/sync-shared.sh sync indie-studio; echo "exit=$?"
```

期待出力：
```
indie-studio:
Unknown agent: nonexistent-agent (not in shared/agents/)
exit=2
```

- [ ] **Step 5: 衝突検知 → error を確認**

```bash
# まず正常なケースに戻す
cat > indie-studio/.claude-plugin/dependencies.json <<'EOF'
{
  "shared": {
    "agents": ["backend-engineer"]
  }
}
EOF

# 手書きファイルを仕込む（x-source を持たない）
cat > indie-studio/agents/backend-engineer.md <<'EOF'
---
name: backend-engineer
description: HANDWRITTEN
---
本文。
EOF

./scripts/sync-shared.sh sync indie-studio; echo "exit=$?"
```

期待出力：
```
indie-studio:
Collision: indie-studio/agents/backend-engineer.md exists as handwritten file. Either rename it or remove from dependencies.json.
exit=2
```

- [ ] **Step 6: 重複検知 → error を確認**

```bash
cat > indie-studio/.claude-plugin/dependencies.json <<'EOF'
{
  "shared": {
    "agents": ["backend-engineer", "backend-engineer"]
  }
}
EOF

# 衝突するファイルを削除
rm -f indie-studio/agents/backend-engineer.md

./scripts/sync-shared.sh sync indie-studio; echo "exit=$?"
```

期待出力：
```
dependencies.json: duplicate agent name in indie-studio/.claude-plugin/dependencies.json
exit=2
```

- [ ] **Step 7: dummy dependencies.json と生成物をクリーンアップして commit**

```bash
rm -f indie-studio/.claude-plugin/dependencies.json
rm -f indie-studio/agents/backend-engineer.md

git status
# 期待: scripts/sync-shared.sh のみ modified（dependencies.json と backend-engineer.md は元から無い）
```

```bash
git add scripts/sync-shared.sh
git commit -m "$(cat <<'EOF'
feat(scripts): sync subcommand を実装

dependencies.json の shared.agents[] を読み、各 agent について
shared/agents/<name>.md から <collection>/agents/<name>.md へ
generated file を書き出す。元 frontmatter を保持し、x-source /
x-source-hash / x-synced-at の 3 行を末尾に注入。

エラー検知：
- shared/agents/ に存在しない agent name → exit 2
- 同名の手書きファイル衝突 → exit 2
- shared.agents[] の重複 → exit 2
EOF
)"
```

---

## Task 4: verify subcommand 実装

**Files:**
- Modify: `scripts/sync-shared.sh`

**Interfaces:**
- Consumes: `<collection>/.claude-plugin/dependencies.json`、`<collection>/agents/<name>.md` の frontmatter（`x-source-hash`）、`shared/agents/<name>.md`
- Produces: 全一致 → exit 0、drift / missing 1 件でも検知 → exit 1。標準エラーに "Drifted: ..." / "Missing: ..." を出力

- [ ] **Step 1: failing test として、現状で verify を試す**

```bash
./scripts/sync-shared.sh verify; echo "exit=$?"
```

期待出力：
```
verify not yet implemented
exit=2
```

- [ ] **Step 2: cmd_verify を実装**

`scripts/sync-shared.sh` 内の `cmd_verify()` の 1 行 placeholder を以下に置き換え：

```bash
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
      local recorded current
      recorded=$(read_source_hash "$dst")
      current=$(file_hash "$src")
      if [ "$recorded" != "$current" ]; then
        echo "Drifted: $dst (source-hash mismatch)" >&2
        has_drift=1
      fi
    done
  done

  if [ "$has_drift" -eq 1 ]; then
    return 1
  fi
  echo "All synced files are up-to-date."
}
```

- [ ] **Step 3: 検証用に dependencies.json + sync 済みファイルを用意**

```bash
cat > indie-studio/.claude-plugin/dependencies.json <<'EOF'
{
  "shared": {
    "agents": ["backend-engineer"]
  }
}
EOF

./scripts/sync-shared.sh sync indie-studio
```

- [ ] **Step 4: verify が exit 0 になることを確認**

```bash
./scripts/sync-shared.sh verify indie-studio; echo "exit=$?"
```

期待出力：
```
All synced files are up-to-date.
exit=0
```

- [ ] **Step 5: shared/agents/ を編集して drift を仕込み、verify が exit 1 になることを確認**

```bash
# shared 側を編集（末尾に空行追加）
echo "" >> shared/agents/backend-engineer.md

./scripts/sync-shared.sh verify indie-studio; echo "exit=$?"
```

期待出力：
```
Drifted: indie-studio/agents/backend-engineer.md (source-hash mismatch)
exit=1
```

- [ ] **Step 6: shared 側の編集を revert、missing シナリオを試す**

```bash
git checkout shared/agents/backend-engineer.md
rm indie-studio/agents/backend-engineer.md

./scripts/sync-shared.sh verify indie-studio; echo "exit=$?"
```

期待出力：
```
Missing: indie-studio/agents/backend-engineer.md
exit=1
```

- [ ] **Step 7: クリーンアップして commit**

```bash
rm -f indie-studio/.claude-plugin/dependencies.json

git status
# 期待: scripts/sync-shared.sh のみ modified
```

```bash
git add scripts/sync-shared.sh
git commit -m "$(cat <<'EOF'
feat(scripts): verify subcommand を実装

各 collection の generated file の frontmatter から x-source-hash を読み、
現在の shared/agents/ の hash と比較。不一致なら "Drifted"、generated file
不存在なら "Missing" を出力し exit 1。全一致なら exit 0。

CI workflow から make verify 経由で呼ばれる主検知ルート。
EOF
)"
```

---

## Task 5: status subcommand 実装

**Files:**
- Modify: `scripts/sync-shared.sh`

**Interfaces:**
- Consumes: verify と同じ入力
- Produces: 標準出力に collection × agent の状態テーブル、Summary 行。exit 0 固定

- [ ] **Step 1: failing test として、現状で status を試す**

```bash
./scripts/sync-shared.sh status; echo "exit=$?"
```

期待出力：
```
status not yet implemented
exit=2
```

- [ ] **Step 2: cmd_status を実装**

`scripts/sync-shared.sh` 内の `cmd_status()` の 1 行 placeholder を以下に置き換え：

```bash
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
    local synced=0 drifted=0 missing=0
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
      local recorded current
      recorded=$(read_source_hash "$dst")
      current=$(file_hash "$src")
      if [ "$recorded" = "$current" ]; then
        printf "  ✓ %-25s (synced)\n" "$name"
        synced=$((synced+1))
      else
        printf "  ✗ %-25s (drifted — source updated)\n" "$name"
        drifted=$((drifted+1))
      fi
    done
    echo "  Summary: $synced synced / $drifted drifted / $missing missing"
  done
}
```

- [ ] **Step 3: 検証用に dependencies.json + sync 済みファイルを用意**

```bash
cat > indie-studio/.claude-plugin/dependencies.json <<'EOF'
{
  "shared": {
    "agents": ["backend-engineer", "code-reviewer"]
  }
}
EOF

./scripts/sync-shared.sh sync indie-studio
```

- [ ] **Step 4: status が synced 2 件を表示することを確認**

```bash
./scripts/sync-shared.sh status indie-studio; echo "exit=$?"
```

期待出力：
```
indie-studio:
  ✓ backend-engineer          (synced)
  ✓ code-reviewer             (synced)
  Summary: 2 synced / 0 drifted / 0 missing
exit=0
```

- [ ] **Step 5: drift を仕込み、status が drifted を表示することを確認**

```bash
echo "" >> shared/agents/backend-engineer.md

./scripts/sync-shared.sh status indie-studio; echo "exit=$?"
```

期待出力：
```
indie-studio:
  ✗ backend-engineer          (drifted — source updated)
  ✓ code-reviewer             (synced)
  Summary: 1 synced / 1 drifted / 0 missing
exit=0
```

- [ ] **Step 6: クリーンアップして commit**

```bash
git checkout shared/agents/backend-engineer.md
rm -f indie-studio/agents/backend-engineer.md
rm -f indie-studio/agents/code-reviewer.md
rm -f indie-studio/.claude-plugin/dependencies.json

git status
# 期待: scripts/sync-shared.sh のみ modified
```

```bash
git add scripts/sync-shared.sh
git commit -m "$(cat <<'EOF'
feat(scripts): status subcommand を実装

verify と同じチェックを行うが exit 0 固定。各 collection × agent の状態
（synced / drifted / missing / unknown）と Summary を整形して標準出力に
表示する。日常的な確認や debug 用途。
EOF
)"
```

---

## Task 6: Makefile を作成

**Files:**
- Create: `Makefile` (repo root)

**Interfaces:**
- Consumes: `scripts/sync-shared.sh`
- Produces: `make help` / `make sync` / `make verify` / `make status` の 4 target

- [ ] **Step 1: failing test として、make が見つからないことを確認**

```bash
make help 2>&1 | head -5
```

期待出力：`make: *** No rule to make target 'help'. Stop.`（または `No targets specified and no makefile found.`）

- [ ] **Step 2: Makefile を作成**

`Makefile` を repo root に作成：

```makefile
.PHONY: help sync verify status

help:  ## 利用可能な target を表示
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

sync:  ## shared から各 collection へ取り込み (COLLECTION=name で指定可)
	@./scripts/sync-shared.sh sync $(COLLECTION)

verify:  ## drift 検知 (CI 用、drift で exit 1)
	@./scripts/sync-shared.sh verify $(COLLECTION)

status:  ## synced/drifted/missing の状態表示
	@./scripts/sync-shared.sh status $(COLLECTION)
```

**注意：** Makefile では `target:` の前に**スペースではなく Tab** が必要。indent は厳密に Tab を使うこと。

- [ ] **Step 3: make help で 4 target が表示されることを確認**

```bash
make help
```

期待出力（順序は環境差あり）：
```
  help            利用可能な target を表示
  sync            shared から各 collection へ取り込み (COLLECTION=name で指定可)
  verify          drift 検知 (CI 用、drift で exit 1)
  status          synced/drifted/missing の状態表示
```

- [ ] **Step 4: make sync（dependencies.json なし）で no-op になることを確認**

```bash
make sync; echo "exit=$?"
```

期待出力：
```
exit=0
```

（dependencies.json を持つ collection が無いので何も sync されない）

- [ ] **Step 5: 不正 target で error を確認**

```bash
make nonexistent 2>&1 | head -3
```

期待出力：`make: *** No rule to make target 'nonexistent'. Stop.`

- [ ] **Step 6: コミット**

```bash
git add Makefile
git commit -m "$(cat <<'EOF'
feat: Makefile を統一窓口として追加

make help / sync / verify / status の 4 target。
scripts/sync-shared.sh の thin wrapper。COLLECTION=name で対象指定可。
EOF
)"
```

---

## Task 7: indie-studio に dependencies.json を追加し、初回 sync を実行

**Files:**
- Create: `indie-studio/.claude-plugin/dependencies.json`
- Create (via sync): `indie-studio/agents/backend-engineer.md` 他 12 ファイル（generated）

**Interfaces:**
- Consumes: `shared/agents/*.md` × 13、新規 dependencies.json
- Produces: indie-studio/agents/ に 13 件の generated file（frontmatter に x-* を持つ）+ 既存の 5 件の手書き、合計 18 件

- [ ] **Step 1: dependencies.json を作成**

`indie-studio/.claude-plugin/dependencies.json` を作成：

```json
{
  "shared": {
    "agents": [
      "backend-engineer",
      "code-reviewer",
      "engineering-manager",
      "frontend-engineer",
      "infrastructure-engineer",
      "mobile-engineer",
      "performance-engineer",
      "principal-engineer",
      "qa-engineer",
      "reviewer",
      "security-engineer",
      "software-architect",
      "tech-lead"
    ]
  }
}
```

- [ ] **Step 2: make sync で 13 件を取り込み**

```bash
make sync COLLECTION=indie-studio
```

期待出力：
```
indie-studio:
  synced: indie-studio/agents/backend-engineer.md
  synced: indie-studio/agents/code-reviewer.md
  synced: indie-studio/agents/engineering-manager.md
  synced: indie-studio/agents/frontend-engineer.md
  synced: indie-studio/agents/infrastructure-engineer.md
  synced: indie-studio/agents/mobile-engineer.md
  synced: indie-studio/agents/performance-engineer.md
  synced: indie-studio/agents/principal-engineer.md
  synced: indie-studio/agents/qa-engineer.md
  synced: indie-studio/agents/reviewer.md
  synced: indie-studio/agents/security-engineer.md
  synced: indie-studio/agents/software-architect.md
  synced: indie-studio/agents/tech-lead.md
```

- [ ] **Step 3: indie-studio/agents/ が 18 件になることを確認**

```bash
ls indie-studio/agents/ | wc -l   # 期待: 18
ls indie-studio/agents/
```

期待：13 件の generated（backend-engineer 他）+ 5 件の手書き（business-strategist 他）。

- [ ] **Step 4: 任意の generated file の frontmatter を確認**

```bash
head -15 indie-studio/agents/backend-engineer.md | tail -10
```

期待出力：
```
（元 frontmatter の最終行付近）
x-source: shared/agents/backend-engineer.md
x-source-hash: sha256:<64文字 hex>
x-synced-at: 2026-06-23T...Z
---
```

- [ ] **Step 5: make verify で drift がないことを確認**

```bash
make verify; echo "exit=$?"
```

期待出力：
```
All synced files are up-to-date.
exit=0
```

- [ ] **Step 6: make status で 13 synced を確認**

```bash
make status COLLECTION=indie-studio
```

期待出力：
```
indie-studio:
  ✓ backend-engineer          (synced)
  ✓ code-reviewer             (synced)
  ...（13 行）
  Summary: 13 synced / 0 drifted / 0 missing
```

- [ ] **Step 7: Claude Code から generated agent を 1 つ起動して動作確認**

実機検証（spec Section 12 の前提）：

別ターミナルまたは別 Claude Code セッションで、indie-studio コレクションを load した状態で `Task` tool に `subagent_type="backend-engineer"` を指定して簡単なタスクを投げる。

- 期待：未知 frontmatter（x-source 等）を Claude Code agent loader が**無視**し、agent が正常起動する
- 失敗時：本 plan を中断し、spec Section 10.3「失敗時の fallback」に従い、ADR-0004 を extends する形で別 ADR を起こし、`description` 末尾に metadata を埋める方式に切り替え

このステップは subagent ではなく **user 自身が実機で確認**するため、subagent-driven 実行時もここで一旦停止して確認をもらう。

- [ ] **Step 8: コミット**

```bash
git add indie-studio/.claude-plugin/dependencies.json indie-studio/agents/
git commit -m "$(cat <<'EOF'
feat(indie-studio): dependencies.json 追加と初回 sync 実行

shared/agents/ から engineering 系 13 エージェントを pick して取り込み。
indie-studio/agents/ は 18 件構成（13 generated + 5 手書き）に。

generated file は frontmatter に x-source / x-source-hash / x-synced-at を
持ち、shared 側との drift が make verify で機械的に検知できる状態。
EOF
)"
```

---

## Task 8: CI workflow を追加

**Files:**
- Create: `.github/workflows/verify-shared.yml`

**Interfaces:**
- Consumes: PR diff、`Makefile`、`scripts/sync-shared.sh`
- Produces: PR check「verify-shared」。drift 検知時は status failure で PR ブロック

- [ ] **Step 1: failing test として、現状の workflow ディレクトリを確認**

```bash
ls .github/workflows/ 2>/dev/null || echo "no workflows yet"
```

期待出力：`no workflows yet`（または既存があれば一覧）

- [ ] **Step 2: .github/workflows/ ディレクトリと yml を作成**

```bash
mkdir -p .github/workflows
```

`.github/workflows/verify-shared.yml` を以下の内容で作成：

```yaml
name: verify-shared
on:
  pull_request:
    paths:
      - 'shared/**'
      - '**/dependencies.json'
      - '**/agents/**'
      - 'scripts/sync-shared.sh'
      - 'Makefile'
      - '.github/workflows/verify-shared.yml'

jobs:
  verify:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install jq
        run: sudo apt-get update && sudo apt-get install -y jq
      - name: Verify shared sync
        run: make verify
```

- [ ] **Step 3: yaml 構文をローカルで確認**

```bash
# 既に Python があれば（macOS デフォルト）：
python3 -c "import yaml; yaml.safe_load(open('.github/workflows/verify-shared.yml'))" && echo "valid yaml"
```

期待出力：`valid yaml`

- [ ] **Step 4: コミット**

```bash
git add .github/workflows/verify-shared.yml
git commit -m "$(cat <<'EOF'
ci: shared/ への drift を PR で検知する verify-shared workflow を追加

shared/、dependencies.json、agents/、sync-shared.sh、Makefile の変更を
含む PR で発火。make verify を実行し、drift 検知時は exit 1 で PR を
ブロックする。
EOF
)"
```

(注: 本 workflow が実際に走るのは PR を作成した時。本 plan の Task 内では実行検証できない。後続の PR 作成時に GitHub Actions の実行結果で確認する)

---

## Task 9: AGENTS.md / CONTEXT-MAP.md / README.md を更新

**Files:**
- Modify: `AGENTS.md`
- Modify: `CONTEXT-MAP.md`
- Modify: `README.md`

**Interfaces:**
- Consumes: 確定した vendoring 規律（ADR-0004、本 plan の前 Task 群）
- Produces: 開発者向けドキュメントが新規律を反映している状態

- [ ] **Step 1: AGENTS.md の現状を確認**

```bash
cat AGENTS.md
```

- [ ] **Step 2: AGENTS.md に shared/ と vendoring 規律のセクションを追加**

AGENTS.md の **`## スキル/エージェントを足す・直すとき`** セクション（既存）の**直後**に、以下のセクションを挿入：

```markdown
## shared/ の共有エージェント

- engineering 系（executor / quality / leadership）の共通エージェントは `shared/agents/` を真実源とする（ADR-0004）。
- 各コレクションは `<collection>/.claude-plugin/dependencies.json` の `shared.agents[]` で取り込み宣言する。
- 取り込みの実体化は `make sync`（または `make sync COLLECTION=<name>`）。`<collection>/agents/<name>.md` に generated file が書き出される（frontmatter に `x-source` / `x-source-hash` / `x-synced-at` を持つ）。
- generated file は **手編集禁止**。shared 側を編集して `make sync` で反映させる。
- `make verify` で drift を機械的に検知（CI も実行）。手元での確認は `make status`。
- shared/agents/ の編集 PR では、影響を受ける全 collection の generated を `make sync` で更新してから commit する。CI verify が忘れを構造的に防ぐ。
- コレクション固有のエージェント（例：indie-studio の business-strategist 等）は従来通り `<collection>/agents/` に手書きで置く。shared/ と同名にしないこと。
```

- [ ] **Step 3: CONTEXT-MAP.md の現状を確認**

```bash
cat CONTEXT-MAP.md
```

- [ ] **Step 4: CONTEXT-MAP.md に shared/ の記載を追加**

CONTEXT-MAP.md のコレクション一覧の**直後**（または末尾）に、以下のセクションを追加：

```markdown
## shared/

- 真実源として `shared/agents/` を持つ。コレクションではなく **vendoring の元データ**（ADR-0004）。
- 各コレクションが `dependencies.json` で pick し、`make sync` で `<collection>/agents/` に generated file として展開される。
- 現状の中身：engineering 系 13 エージェント（executor 5 + quality 4 + leadership 4）。
- 配布対象外（marketplace.json には列挙しない）。install 先には流れない。
```

- [ ] **Step 5: README.md の現状を確認**

```bash
cat README.md
```

- [ ] **Step 6: README.md に「新コレクション追加時の手順」を追加**

README.md の末尾、または既存の「コレクションを足す」系セクションがあればその近くに、以下を追加：

```markdown
## 新しいコレクションを追加するとき

1. `<collection>/` 配下に `skills/` / `agents/` / `docs/adr/` / `CONTEXT.md` / `ROADMAP.md` / `.claude-plugin/plugin.json` を作る（ADR-0001 の構造）
2. shared/agents/ のエージェントを使う場合は `<collection>/.claude-plugin/dependencies.json` を作り、`shared.agents[]` に basename を列挙する
3. `make sync COLLECTION=<collection>` を実行して generated file を反映
4. `make verify` で drift がないことを確認
5. root の `marketplace.json` に新 plugin を 1 entry 追加
6. `CONTEXT-MAP.md` にコレクションの所在と概要を追記
```

- [ ] **Step 7: 変更をまとめて確認**

```bash
git diff AGENTS.md CONTEXT-MAP.md README.md | head -100
```

- [ ] **Step 8: コミット**

```bash
git add AGENTS.md CONTEXT-MAP.md README.md
git commit -m "$(cat <<'EOF'
docs: shared/ と vendoring 規律をドキュメントに反映

AGENTS.md: shared/ の共有エージェント運用ルールを追加
CONTEXT-MAP.md: shared/ の位置付け（コレクション外の真実源）を追記
README.md: 新コレクション追加時の手順を追記
EOF
)"
```

---

## 完了条件

全 Task 完了後、以下が成立していること：

- [ ] `shared/agents/` に 13 エージェントの真実源が存在し、`git log --follow` で indie-studio 時代の履歴を辿れる
- [ ] `scripts/sync-shared.sh` が sync / verify / status の 3 サブコマンドで動作する
- [ ] `Makefile` の 4 target（help / sync / verify / status）が動作する
- [ ] `indie-studio/.claude-plugin/dependencies.json` が存在し、`make sync` で indie-studio/agents/ に 13 件の generated file が出る
- [ ] generated file は frontmatter に `x-source` / `x-source-hash` / `x-synced-at` を持つ
- [ ] `make verify` が exit 0、`make status` が「13 synced / 0 drifted / 0 missing」
- [ ] Claude Code から generated agent が正常起動する（Task 7 Step 7 で確認）
- [ ] `.github/workflows/verify-shared.yml` が valid yaml で存在し、`make verify` を呼ぶ
- [ ] AGENTS.md / CONTEXT-MAP.md / README.md が shared/ と vendoring 規律を反映している
- [ ] 全コミットが `feat:` / `docs:` / `refactor:` / `ci:` のいずれかで分類されており、各 Task が独立 commit になっている

ブランチ `feat/shared-agent-vendoring` の commit 数は本 plan で +9（Task 1〜9）。先行する ADR + spec の 2 commit と合わせて 11 commit になる。PR 化時はこの構成のまま push する（squash しない）。

## 失敗時の対応

- **Task 7 Step 7 で Claude Code が `x-*` 未知 frontmatter で破綻した場合**：plan 実行を中断。ADR-0004 を extends する新 ADR を別ブランチで起こし、`description` 末尾に metadata を埋める fallback 方式（spec Section 10.3）に切り替え。本 plan は破棄して新 spec / plan を作り直す
- **bash 互換性問題（macOS の bash 3.2 が `mapfile` を持たない）**：macOS デフォルト bash で `mapfile` が失敗する場合、Homebrew bash 5+ を `#!/usr/bin/env bash` で参照させるか、`while IFS= read -r line; do ...; done` に置き換える。ubuntu-latest（bash 5+）では問題なし
- **CI で `jq` が preinstalled だった場合**：`apt-get install -y jq` ステップは冗長だが害は無いので放置可。気になれば後続 PR で `command -v jq || sudo apt-get install -y jq` に切り替え

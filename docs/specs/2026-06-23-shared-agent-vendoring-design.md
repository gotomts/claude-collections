# shared-agent-vendoring 実装 design

[ADR-0004](../adr/0004-shared-agent-vendoring.md) で採択した「shared/agents/ を真実源とする vendoring 方式」を実装レベルに翻訳した design spec。本 spec は **architectural 決定の繰り返しではなく**、ADR で定まった方針を前提に「ファイル配置・スキーマ・スクリプト I/F・エラーハンドリング・移行手順」を具体化する。

## 0. 前提

- ADR-0004 の決定（真実源は `shared/agents/`、取り込み宣言は `dependencies.json`、generated file は git tracked、CI で drift 検知、lock file なし、frontmatter に `x-*` メタを埋める）に従う
- 共有対象は **engineering 13 エージェント**（executor 5 + quality 4 + leadership 4）。Product/Design/Discovery 系 5 は indie-studio 固有として残す
- rules（CLAUDE.md 相当）は本 spec の対象外（collection 内完結、ADR-0004 参照）

## 1. ディレクトリ構造

```
claude-collections/
  Makefile                                       # NEW: 統一窓口
  shared/
    agents/                                      # NEW: 真実源
      backend-engineer.md
      frontend-engineer.md
      mobile-engineer.md
      infrastructure-engineer.md
      performance-engineer.md
      qa-engineer.md
      code-reviewer.md
      reviewer.md
      security-engineer.md
      principal-engineer.md
      software-architect.md
      tech-lead.md
      engineering-manager.md
  scripts/
    sync-shared.sh                               # NEW
  indie-studio/
    .claude-plugin/
      plugin.json
      dependencies.json                          # NEW
    agents/
      # 13: generated（shared/ から sync、frontmatter に x-* metadata）
      # 5:  手書き：business-strategist / product-manager /
      #            product-designer / visual-designer / ux-researcher
  .github/
    workflows/
      verify-shared.yml                          # NEW
  docs/
    adr/0004-shared-agent-vendoring.md           # 既存（ADR）
    specs/2026-06-23-shared-agent-vendoring-design.md  # 本 spec
```

## 2. CLI entry point: Makefile

repo root の `Makefile` を**統一窓口**とする。直接 `./scripts/sync-shared.sh` を呼んでもよいが、推奨は `make` 経由。

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

使い方：
```bash
make help                              # 一覧
make sync                              # 全 collection を sync
make sync COLLECTION=indie-studio      # 指定
make verify                            # CI 等
make status                            # 現状確認
```

採用理由（他案却下含む）は ADR-0004 ではなく本 spec の意思決定として記録：
- **採用：Makefile** — macOS / Linux preinstalled、追加 install 不要、将来 target 追加で他コマンドも統合可能
- **却下：Justfile** — syntax は綺麗だが `just` install が CI 含む全環境で必要
- **却下：bin/ thin wrapper** — sync/verify/status × 3 ファイルの wrapper 管理が増える
- **却下：直接スクリプト呼び出しのみ** — 統一窓口がなく、コマンドが増えた時の発見性が低い

## 3. scripts/sync-shared.sh

### 3.1 起動規約

- shebang: `#!/usr/bin/env bash`
- `set -euo pipefail`
- **cwd 非依存**：`cd "$(git rev-parse --show-toplevel)"` で内部的に repo root に移動。どこから呼んでも動く
- 起動時 prereq チェック：`jq` 存在確認。なければ `jq is required. Install via: brew install jq` を出して exit 2

### 3.2 サブコマンド

```
Usage:
  sync-shared.sh sync [<collection>]    # 取り込み（無指定 = 全 collection）
  sync-shared.sh verify [<collection>]  # drift 検知（drift で exit 1）
  sync-shared.sh status [<collection>]  # 状態表示（exit 0 固定）
```

#### sync の動作
1. 対象 collection 群を特定：
   - 引数あり：その 1 collection のみ
   - 引数なし：`*/.claude-plugin/dependencies.json` を glob で発見
2. 各 collection の `.claude-plugin/dependencies.json` を読み、`shared.agents[]` を取得
3. 各 picked agent name について：
   - `shared/agents/<name>.md` を読む（無ければ error）
   - SHA256 計算
   - 元 frontmatter + `x-source` / `x-source-hash` / `x-synced-at` を merge して `<collection>/agents/<name>.md` に書き出し
4. 手書き agent（generated でない `<collection>/agents/*.md`）は触らない
5. 衝突検知：pick された name に対して `<collection>/agents/<name>.md` が**手書きで**既存（frontmatter に `x-source` が無い）→ error

#### verify の動作
1. 対象 collection 群を特定（sync と同じロジック）
2. 各 picked agent について：
   - `<collection>/agents/<name>.md` 存在確認（無ければ "missing", exit 1）
   - frontmatter の `x-source-hash` を読む
   - `shared/agents/<name>.md` の現在 hash と比較（不一致なら "drifted", exit 1）
3. 全一致なら exit 0、サマリを出力

#### status の動作
verify と同じチェックだが exit 0 固定。出力例：
```
indie-studio:
  ✓ backend-engineer       (synced)
  ✗ code-reviewer          (drifted — source updated)
  ! tech-lead              (missing in collection)
  
Summary: 11 synced / 1 drifted / 1 missing
```

### 3.3 実装言語

- **bash + jq**
- macOS と Linux（GitHub Actions ubuntu-latest）で動作
- shellcheck で lint 推奨（本 spec 範囲外）

## 4. dependencies.json schema

`<collection>/.claude-plugin/dependencies.json`:

```jsonc
{
  "shared": {
    "agents": [
      "backend-engineer",
      "frontend-engineer",
      "mobile-engineer",
      "infrastructure-engineer",
      "performance-engineer",
      "qa-engineer",
      "code-reviewer",
      "reviewer",
      "security-engineer",
      "principal-engineer",
      "software-architect",
      "tech-lead",
      "engineering-manager"
    ]
  }
}
```

- `shared.` wrapper を残し、将来 `shared.skills[]` / `shared.rules[]` を非破壊で追加可能に
- 名前は basename（拡張子なし）
- バリデーション：
  - 不正 JSON → error (exit 2)
  - `shared.agents` が array でない → error (exit 2)
  - `shared.agents[]` に重複あり → error (exit 2)
  - 存在しない name → error (exit 2)

## 5. Generated file frontmatter

shared/ の元 frontmatter を**無加工で保持**し、末尾に `x-*` を 3 つ追加：

**元（`shared/agents/backend-engineer.md`）:**
```yaml
---
name: backend-engineer
description: ...
tools: ...
model: ...
color: ...
---

（本文）
```

**sync 後（`indie-studio/agents/backend-engineer.md`）:**
```yaml
---
name: backend-engineer
description: ...
tools: ...
model: ...
color: ...
x-source: shared/agents/backend-engineer.md
x-source-hash: sha256:abc123...
x-synced-at: 2026-06-23T00:00:00Z
---

（本文：無加工）
```

- 既存 frontmatter フィールドは順序含めて無加工
- `x-*` 3 つはファイル末尾の `---` 直前に追加
- `x-source-hash` の値形式：`sha256:` prefix + 16進文字列（lowercase）
- `x-synced-at` は ISO 8601 UTC（秒精度）

**前提：Claude Code agent loader が未知 frontmatter フィールドを無視する**（ADR-0004 で記載のリスク）。実装 PR の冒頭で実機確認し、破綻したら fallback（`description` 末尾に文字列メタ埋め）を別 ADR で記録して切り替え。

## 6. 命名衝突ルール

| 状況 | 挙動 |
|---|---|
| `shared/agents/X` が pick されており、`<collection>/agents/X` が **手書きで**（= frontmatter に `x-source` 無し）既存 | sync が error 停止。出力例：`Collision: indie-studio/agents/backend-engineer.md exists as handwritten file. Either rename it or remove from dependencies.json.` |
| `shared/agents/X` が **未** pick で、`<collection>/agents/X` が手書きで存在 | OK（独立して共存） |
| `shared/agents/X` が pick されており、`<collection>/agents/X` が既に generated（= `x-source` あり） | OK（sync で上書き） |

解消方法：手書き側をリネーム、または `dependencies.json` から pick を外す。

## 7. CI workflow

`.github/workflows/verify-shared.yml`:

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
        run: sudo apt-get install -y jq
      - name: Verify shared sync
        run: make verify
```

- `paths` filter で関係 PR のみ走る
- `make` と `bash` は ubuntu-latest に preinstalled
- drift 検知時は exit 1 で PR ブロック

## 8. エラーハンドリング一覧

| エラー | メッセージ | exit code |
|---|---|---|
| jq 未インストール | `jq is required. Install via: brew install jq` | 2 |
| dependencies.json 不正 JSON | `Invalid JSON: <path>` | 2 |
| `shared.agents` が array でない | `dependencies.json: shared.agents must be an array` | 2 |
| `shared.agents[]` 重複 | `dependencies.json: duplicate agent name '<name>'` | 2 |
| 存在しない agent name | `Unknown agent: <name> (not in shared/agents/)` | 2 |
| 同名衝突 | `Collision: <path> exists as handwritten file` | 2 |
| verify で missing | `Missing: <collection>/agents/<name>.md` | 1 |
| verify で drift | `Drifted: <collection>/agents/<name>.md (source-hash mismatch)` | 1 |
| usage error | `Usage: sync-shared.sh {sync\|verify\|status} [<collection>]` | 2 |

exit code 体系：
- 0：成功
- 1：drift / missing 検知（verify のみ。データ正常性の検証失敗）
- 2：実装エラー / 設定エラー / usage error

## 9. Migration plan

実装 PR で行う作業（順序通り）：

1. **`shared/agents/` 作成、indie-studio から 13 ファイルを `git mv`** で移動。`git mv` を使うことで `git log --follow` で履歴を辿れる
2. **`scripts/sync-shared.sh` 実装**（sync + verify + status の 3 サブコマンド）
3. **`Makefile` 作成**（help + sync + verify + status の 4 target）
4. **`indie-studio/.claude-plugin/dependencies.json` 追加**（13 agent を pick）
5. **`make sync COLLECTION=indie-studio` 実行** → 13 ファイルが indie-studio/agents/ に generated として戻る
6. **diff 確認**：13 ファイルの本文は元と同じ、frontmatter に `x-*` 3 行が追記されていること
7. **`.github/workflows/verify-shared.yml` 追加**
8. **`AGENTS.md` と `CONTEXT-MAP.md` を更新**（shared/ の位置付け、vendoring 規律、Makefile 経由の操作）
9. **README に「新 collection 追加時の手順」を 1 段落追加**

各ステップを別 commit にする想定。PR にまとめて出す。

## 10. Testing

### 10.1 自動テスト
GitHub Actions の `verify-shared` workflow が drift / missing を機械的に検知 → 回帰テスト。

### 10.2 実装 PR 内の手動テスト

- `make sync` 後、indie-studio/agents/<name>.md の 13 ファイルが frontmatter に `x-source` / `x-source-hash` / `x-synced-at` を持つこと
- `shared/agents/backend-engineer.md` を編集して `make sync` 再実行 → indie-studio 側に反映される
- 編集後 `make sync` を**実行しない**で `make verify` → exit 1 になる
- `dependencies.json` に存在しない agent name を書いて `make sync` → error (exit 2)
- 同名衝突を仕込んで `make sync` → error (exit 2)
- 異なる cwd（例：`/tmp` や `indie-studio/`）から `make sync` → repo root に内部的に移動して動作する
- **Claude Code 実機確認**：sync 後の generated file が agent として正しく起動できる（`x-*` 未知 frontmatter を無視するか）

### 10.3 失敗時の fallback
`x-*` frontmatter が Claude Code agent loader で破綻した場合：
- 本 spec は無効化
- ADR-0004 を extends する形で別 ADR を起こし、`description` 末尾に metadata を埋める fallback 方式に切り替え

## 11. スコープ外（明示）

以下は本 spec の対象外：

- **rules（CLAUDE.md 相当）の共有** — ADR-0004 で collection 内完結と決定済み
- **skills の共有** — 要望が出ていない（同じ vendoring パターンを将来適用可能）
- **shared/agents/ の命名規約**（役職名そのまま v.s. 接頭辞付き等） — 命名衝突が起きた時に運用で詰める
- **agent version pin（git SHA 等での固定）** — main 追従戦略（ADR-0003）と整合させない
- **shared 内エージェント間の依存関係** — agent 間に依存があれば dependencies.json で個別 pick されるだけ

## 12. 未解決の前提検証

実装 PR の冒頭で確認する事項：

1. Claude Code agent loader が frontmatter の `x-*` 未知フィールドを無視するか
2. macOS デフォルトの `sha256sum` が無い場合の代替（`shasum -a 256` 等）の動作
3. ubuntu-latest GitHub Actions runner で `jq` が preinstalled か（preinstalled の場合 `apt-get install` は冗長）

いずれも実装で初めて確定する内容のため、本 spec では「実装 PR で扱う」として明記するに留める。

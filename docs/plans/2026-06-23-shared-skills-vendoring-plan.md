# shared-skills-vendoring Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `shared/skills/` namespace を新設し、`scripts/sync-shared.sh` を skill 対応に拡張する。`shared/skills/start-stage-branch/SKILL.md` と `shared/skills/finish-stage-pr/SKILL.md` を真実源として配置し、indie-studio コレクションが `dependencies.json` の `shared.skills[]` で取り込めるようにする（root ADR-0005 を起稿）。spec の Layer A（PR1）のみを対象とする。

**Architecture:** root ADR-0004（shared/agents/ vendoring）を extends。`shared/skills/<name>/SKILL.md` を真実源とし、`<collection>/.claude-plugin/dependencies.json` の `shared.skills[]` で pick 宣言。`scripts/sync-shared.sh` が generated file（frontmatter に `x-source` / `x-source-hash` / `x-body-hash` / `x-synced-at` を埋め込み）を `<collection>/skills/<name>/SKILL.md` に書き出す。既存の agents 用ロジックを最大限再利用し、skill 用は path 解決と loop だけ追加。1 skill = 1 SKILL.md に絞る（補助ファイルは対象外・YAGNI）。

**Tech Stack:** bash 4+ / jq / GNU Make / git / gh CLI（手動確認のみ）

## Global Constraints

- **Spec の真実源**：[docs/specs/2026-06-23-indie-studio-skill-branch-pr-flow-design.md](../specs/2026-06-23-indie-studio-skill-branch-pr-flow-design.md)。実装上の判断はここを参照
- **root ADR-0004**：[docs/adr/0004-shared-agent-vendoring.md](../adr/0004-shared-agent-vendoring.md) を extends する形で本 PR の ADR-0005 を起稿
- **依存ツール**：bash + jq + git + make のみ。他言語 runtime は導入しない
- **cwd 非依存**：scripts は `cd "$(git rev-parse --show-toplevel)"` で内部的に repo root に移動（既存通り）
- **既存挙動の保全**：`shared.agents[]` 関連の挙動・出力フォーマット・error 条件は一切変更しない（後方互換）。skill 対応は新規関数 + 新規ループとして追加し、既存パスに分岐を増やさない
- **frontmatter 形式**：generated file は元 frontmatter を順序含めて保持し、closing `---` の直前に `x-source` / `x-source-hash` / `x-body-hash` / `x-synced-at` の 4 行を追加。書式は agents と同一
- **1 skill = 1 SKILL.md**：`shared/skills/<name>/SKILL.md` のみ sync 対象。`<name>/references/*.md` 等の補助ファイルは将来要望が出た時点で別 ADR で拡張
- **Conventional Commits**：`feat:` / `docs:` / `chore:` プレフィックス。既存履歴と整合
- **頻繁なコミット**：各 Task の末尾で 1 コミット。ブランチは `feat/indie-studio-skill-branch-pr-flow`（作成済み）
- **作業ディレクトリ**：本 PR の作業はすべて `/Users/goto/ghq/github.com/gotomts/claude-collections.feat-indie-studio-skill-branch-pr-flow` (worktree) で行う
- **取り込み対象 helper skill 2 個**：`start-stage-branch`・`finish-stage-pr`
- **PR2 の前提**：本 PR1 のマージ後に PR2 (indie-studio 既存 6 SKILL.md 改修) を rebase で起こす。本 plan は PR1 のみが対象

---

## Task 1: root ADR-0005 起稿（shared/skills/ vendoring）

**Files:**
- Create: `docs/adr/0005-shared-skills-vendoring.md`

**Interfaces:**
- Consumes: 既存 ADR-0004（shared/agents/ vendoring）の決定
- Produces: 本 PR の他 Task が参照する設計判断の真実源

- [ ] **Step 1: ADR ファイルを作成**

Create `docs/adr/0005-shared-skills-vendoring.md` with the following content:

```markdown
# 共有スキルは shared/skills/ を真実源とする vendoring 方式で配布する

collection 間で共通利用したいスキル（helper 系：branch 作成 / PR 作成 等）は、リポジトリ root の `shared/skills/` を**真実源**とし、各 collection は `<collection>/.claude-plugin/dependencies.json` の `shared.skills[]` で**取り込みたいスキルを宣言**する。実体化は `scripts/sync-shared.sh` が generated file として `<collection>/skills/<name>/SKILL.md` に書き出し、CI で drift を検知する。ADR-0004（shared/agents/ vendoring）を extends する。当面は 1 skill = 1 SKILL.md に絞る（補助ファイルは別 ADR で拡張）。

## Status

accepted（[ADR-0004](0004-shared-agent-vendoring.md) を extends：同じ vendoring パターンを skill にも適用）

## Considered Options

### 共有手段

- **却下：collection ごとに同名 skill を手書き複製**。helper 系は複数 collection で同一の挙動を期待されるため、複製は drift の温床。ADR-0004 と同じ理由で却下。
- **却下：shared-skills を独立 plugin として marketplace に列挙**。ADR-0004 と同じ理由（粒度不一致・`name` 衝突・install 依存の不可視性）で却下。
- **採用：ADR-0004 と同じ vendoring パターンを skill にも適用**。learning cost ゼロ、運用窓口（`make sync` / `make verify` / `make status`）も同一。

### 真実源の所在

- **採用：リポジトリ root の `shared/skills/`**。`shared/agents/` と並列。collection ではない（`marketplace.json` に列挙しない）。

### 取り込み宣言の場所

- **採用：`<collection>/.claude-plugin/dependencies.json` の `shared.skills[]`**（既存 `shared.agents[]` と同階層）。**任意フィールド**として追加（既存 collection の dependencies.json は変更不要）。

### sync 対象の粒度

- **却下：skill ディレクトリ配下の全ファイルを sync**（`SKILL.md` ＋ `references/*.md` ＋ `examples/*` 等）。複雑度が上がる割に、現状 shared 対象として想定しているのは 1 ファイル SKILL.md のみ。YAGNI。
- **採用：1 skill = `<name>/SKILL.md` のみ sync**。`<name>/references/*.md` 等の補助ファイルは将来要望が出た時点で別 ADR で拡張。これにより既存の agents 用 `sync_one` ロジックがほぼそのまま流用可能。

### 衝突回避

- **採用：`shared/agents/<name>` と `shared/skills/<name>` の `name` 衝突は禁止**（top-level で別 namespace なので構造的に分離）。`shared/skills/` 内および各 collection 内では agents と同様に `name` 一意制約。

### CI 検知

- **採用：`scripts/sync-shared.sh verify` を skill にも拡張**。lock ファイルは導入せず、generated file の frontmatter `x-source-hash` / `x-body-hash` の比較で drift を検知（agents と同型）。

## Consequences

- `<collection>/.claude-plugin/dependencies.json` に `shared.skills[]` を追加することで、shared/skills/ から helper を取り込める。`shared.skills` は **optional**（未設定 collection は影響なし）
- `scripts/sync-shared.sh` は agents 用ロジックを保持しつつ、skill 用の関数と loop を追加する形で拡張する。既存挙動は不変
- generated SKILL.md は git tracked（agents と同じ理由）。frontmatter に `x-source` / `x-source-hash` / `x-body-hash` / `x-synced-at` を埋める
- shared/skills/<name>/SKILL.md を更新したら、pick している全 collection で `make sync` を実行し、generated 更新の PR を出す。CI verify でブロックされるため忘れは構造的に防がれる
- 1 skill = 1 SKILL.md の制限は、helper skill が SKILL.md 自己完結である限り十分。複雑な skill 構成（references/examples）が必要になった時点で本 ADR を拡張する別 ADR を書く
- `shared/skills/` 配下のスキルと collection 固有スキルの `name` 衝突は sync が error で停止する（agents と同型）
- 本 ADR は root の `docs/adr/` に置く（ADR-0001 の「横断決定は root」原則）
```

- [ ] **Step 2: ADR が markdown として正しいか視覚確認**

```bash
head -5 docs/adr/0005-shared-skills-vendoring.md
wc -l docs/adr/0005-shared-skills-vendoring.md
```

Expected: 1 行目が `# 共有スキルは shared/skills/ を真実源とする vendoring 方式で配布する`、行数は 50 前後。

- [ ] **Step 3: コミット**

```bash
git add docs/adr/0005-shared-skills-vendoring.md
git commit -m "docs(adr): ADR-0005 shared/skills/ vendoring を起稿（ADR-0004 extends）"
```

---

## Task 2: shared/skills/start-stage-branch/SKILL.md を作成

**Files:**
- Create: `shared/skills/start-stage-branch/SKILL.md`

**Interfaces:**
- Consumes: `wt` CLI（dotfiles 由来の `wt switch --create` 関数）、git CLI
- Produces: 呼び出し側 skill（PR2 の indie-studio 各 SKILL.md）が args=`<stage>/<skill-name>` 形式で invoke できる helper skill

- [ ] **Step 1: ディレクトリを作成**

```bash
mkdir -p shared/skills/start-stage-branch
```

- [ ] **Step 2: SKILL.md を作成**

Create `shared/skills/start-stage-branch/SKILL.md`:

````markdown
---
name: start-stage-branch
description: |
  service repo 内で、skill 起動時に branch + worktree を切る共有 helper。
  呼び出し側 (各 stage skill) が推奨 branch 名を args で渡し、本 skill が
  重複検出・suffix 付与・ユーザー承認・wt switch --create を担当する。
  汎用なので indie-studio 以外の collection からも利用可。
argument-hint: "<branch-suggestion>  # 例: s1/service-discovery"
allowed-tools:
  - Bash
  - Read
maintainer: gotomts
---

# start-stage-branch

呼び出し側 skill から推奨 branch 名を受け取り、service repo に branch + worktree を 1 アクションで用意する共有 helper。`wt switch --create` で worktree とブランチを同時に作る。

## 使うべきとき

各 stage skill（例: `service-discovery` / `tech-design` / `decomposition` 等）が冒頭で「自分の実行を独立 branch で隔離する」ために invoke する。呼び出し側が args 1 行で推奨 branch 名（`<stage>/<skill-name>` 形式）を渡す前提。

## 使わないとき

- 呼び出し側に branch suggestion 引数が無い場合（argument-hint 必須）。
- Linear / GitHub URL から命名したい場合（user 直接の `wt-start` を使う）。
- 単独タスクで main 直作業を尊重する場合（呼び出し側 skill が判断）。

## 実行ステップ

### Step 1: 環境チェック

`git rev-parse --show-toplevel` が成功することを確認。失敗（git repo 外）なら error 報告して中断（呼び出し元 skill に「進める」と誤判定させない）。

### Step 2: base ブランチを解決

```sh
git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||'
```

取得できれば `origin/<default>` を base に。失敗（remote 未設定）なら `origin/main` を default として提示し、user に確認。

### Step 3: 重複検出

引数 `<branch-suggestion>` を受けて、以下を順にチェック：

```sh
git rev-parse --verify <branch-suggestion> 2>/dev/null
git ls-remote --heads origin <branch-suggestion> 2>/dev/null
```

どちらかにヒットしたら、`<branch-suggestion>-2` → `-3` → ... と suffix を増やして空きを取る。

### Step 4: ユーザー承認（1 問）

提示形式：

```
推奨: <候補 branch 名>
base: origin/main
この名前で進めて良いですか? (yes / 別名)
```

- `yes` → Step 5 へ。
- `別名` → 提示された名前で Step 3 から再開（重複検出やり直し）。

### Step 5: 実行

```sh
wt switch --create <approved-branch> --base <base>
```

`-y` (skip approval) は付けない。実行前に最終コマンドを user に見せる。

### Step 6: 完了報告

worktree のパスと「呼び出し元 skill に制御を返します」を 1〜2 行で返す。

## 失敗時の挙動

| 状況 | 挙動 |
|---|---|
| git repo 外 | error 報告 + 中断（skill 本体に進まない） |
| 既存 worktree 内 | "既に worktree 内ですが新規追加で進めますか?" 1 問確認 |
| `wt` コマンド不在 | error 報告 + 中断（依存性チェック） |
| `wt switch --create` 失敗 | エラー出力を見せて中断、リカバリは呼び出し側ユーザー判断 |
| user が "別名" を返した | その名前で再度重複検出してやり直し |

## やらないこと

- Linear / GitHub からの命名（`wt-start` の責務、必要なら別 helper に分離）。
- branch 名規約の strict validation（呼び出し側が責任を持つ）。
- editor / claude 起動の連鎖。
- merge / PR 作成（PR は `finish-stage-pr` の責務）。

## 関連

- root ADR-0005（shared/skills/ vendoring）
- 呼び出し側の規約は collection 側の ADR で定める（例: indie-studio ADR-0031）
````

- [ ] **Step 3: ファイルが想定通りか確認**

```bash
head -10 shared/skills/start-stage-branch/SKILL.md
wc -l shared/skills/start-stage-branch/SKILL.md
```

Expected: 1 行目が `---`（frontmatter 開始）、行数は 70〜90。

- [ ] **Step 4: コミット**

```bash
git add shared/skills/start-stage-branch/SKILL.md
git commit -m "feat(shared): start-stage-branch helper skill を追加（ADR-0005）"
```

---

## Task 3: shared/skills/finish-stage-pr/SKILL.md を作成

**Files:**
- Create: `shared/skills/finish-stage-pr/SKILL.md`

**Interfaces:**
- Consumes: git CLI、gh CLI（`gh pr create` / `gh pr edit` / `gh label create`）
- Produces: 呼び出し側 skill（PR2 の indie-studio 各 SKILL.md）が prose 引数で PR title / stage / label / ⚠️ 残数 / gate report 要約を渡して invoke できる helper skill

- [ ] **Step 1: ディレクトリを作成**

```bash
mkdir -p shared/skills/finish-stage-pr
```

- [ ] **Step 2: SKILL.md を作成**

Create `shared/skills/finish-stage-pr/SKILL.md`:

````markdown
---
name: finish-stage-pr
description: |
  service repo 内で、skill 完了時に push + PR open を担当する共有 helper。
  呼び出し側 (各 stage skill) が PR title 候補・stage・label・⚠️ 残数・
  ゲートレポート要約を args で渡し、本 skill が draft/ready 判定・
  user 最終確認・gh pr create を担当する。汎用なので indie-studio
  以外の collection からも利用可。
argument-hint: "<title-suggestion>  # body 用情報は呼び出し側 SKILL.md の prose で渡す"
allowed-tools:
  - Bash
  - Read
maintainer: gotomts
---

# finish-stage-pr

呼び出し側 skill から PR title 候補・stage キー・label・⚠️ 残数・ゲートレポート要約を受け取り、現 branch を push して PR を open する共有 helper。⚠️ 残数で draft / ready を自動判定する。

## 使うべきとき

各 stage skill が完全性ガード（期待マニフェスト ✅/➖/⚠️ 決着）を提示した直後に invoke する。呼び出し側が PR title 候補と body 構成要素を prose で渡す前提。

## 使わないとき

- 完全性ガードが未完了の場合（呼び出し側が判定し、未完了なら invoke しない）。
- 単独 commit でローカルに留めたい場合（`commit-commands:commit` を使う）。
- merge / 自動レビュアー割り当てをしたい場合（本 helper の責務外）。

## 入力（呼び出し側 SKILL.md の prose で渡す）

| 項目 | 内容 | 例 |
|---|---|---|
| title 候補 | conventional commits 風 1 行 | `feat(s1): service-discovery 完了 (socialcoffeenote)` |
| ⚠️ 残数 | 完全性ガードで未解消の項目数 | 0 / 2 |
| ゲートレポート要約 | ✅/➖/⚠️ 件数と要点 | `✅ 12 / ➖ 3 / ⚠️ 0` |
| label 候補 | indie-studio + stage 名 | `indie-studio`, `s1` |
| stage キー | branch 名と整合 | `s1` |

## 実行ステップ

### Step 1: 環境チェック

`git rev-parse --show-toplevel` で git repo を確認。`git branch --show-current` で現 branch を取得し、`main` 直作業を拒否（"main 直作業では PR を出せません" + 中断）。

### Step 2: 未 commit 確認

```sh
git status --porcelain
```

出力が空でなければ "未 commit 変更があります。commit してから再度 invoke してください" で中断（自動 commit はしない）。

### Step 3: base 解決

```sh
git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||'
```

取得できれば `origin/<default>`、失敗なら `origin/main` を default として提示。

### Step 4: commit 差分の確認（空 PR 防止）

```sh
git log origin/main..HEAD --oneline
```

出力が空なら "差分がないので PR を作りません" + 中断。

### Step 5: 既存 PR チェック

```sh
gh pr list --head <current-branch> --json number,title
```

ヒットしたら "branch X には既に PR #N があります" を見せ、`gh pr edit` で更新か新規かを 1 問確認。

### Step 6: draft / ready 判定

呼び出し側から受けた ⚠️ 残数で判定：

- `⚠️ 残数 > 0` → **draft**
- `⚠️ 残数 == 0` → **ready**

### Step 7: PR body を組み立て

テンプレ：

```markdown
## 概要
<呼び出し側からの 1 行説明>

## ゲートレポート
✅ <件数> / ➖ <件数> / ⚠️ <件数>

<⚠️ がある場合のみ>
### 繰り越し論点
- <item 1>
- <item 2>

## 関連
- stage: <s1 / s1a / s1b / s3 / s4 / s5>
- skill: <service-discovery / ...>

🤖 Generated via indie-studio harness (`finish-stage-pr` helper)
```

### Step 8: ユーザー最終確認（1 問）

提示形式：

```
PR を作成します:
  title: <title>
  base: origin/main
  state: draft (⚠️ 2 件残り) | ready (⚠️ 0)
  labels: indie-studio, s1
進めて良いですか? (yes / title 修正 / no)
```

- `yes` → Step 9 へ。
- `title 修正` → user 入力を待って title を差し替え、Step 8 から再確認。
- `no` → PR を作らず終了、branch は残す（再 invoke 可能）。

### Step 9: label 存在確認

```sh
gh label list --json name | jq -r '.[].name'
```

提示 label が無ければ "label '<name>' が無いので作成しますか? (yes/no)" 1 問確認。yes なら：

```sh
gh label create <name> --color <default-color>
```

`default-color` は label 名に応じて選ぶ（例: `indie-studio` → `8B5CF6`、`s1` → `0E8A16`）。

### Step 10: push と PR open

```sh
git push -u origin <current-branch>
gh pr create --base <base-branch> --head <current-branch> --title "<title>" --body "<body>" [--draft]
gh pr edit <new-pr-number> --add-label "<label1>" --add-label "<label2>"
```

`--draft` は ⚠️ 残数 > 0 の場合のみ付ける。

### Step 11: 完了報告

作成された PR URL を user に表示。呼び出し元 skill に制御を返す。

## 失敗時の挙動

| 状況 | 挙動 |
|---|---|
| 現在 `main` | "main 直作業では PR を出せません" + 中断 |
| dirty working tree | "未 commit 変更があります。commit してから再度 invoke してください" + 中断 |
| 既存 PR が同 head | "branch X には既に PR #N があります" を見せ、`gh pr edit` で更新か新規かを 1 問確認 |
| commit が 0 件（空 PR） | "差分がないので PR を作りません" + 中断 |
| push 失敗（認証等） | エラー出力を見せて中断、`gh auth status` を案内 |
| ユーザーが "no" を返した | PR を作らず終了、branch は残す |
| label が未存在 | `gh label create` を 1 問確認して自動作成 |

## やらないこと

- 自動 merge（G3/G4/G5 ゲートの責務、reviewer 判断）。
- reviewer 自動割り当て（個人開発前提）。
- amend / force-push（危険操作禁止規律）。
- 自動 commit（呼び出し側に責任を持たせる）。

## 関連

- root ADR-0005（shared/skills/ vendoring）
- 呼び出し側の規約は collection 側の ADR で定める（例: indie-studio ADR-0031）
````

- [ ] **Step 3: ファイルが想定通りか確認**

```bash
head -15 shared/skills/finish-stage-pr/SKILL.md
wc -l shared/skills/finish-stage-pr/SKILL.md
```

Expected: 1 行目が `---`、frontmatter が完結、行数は 120〜160。

- [ ] **Step 4: コミット**

```bash
git add shared/skills/finish-stage-pr/SKILL.md
git commit -m "feat(shared): finish-stage-pr helper skill を追加（ADR-0005）"
```

---

## Task 4: scripts/sync-shared.sh を skill 対応に拡張

**Files:**
- Modify: `scripts/sync-shared.sh`

**Interfaces:**
- Consumes: shared/skills/<name>/SKILL.md（Task 2/3 で作成済み）、`<collection>/.claude-plugin/dependencies.json`（Task 5 で `shared.skills[]` を追加）
- Produces: `read_picked_skills()` / `sync_one_skill()` 関数、`cmd_sync` / `cmd_verify` / `cmd_status` の skill ループ。既存 agents 関連挙動は不変

- [ ] **Step 1: 改修方針を確認（dry-read）**

```bash
grep -n "^[a-z_]*()" scripts/sync-shared.sh
```

Expected 出力: usage / file_hash / body_hash / discover_collections / read_picked_agents / is_generated / read_source_hash / read_body_hash / sync_one / cmd_sync / cmd_verify / cmd_status の 12 関数。これらは変更せず（read_picked_agents 以外は完全保全）、新規追加で対応する。

- [ ] **Step 2: read_picked_skills 関数を追加**

`scripts/sync-shared.sh` を編集し、`read_picked_agents()` 関数の直後（現在 line 71 あたり、`}` の後）に以下を挿入：

```bash
# dependencies.json の shared.skills[] を読む（optional・無い場合は no-op）
read_picked_skills() {
  local dep_file="$1"
  # shared.skills is optional; absent / null → silent no-op
  jq -e '.shared.skills' "$dep_file" >/dev/null 2>&1 || return 0
  jq -e '.shared.skills | type == "array"' "$dep_file" >/dev/null 2>&1 || {
    echo "dependencies.json: shared.skills must be an array ($dep_file)" >&2
    return 2
  }
  jq -r '.shared.skills[]' "$dep_file"
}
```

**Note**: `read_picked_agents` と違って、`shared.skills` が無い場合は silent `return 0`（既存 collection の dependencies.json を壊さないため）。

- [ ] **Step 3: sync_one_skill 関数を追加**

`scripts/sync-shared.sh` を編集し、`sync_one()` 関数の直後（既存 sync_one の `}` の後）に以下を挿入：

```bash
# 1 skill を 1 collection に sync
sync_one_skill() {
  local collection="$1"
  local name="$2"
  local src="shared/skills/$name/SKILL.md"
  local dst="$collection/skills/$name/SKILL.md"

  if [ ! -f "$src" ]; then
    echo "Unknown skill: $name (not in shared/skills/)" >&2
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

  mkdir -p "$collection/skills/$name"

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
```

**Note**: agents の sync_one とほぼ同型。違いは src/dst のパス構築と、`mkdir -p` が `$collection/skills/$name` まで掘る点のみ。

- [ ] **Step 4: cmd_sync に skill loop を追加**

`scripts/sync-shared.sh` の `cmd_sync()` 関数内の agents ループの直後（現在の `for name in "${agents[@]}"; do sync_one "$collection" "$name"; done` の直後）に以下を挿入：

```bash
    # skills loop（optional・shared.skills 無ければ no-op）
    local skills=()
    mapfile -t skills < <(read_picked_skills "$dep")

    if [ "${#skills[@]}" -gt 0 ]; then
      local uniq_count_s
      uniq_count_s=$(printf "%s\n" "${skills[@]}" | sort -u | wc -l | tr -d ' ')
      if [ "$uniq_count_s" -ne "${#skills[@]}" ]; then
        echo "dependencies.json: duplicate skill name in $dep" >&2
        exit 2
      fi
    fi

    local skill_name
    for skill_name in "${skills[@]}"; do
      sync_one_skill "$collection" "$skill_name"
    done
```

- [ ] **Step 5: cmd_verify に skill loop を追加**

`scripts/sync-shared.sh` の `cmd_verify()` 関数内の agents ループの直後に以下を挿入：

```bash
    # skills verify loop（optional）
    local skills=()
    mapfile -t skills < <(read_picked_skills "$dep")

    local skill_name
    for skill_name in "${skills[@]}"; do
      local dst="$collection/skills/$skill_name/SKILL.md"
      local src="shared/skills/$skill_name/SKILL.md"

      if [ ! -f "$src" ]; then
        echo "Unknown skill: $skill_name (not in shared/skills/)" >&2
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

      local recorded_body current_body
      recorded_body=$(read_body_hash "$dst")
      current_body=$(body_hash "$dst")
      if [ -n "$recorded_body" ] && [ "$recorded_body" != "$current_body" ]; then
        echo "Edited: $dst (body modified — revert via 'git checkout $dst' or move change to shared/)" >&2
        has_drift=1
      fi
    done
```

- [ ] **Step 6: cmd_status に skill loop を追加**

`scripts/sync-shared.sh` の `cmd_status()` 関数内の agents ループの直後に以下を挿入：

```bash
    # skills status loop（optional）
    local skills=()
    mapfile -t skills < <(read_picked_skills "$dep")

    local skill_name
    for skill_name in "${skills[@]}"; do
      local dst="$collection/skills/$skill_name/SKILL.md"
      local src="shared/skills/$skill_name/SKILL.md"
      if [ ! -f "$src" ]; then
        printf "  ? %-25s (unknown in shared/skills/)\n" "$skill_name"
        continue
      fi
      if [ ! -f "$dst" ]; then
        printf "  ! %-25s (missing skill in collection)\n" "$skill_name"
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
        printf "  ✗ %-25s (skill drifted — source updated)\n" "$skill_name"
        drifted=$((drifted+1))
      elif [ "$body_edited" -eq 1 ]; then
        printf "  ✎ %-25s (skill edited — body modified)\n" "$skill_name"
        edited=$((edited+1))
      else
        printf "  ✓ %-25s (skill synced)\n" "$skill_name"
        synced=$((synced+1))
      fi
    done
```

- [ ] **Step 7: shellcheck で構文チェック**

```bash
shellcheck scripts/sync-shared.sh
```

Expected: warning が出ても fatal は無いこと（既存スクリプトと同水準）。`shellcheck` が無ければ `brew install shellcheck` で導入、または `bash -n scripts/sync-shared.sh` でも代用可。

- [ ] **Step 8: usage 出力と既存挙動が壊れていないか確認**

```bash
./scripts/sync-shared.sh 2>&1 | head -10
./scripts/sync-shared.sh status indie-studio 2>&1 | head -20
```

Expected: usage が表示される、`status indie-studio` で既存の agents 状態（13 個 synced）が表示される（skill は未宣言なので 0 個）。

- [ ] **Step 9: コミット**

```bash
git add scripts/sync-shared.sh
git commit -m "feat(scripts): sync-shared.sh を shared/skills/ 対応に拡張（ADR-0005）"
```

---

## Task 5: indie-studio dependencies.json に shared.skills を追加し、make sync で実体化

**Files:**
- Modify: `indie-studio/.claude-plugin/dependencies.json`
- Create (via sync): `indie-studio/skills/start-stage-branch/SKILL.md`
- Create (via sync): `indie-studio/skills/finish-stage-pr/SKILL.md`

**Interfaces:**
- Consumes: Task 2/3 の shared/skills/ 配下、Task 4 の sync-shared.sh
- Produces: indie-studio collection が 2 個の helper skill を pick した状態

- [ ] **Step 1: 現状の dependencies.json を確認**

```bash
cat indie-studio/.claude-plugin/dependencies.json
```

Expected: `"shared": { "agents": [...] }` の形式、13 agents が並ぶ。

- [ ] **Step 2: dependencies.json に shared.skills を追加**

Edit `indie-studio/.claude-plugin/dependencies.json` to add `"skills"` key under `shared`:

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
    ],
    "skills": [
      "finish-stage-pr",
      "start-stage-branch"
    ]
  }
}
```

**Note**: `skills` 配列は alphabetical 順で揃える（agents と整合）。

- [ ] **Step 3: jq で valid JSON 確認**

```bash
jq -e '.shared.skills | type == "array"' indie-studio/.claude-plugin/dependencies.json
```

Expected: `true` が出力。

- [ ] **Step 4: make sync を実行**

```bash
make sync COLLECTION=indie-studio
```

Expected 出力 (抜粋):
```
indie-studio:
  unchanged: indie-studio/agents/backend-engineer.md
  ...
  synced: indie-studio/skills/finish-stage-pr/SKILL.md
  synced: indie-studio/skills/start-stage-branch/SKILL.md
```

- [ ] **Step 5: generated SKILL.md の frontmatter を確認**

```bash
head -10 indie-studio/skills/start-stage-branch/SKILL.md
head -10 indie-studio/skills/finish-stage-pr/SKILL.md
```

Expected: `x-source: shared/skills/<name>/SKILL.md`, `x-source-hash: sha256:...`, `x-body-hash: sha256:...`, `x-synced-at: <ISO timestamp>` が含まれる。

- [ ] **Step 6: make verify で drift が無いことを確認**

```bash
make verify COLLECTION=indie-studio
```

Expected: `All synced files are up-to-date.` と表示、exit code 0。

- [ ] **Step 7: コミット**

```bash
git add indie-studio/.claude-plugin/dependencies.json \
        indie-studio/skills/start-stage-branch/SKILL.md \
        indie-studio/skills/finish-stage-pr/SKILL.md
git commit -m "feat(indie-studio): shared/skills/ から 2 helper を pick（ADR-0005）"
```

---

## Task 6: root AGENTS.md に shared/skills/ 規約を追記

**Files:**
- Modify: `AGENTS.md`

**Interfaces:**
- Consumes: ADR-0005 の決定
- Produces: 他 collection が同 vendoring 機構を skill にも使えると分かる文書

- [ ] **Step 1: 現在の AGENTS.md の shared/ セクションを確認**

```bash
grep -n "shared/" AGENTS.md | head -10
```

Expected: `## shared/ の共有エージェント` セクションが存在（line 19 周辺）。

- [ ] **Step 2: 「shared/ の共有スキル」セクションを追記**

Edit `AGENTS.md`: `## shared/ の共有エージェント` セクションの最後の bullet（コレクション固有エージェントの説明）の直後に、以下のセクションを挿入する。

```markdown

## shared/ の共有スキル

- helper 系（例：start-stage-branch / finish-stage-pr）の共通スキルは `shared/skills/` を真実源とする（ADR-0005）。
- 各コレクションは `<collection>/.claude-plugin/dependencies.json` の `shared.skills[]` で取り込み宣言する（`shared.agents[]` と同階層・任意フィールド）。
- 取り込みの実体化は `make sync COLLECTION=<name>` で。`<collection>/skills/<name>/SKILL.md` に generated file が書き出される（frontmatter に `x-source` / `x-source-hash` / `x-body-hash` / `x-synced-at` を持つ）。
- generated file は **手編集禁止**。shared 側を編集して `make sync` で反映。
- `make verify` の drift 検知は agents と同型（source-hash mismatch / body modified）。
- 当面 1 skill = 1 SKILL.md（補助ファイルは sync 対象外）。複雑な skill 構成が必要になった時点で本 ADR を拡張。
- コレクション固有のスキルは従来通り `<collection>/skills/` に手書きで置く。shared/ と同名にしないこと（agents と同規律）。
```

- [ ] **Step 3: 追記後の構造を確認**

```bash
grep -n "^## " AGENTS.md
```

Expected: `## shared/ の共有エージェント` と `## shared/ の共有スキル` の両方が並ぶ。

- [ ] **Step 4: コミット**

```bash
git add AGENTS.md
git commit -m "docs(agents-md): shared/ の共有スキル 規約を追記（ADR-0005）"
```

---

## Task 7: full verify cycle と drift 検知の手動テスト

**Files:**
- 一時的に編集: `shared/skills/start-stage-branch/SKILL.md`（手動 drift 確認用、最後に revert）
- 一時的に編集: `indie-studio/skills/finish-stage-pr/SKILL.md`（手動 edited 確認用、最後に revert）

**Interfaces:**
- Consumes: Task 1〜6 の成果
- Produces: drift / edited / unchanged の 3 state が期待通り動くという経験的確証

- [ ] **Step 1: clean な状態で make verify が pass することを確認**

```bash
make verify
```

Expected: `All synced files are up-to-date.` 表示、exit code 0。

- [ ] **Step 2: make status の出力を目視**

```bash
make status COLLECTION=indie-studio
```

Expected: agents 13 個 + skills 2 個がすべて `✓ synced` 表示、Summary に `15 synced / 0 drifted / 0 edited / 0 missing`。

- [ ] **Step 3: shared/ 側を一字変更して drifted を確認**

```bash
# 末尾に空白を追加して hash を変える（content は変えない）
echo "" >> shared/skills/start-stage-branch/SKILL.md
make verify
```

Expected: exit code 1、`Drifted: indie-studio/skills/start-stage-branch/SKILL.md (source-hash mismatch — shared/ updated, run 'make sync')` 表示。

- [ ] **Step 4: shared/ 変更を revert**

```bash
git checkout shared/skills/start-stage-branch/SKILL.md
make verify
```

Expected: revert 後は `All synced files are up-to-date.` 表示、exit code 0。

- [ ] **Step 5: generated 側を手編集して edited を確認**

```bash
echo "" >> indie-studio/skills/finish-stage-pr/SKILL.md
make verify
```

Expected: exit code 1、`Edited: indie-studio/skills/finish-stage-pr/SKILL.md (body modified — revert via 'git checkout ...' or move change to shared/)` 表示。

- [ ] **Step 6: generated 変更を revert**

```bash
git checkout indie-studio/skills/finish-stage-pr/SKILL.md
make verify
```

Expected: `All synced files are up-to-date.` 表示、exit code 0。

- [ ] **Step 7: make sync を再実行して unchanged を確認**

```bash
make sync COLLECTION=indie-studio
```

Expected: 全 15 entries が `unchanged:` 表示。

- [ ] **Step 8: 作業ツリーが clean か確認**

```bash
git status
```

Expected: `nothing to commit, working tree clean`。

- [ ] **Step 9: PR1 全体の commit 履歴を確認**

```bash
git log --oneline main..HEAD | head -10
```

Expected: 6 commits（ADR-0005 / start-stage-branch / finish-stage-pr / sync-shared.sh / indie-studio sync / AGENTS.md）。

**Note**: テスト Task のため独自 commit は無し（Step 3-6 で作った drift は revert で消えるので、tree は clean のまま）。

---

## 完了後の手順（PR1 のクローズ）

本 plan の全 Task 完了後、PR1 を作成して main にマージする。手順は手動 or `commit-commands:commit-push-pr` で行う：

```bash
git push -u origin feat/indie-studio-skill-branch-pr-flow
gh pr create --base main --title "feat: shared/skills/ vendoring system を導入（ADR-0005）" \
  --body "$(cat <<'EOF'
## 概要

ADR-0004 を extends し、shared/skills/ namespace を vendoring system に追加。helper skill 2 つ（start-stage-branch / finish-stage-pr）を真実源として配置し、indie-studio が pick する状態まで整える。indie-studio 既存 6 SKILL.md の改修は別 PR (PR2) で行う。

## 変更内容

- root ADR-0005 起稿（shared/skills/ vendoring）
- shared/skills/start-stage-branch/SKILL.md / shared/skills/finish-stage-pr/SKILL.md 新規追加
- scripts/sync-shared.sh を skill 対応に拡張（agents の挙動は不変）
- indie-studio/.claude-plugin/dependencies.json に shared.skills を追加し、make sync で 2 generated を作成
- root AGENTS.md に shared/ の共有スキル セクションを追記

## テスト

Task 7 の手動テストで以下を確認済み：
- make verify が clean 状態で pass
- shared/ 側を変更 → Drifted を検知
- generated を手編集 → Edited を検知
- revert 後は再び pass

## 関連

- spec: docs/specs/2026-06-23-indie-studio-skill-branch-pr-flow-design.md
- ADR: docs/adr/0005-shared-skills-vendoring.md
- 後続: PR2 で indie-studio 既存 6 SKILL.md の改修 + indie-studio ADR-0031 起稿

🤖 Generated with Claude Code
EOF
)"
```

PR2 は PR1 マージ後にこのブランチを rebase して別ブランチで作業する。

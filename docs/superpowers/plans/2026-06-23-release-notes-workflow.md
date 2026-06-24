# Release Notes Workflow Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** claude-collections に release-drafter + GitHub Releases によるリリースノート運用を導入し、`indie-studio/v0.0.x` 形式の draft Release が main マージごとに自動更新され、ユーザー承認下で Claude Code が publish 操作する状態を作る。

**Architecture:** kissasoft-mcp で実証済みの release-drafter@v6 をベースに、collection 単位で config + workflow を分離し、`paths` filter で対象 collection の PR にのみ反応させる。tag は slash 区切り (`<collection>/v<semver>`) で monorepo 業界標準パターン。autolabeler を有効化し Conventional Commits prefix から自動 label 付与。version-resolver はテスト期は全 patch 固定 (`0.1.0` 自動突入を抑制)、安定化フェーズで本 ADR を extends する別 ADR で書き換え。

**Tech Stack:**
- GitHub Actions (workflow runtime)
- [release-drafter/release-drafter@v6](https://github.com/release-drafter/release-drafter) (draft Release 自動更新)
- [gh CLI](https://cli.github.com/) (publish 操作 / draft 確認)

## Global Constraints

- **spec source**: `docs/superpowers/specs/2026-06-23-release-notes-workflow-design.md` (commit `0c11ef0`)
- **既存規約**: Conventional Commits (`feat:` / `fix:` / `refactor:` / `docs:` / `test:` / `chore:`、scope optional `feat(indie-studio):`)
- **ブランチ**: `docs/add-release-notes-workflow` (base: `main`)
- **worktree path**: `/Users/goto/ghq/github.com/gotomts/claude-collections.docs-add-release-notes-workflow`
- **spec のパス誤記訂正**: spec セクション 6 の「`indie-studio/ROADMAP.md`」は **誤り**。正しくは `indie-studio/docs/ROADMAP.md` (本 plan の Task 5 で正しいパスを使用)
- **tag format**: `<collection>/v<semver>` (slash 区切り)。本 plan では `indie-studio/v0.0.1` から開始
- **テスト期 version**: `v0.0.x` 系厳守。version-resolver は全 label patch 固定で `0.1.0` 自動突入を抑制
- **publish 主体**: Claude Code が判断 + 操作、ただし操作前にユーザー承認を必須とする (`gh release edit --draft=false` 実行前に confirm)
- **commit message**: 各 Task の最終 step で必ず commit、Co-Authored-By trailer 付与

---

## File Structure

| Path | 種別 | 責務 |
|---|---|---|
| `docs/adr/0004-release-notes-workflow.md` | Create | 本 spec の最終決定記録。ADR-0003 を参照 (extends ではない)。後続 ADR (安定化フェーズ移行) はこの ADR を extends する |
| `.github/release-drafter-indie-studio.yml` | Create | release-drafter の `indie-studio` 専用 config (categories / autolabeler / tag-template / version-resolver)。collection 増加時は `release-drafter-<collection>.yml` で同形追加 |
| `.github/workflows/release-drafter-indie-studio.yml` | Create | GitHub Actions workflow。`push: main` + `paths: ['indie-studio/**']` filter で `indie-studio` 関連 PR のマージ時のみ draft 更新。`workflow_dispatch` で手動再実行可 |
| `AGENTS.md` (root) | Modify (append) | 「## リリースノート運用」節を末尾に追加。collection 単位 release / tag 命名 / PR merge 後の publish 判断 trigger 規約 / セッション開始時の未 publish draft 確認 / 月次 draft レビュー / 導入 PR の bootstrap 手順 |
| `indie-studio/docs/ROADMAP.md` | Modify (append) | 「## リリース運用 (ADR-0004)」節を末尾に追加。月次 draft レビュー手順 + 安定化フェーズ移行 TODO (version-resolver 書き換え / plugin.json semver / Breaking category 追加) |

**Task 順序の根拠**: ADR を最初に書いて設計の真実源を確立 (Task 1) → release-drafter の設定本体を作る (Task 2-3) → 運用規約と TODO をドキュメントに反映 (Task 4-5) → PR 作成して bootstrap (Task 6)。Task 1〜5 は相互独立だが、Task 1 の ADR-0004 が後続 Task の参照先になるため最初に固める。Task 6 は全 Task 完了後に必須。

---

## Task 1: ADR-0004 を起草

**Files:**
- Create: `docs/adr/0004-release-notes-workflow.md`

**Interfaces:**
- Consumes: ADR-0003 (`docs/adr/0003-plugin-marketplace-distribution.md` — version 戦略 2 段階移行) を参照
- Produces: 後続 Task 2/3/4/5 の設計根拠 (各ファイルの先頭コメントから ADR-0004 を参照)

- [ ] **Step 1: 既存 ADR 形式の確認**

Run: `head -30 docs/adr/0003-plugin-marketplace-distribution.md`

Expected: タイトル (`#` 1 行) → リード段落 → `## Status` → `## Considered Options` (`### サブセクション` 複数) → `## Consequences` の構造。本 ADR-0004 も同形式に揃える。

- [ ] **Step 2: ADR-0004 を起草**

Create `docs/adr/0004-release-notes-workflow.md` with the following content:

````markdown
# claude-collections のリリースノート運用 (release-drafter + GitHub Releases)

`claude-collections` リポジトリの各 plugin (現状 `indie-studio`、将来追加分も同様) の変更履歴を、install 利用者 (含む自分) が後から追えるようにする。配置は GitHub Releases のみ (リポジトリ内 `CHANGELOG.md` ファイルは持たない)、ツールは [release-drafter@v6](https://github.com/release-drafter/release-drafter) を採用、collection 単位に config (`.github/release-drafter-<collection>.yml`) と workflow を分離、tag は slash 区切り (`<collection>/v<semver>`)、テスト期も `v0.0.x` で実 publish する (version-resolver は全 patch 固定で `0.1.0` 自動突入を抑制)、publish 判断と操作は Claude Code が担い、ユーザー承認下で `gh release edit` 実行、PR merge 後トリガー (AGENTS.md 規約で必須化)。autolabeler を有効化し PR title から Conventional Commits prefix で自動 label 付与 (kissasoft-mcp は autolabeler を見送ったが、claude-collections では導入 PR の手動 label で bootstrap を回避)。categories の見出しは kissasoft-mcp と同形 6 つ (✨ Features / 🐛 Fixes / ♻️ Refactor / 📝 Docs / ✅ Tests / 🔧 Chore)、ただし version-resolver の bump はテスト期は全 patch・安定化フェーズで kissasoft-mcp 同形に書き換える 2 段階移行。

## Status

accepted

## 関連 ADR

- [ADR-0001](0001-multi-collection-repo.md) — 複数コレクション構造 (自己完結原則の根拠)
- [ADR-0003](0003-plugin-marketplace-distribution.md) — plugin marketplace 配布 + version 戦略 2 段階移行 (本 ADR は ADR-0003 を **参照**、extends ではない — version 戦略を変更しない)

## Considered Options

### 配置 / ツール

- **却下：単一 root `CHANGELOG.md`** — install 利用者が自分の plugin の更新だけ追いたい時に他 collection の更新がノイズ。コレクション増加で肥大化。ADR-0001 の自己完結原則と齟齬。
- **却下：collection 単位 `<collection>/CHANGELOG.md`** — ファイル管理コスト、kissasoft-mcp で確立した release-drafter ノウハウを活かせない、安定化フェーズで GitHub Releases に切り替える / 併用するかを再判断必要。
- **却下：手書き運用** — Conventional Commits 採用済みなので自動生成系ツールが使える前提条件は揃っており、手書きは過小自動化。
- **採用：GitHub Releases + release-drafter@v6 のみ** — kissasoft-mcp で動作実績あり、monorepo 複数 app パターン (tag prefix で分離) も実装済み、ADR-0003 の 2 段階移行と同じツール内でシームレス (テスト期 = `v0.0.x` で publish、安定化フェーズ = `v0.1.0` 以降に semver 移行)。

### config 構造

- **却下：集約 1 config (kissasoft-mcp 方式)** — 「publish 前にタグを手動書き換え」運用が必要、collection 2 つ目が増えた瞬間に draft 混在問題が発生、後で分離に移行する二度手間。
- **採用：collection ごとに config 分離 (`.github/release-drafter-<collection>.yml`)** — AGENTS.md / CONTEXT-MAP.md で「複数コレクション」は確定設計。collection 増加は仮定でなく予定。最初から拡張前提の構造。

### tag 命名

- **却下：単一 semver (`v0.1.0`)** — collection 増加で衝突。
- **却下：hyphen 区切り (`indie-studio-v0.1.0`)** — collection 名自体に hyphen を含むと境目が視覚的に判別しにくい (`indie-studio-v…` で `studio` と `v` の区切りが弱い)。
- **採用：slash 区切り (`indie-studio/v0.1.0`)** — Go modules / nx 等 monorepo の業界標準、視覚的に階層が明確、collection 名が hyphen 含んでも誤読しない。

### publish ポリシー

- **却下：完全自動 publish (毎マージで release 積む)** — publish の judgment が消える、release 単位が「1 PR = 1 release」でノイズ多。
- **却下：draft 維持厳守 (テスト期は publish しない)** — テスト期に履歴として残らない、draft 一覧が「いびつ」な体験になる、GitHub の Releases タブの可視性が活かせない。
- **却下：定期スケジュール publish (cron)** — 「先週から変わってないのに publish」のような空 release リスク。
- **採用：区切りで publish、判断と操作は Claude Code がユーザー承認下で実行 (PR merge 後トリガー)** — judgment ポイントが残り release notes の質が上がる、kissasoft-mcp と運用同形 (脳内一貫性)、Claude Code が `gh release` で draft 確認 → 評価 → ユーザー承認後 publish。

### publish 主体

- **却下：人間が完全手動** — claude-collections は AI ハーネス系プロジェクトなので、判断と操作を Claude Code に委ねるのが dogfooding として自然。
- **却下：skill 化 (`/release-publish-check`)** — claude-collections の置き場 (どの collection に属するか) が別 brainstorming 必要で scope creep。
- **却下：cron 自動化** — publish 事故リスク (WIP draft を public 化)、judgment 消失。
- **却下：GitHub Actions + claude-code-action 半自動化** — 今回 spec のスコープを超過、cost / API key / 承認フロー設計が別 spec 必要 (Phase 2 候補として保留)。
- **採用：Claude Code 判断 + ユーザー承認下、PR merge 後トリガー (AGENTS.md 規約化)** — 追加実装ゼロ、Claude Code セッションが PR ブランチ作業中に開いてる前提と整合、publish 承認が人間に残り事故リスク最小、後から GitHub Actions 半自動化に発展可能。

### autolabeler

- **却下：手動付与 (kissasoft-mcp 流)** — kissasoft-mcp はブートストラップ問題 (config を main から読むため導入 PR で autolabeler が動かない) で見送ったが、これは導入 PR 1 回限りの制約で永続採用しない理由にならない。手動は付け忘れリスク常時あり。
- **採用：autolabeler で PR title から自動付与** — Conventional Commits 採用済みなので追加の人間操作なし、付け忘れゼロ、唯一の制約 (導入 PR は autolabeler が動かない) は導入 PR で手動 label 1 回付与すれば回避。

### version-resolver bump

- **却下：kissasoft-mcp 同形 (feat→minor / major→major)** — テスト期 (`v0.0.x` 厳守) で `feat` ラベル含む PR が出ると `0.0.x → 0.1.0` に minor bump し、意図せず安定化フェーズへ突入。
- **採用：テスト期は全 label patch 固定、安定化フェーズで kissasoft-mcp 同形に書き換え** — テスト期は `v0.0.x` 系を厳守、安定化フェーズへの移行は ADR-0003 の境界判断に乗せ、その時点で本 ADR を extends する新 ADR で `feat→minor` 等の bump rule を有効化。

### categories

- **却下：Breaking / Architecture など固有 category 追加** — テスト期 (常に main 追従 = 常に breaking 可能性あり) では Breaking category が機能しない、ADR 用 category は `docs:` prefix と autolabeler パターンが衝突する。
- **採用：kissasoft-mcp 同形 6 categories (見出しのみ流用)** — `feat / fix / refactor / docs / test / chore`。bump rule のみテスト期は全 patch に固定 (上記)。安定化フェーズで Breaking category 追加を別 ADR で記録。

## Consequences

- `.github/release-drafter-indie-studio.yml` + `.github/workflows/release-drafter-indie-studio.yml` の 2 ファイルが追加される。将来 collection 増加時は同形の 2 ファイル追加で拡張 (`release-drafter-<collection>.yml`)。
- root `AGENTS.md` に「## リリースノート運用」節が加わる。内容: PR merge 後の Claude Code セッションで publish 判断を必ず実行 / セッション開始時の未 publish draft 確認 / 月次 draft レビュー (backup) / 導入 PR の bootstrap 手順。
- `indie-studio/docs/ROADMAP.md` に「## リリース運用 (ADR-0004)」セクションが加わる。月次 draft 状態レビューと安定化フェーズ移行 TODO を記録。
- 安定化フェーズ移行時に本 ADR を **extends する新 ADR** を起こす。記録内容: version-resolver を kissasoft-mcp 同形 (`feat→minor` / `major→major`) に書き換え / `💥 Breaking` category 追加 / autolabeler の major 検出パターン追加 / plugin.json semver 明示 (ADR-0003 を extends する形と併せて 1 ADR にまとめても可)。
- 「Phase 2 として GitHub Actions + claude-code-action による半自動化」は session 漏れが頻発 / 外部 contributor 増加で検討。本 ADR を extends する新 ADR で記録。
- 本 ADR は repo 横断の決定 (全 collection 共通の運用ルール) であるため root `docs/adr/` に置く (ADR-0001 「横断決定は root」原則に従う)。
- GitHub Repository Settings → Actions → General → Workflow permissions を **「Read and write permissions」** にする必要がある (release-drafter が draft Release を作成するため `contents: write` が要る。read-only だと 403 で失敗)。
````

- [ ] **Step 3: ADR の相互リンク確認**

Run: `grep -E 'adr/000[1-4]' docs/adr/0004-release-notes-workflow.md`

Expected: ADR-0001 / ADR-0003 への相対リンクが各 1 箇所以上ヒット。リンク先ファイルが存在することを確認 (`ls docs/adr/000{1,3}-*.md`)。

- [ ] **Step 4: commit**

```bash
git add docs/adr/0004-release-notes-workflow.md
git commit -m "$(cat <<'EOF'
docs(adr): 0004 リリースノート運用 (release-drafter + GitHub Releases) を起草

claude-collections のリリースノート運用を決定。配置は GitHub Releases のみ、
ツールは release-drafter@v6、collection 単位 config 分離、slash tag、
テスト期は v0.0.x で実 publish (version-resolver 全 patch 固定)、publish 判断と
操作は Claude Code (ユーザー承認下)、autolabeler 自動付与、6 categories。
ADR-0003 を参照 (extends ではない、version 戦略は変更せず)。

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: release-drafter config を作成

**Files:**
- Create: `.github/release-drafter-indie-studio.yml`

**Interfaces:**
- Consumes: ADR-0004 の決定 (Task 1)、kissasoft-mcp の `.github/release-drafter.yml` をテンプレートとして使用
- Produces: Task 3 の workflow が `config-name` で参照する config

- [ ] **Step 1: `.github/` ディレクトリの存在確認**

Run: `ls -la .github/ 2>&1`

Expected: ディレクトリが無い場合は次 step の Write で自動作成される (新規)。既存の場合はそのまま使う。

- [ ] **Step 2: release-drafter config を作成**

Create `.github/release-drafter-indie-studio.yml` with the following content:

```yaml
# indie-studio コレクション専用の release-drafter 設定 (ADR-0004)。
# tag-template: indie-studio/v$RESOLVED_VERSION (slash 区切り、ADR-0004 採用)
# version-resolver: テスト期は全 label patch 固定 (0.1.0 自動突入を抑制)
# 安定化フェーズ移行時に ADR-0004 を extends する新 ADR で feat→minor に書き換え
# autolabeler: Conventional Commits prefix から自動 label 付与
# 導入 PR は autolabeler が動かない (config を main から読むため) → 導入 PR のみ手動 label

name-template: "indie-studio/v$RESOLVED_VERSION"
tag-template: "indie-studio/v$RESOLVED_VERSION"

categories:
  - title: "✨ Features"
    labels: ["feat"]
  - title: "🐛 Fixes"
    labels: ["fix"]
  - title: "♻️ Refactor"
    labels: ["refactor"]
  - title: "📝 Docs"
    labels: ["docs"]
  - title: "✅ Tests"
    labels: ["test"]
  - title: "🔧 Chore"
    labels: ["chore"]

change-template: "- $TITLE (#$NUMBER) @$AUTHOR"
change-title-escapes: '\<*_&'

# テスト期 (現在): 全 label patch 固定で 0.0.x 系厳守
# 安定化フェーズで本セクションを kissasoft-mcp 同形 (feat→minor / major→major) に書き換え
version-resolver:
  patch:
    labels: ["feat", "fix", "refactor", "docs", "test", "chore", "major"]
  default: patch

# Conventional Commits prefix から自動 label 付与
autolabeler:
  - label: "feat"
    title:
      - "/^feat(\\(.+\\))?:/"
  - label: "fix"
    title:
      - "/^fix(\\(.+\\))?:/"
  - label: "refactor"
    title:
      - "/^refactor(\\(.+\\))?:/"
  - label: "docs"
    title:
      - "/^docs(\\(.+\\))?:/"
  - label: "test"
    title:
      - "/^test(\\(.+\\))?:/"
  - label: "chore"
    title:
      - "/^chore(\\(.+\\))?:/"

template: |
  ## 変更点

  $CHANGES

  **Full Changelog**: https://github.com/$OWNER/$REPONAME/compare/$PREVIOUS_TAG...indie-studio/v$RESOLVED_VERSION
```

- [ ] **Step 3: YAML 構文検証**

Run: `python3 -c "import yaml; yaml.safe_load(open('.github/release-drafter-indie-studio.yml'))" && echo "OK"`

Expected: `OK` が出力される (構文 error なし)。失敗した場合は YAML 構文 (インデント / クォート) を確認。

- [ ] **Step 4: commit**

```bash
git add .github/release-drafter-indie-studio.yml
git commit -m "$(cat <<'EOF'
chore: release-drafter の indie-studio 専用 config を追加 (ADR-0004)

tag-template/name-template を indie-studio/v$RESOLVED_VERSION (slash 区切り)。
version-resolver はテスト期につき全 label patch 固定 (0.1.0 自動突入を抑制)。
autolabeler で Conventional Commits prefix から feat/fix/refactor/docs/test/chore
を自動付与。categories は kissasoft-mcp 同形 6 つ。

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: GitHub Actions workflow を作成

**Files:**
- Create: `.github/workflows/release-drafter-indie-studio.yml`

**Interfaces:**
- Consumes: Task 2 で作った config を `config-name: release-drafter-indie-studio.yml` で参照
- Produces: `push: main` + `paths: ['indie-studio/**']` filter で indie-studio 関連 PR マージ時のみ draft 更新する Action。`workflow_dispatch` で手動再実行可

- [ ] **Step 1: `.github/workflows/` ディレクトリの存在確認**

Run: `ls -la .github/workflows/ 2>&1`

Expected: ディレクトリが無い場合は次 step の Write で自動作成される (新規)。

- [ ] **Step 2: workflow YAML を作成**

Create `.github/workflows/release-drafter-indie-studio.yml` with the following content:

```yaml
# indie-studio コレクションの release-drafter ワークフロー (ADR-0004)。
# main マージごとに draft Release を自動更新。publish は手動 (Claude Code が
# ユーザー承認下で gh release edit を実行)。
#
# paths filter で indie-studio/** の PR にのみ反応 (collection 単位の独立 draft 維持)。
# config (.github/release-drafter-indie-studio.yml) 自身の変更や本 workflow 自身の
# 変更でも draft を更新する (設定修正の即時反映)。
#
# 前提：リポジトリ Settings → Actions → General → Workflow permissions を
# 「Read and write permissions」にしておく (read-only だと contents: write が
# 403 で失敗)。詳細は ADR-0004 Consequences 参照。
#
# workflow_dispatch は設定修正後にドラフトを作り直したい時の手動再実行用。

name: Release Drafter (indie-studio)

on:
  push:
    branches: [main]
    paths:
      - "indie-studio/**"
      - ".github/release-drafter-indie-studio.yml"
      - ".github/workflows/release-drafter-indie-studio.yml"
  workflow_dispatch:

permissions:
  contents: read

jobs:
  update_release_draft:
    permissions:
      contents: write     # draft Release の作成/更新
      pull-requests: read # release-drafter がノート生成のためマージ済み PR を読む
    runs-on: ubuntu-latest
    steps:
      - uses: release-drafter/release-drafter@v6
        with:
          config-name: release-drafter-indie-studio.yml
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

- [ ] **Step 3: YAML 構文検証**

Run: `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/release-drafter-indie-studio.yml'))" && echo "OK"`

Expected: `OK` が出力される。

- [ ] **Step 4: commit**

```bash
git add .github/workflows/release-drafter-indie-studio.yml
git commit -m "$(cat <<'EOF'
chore: release-drafter の indie-studio workflow を追加 (ADR-0004)

push: main + paths: ['indie-studio/**'] filter で indie-studio 関連 PR マージ時
のみ draft 更新。config (.github/release-drafter-indie-studio.yml) 自身の変更や
本 workflow 自身の変更でも draft を再生成。workflow_dispatch で手動再実行可。
permissions は contents:write + pull-requests:read (release-drafter@v6 要件)。

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 4: root AGENTS.md に「リリースノート運用」節を追加

**Files:**
- Modify: `AGENTS.md` (root、末尾に追記)

**Interfaces:**
- Consumes: Task 1 ADR-0004 (リンク参照)
- Produces: root 横断のリリースノート運用規約。Claude Code セッションが AGENTS.md を読んだ際に「PR merge 後の publish 判断」「セッション開始時の draft 確認」を必ず実行するための trigger 規約

- [ ] **Step 1: 既存 AGENTS.md 末尾の確認**

Run: `tail -5 AGENTS.md`

Expected: 末尾は「`indie-studio`：個人開発のサービス設計〜...」で終わるはず。追記場所は末尾 (新セクションを最後に追加)。

- [ ] **Step 2: AGENTS.md に節を追記**

Append the following content to the end of `AGENTS.md` (use Edit tool to add after the last existing line):

```markdown

## リリースノート運用

各コレクションの変更履歴は GitHub Releases に集約する (リポジトリ内 `CHANGELOG.md` ファイルは持たない)。ツールは [release-drafter@v6](https://github.com/release-drafter/release-drafter)、collection 単位に config + workflow を分離 (`.github/release-drafter-<collection>.yml` / `.github/workflows/release-drafter-<collection>.yml`)。設計判断は [`docs/adr/0004`](docs/adr/0004-release-notes-workflow.md)。

### tag 命名

- format: `<collection>/v<semver>` (slash 区切り、例: `indie-studio/v0.0.1`)
- テスト期: `v0.0.x` 系で publish、version-resolver は全 patch 固定 (`0.1.0` 自動突入を抑制)
- 安定化フェーズ: `v0.1.0` 以降 semver (ADR-0004 を extends する新 ADR で切り替え)

### publish 判断 (PR merge 後 trigger)

PR を main に merge した直後の Claude Code セッションで、publish 判断を **必ず実行する**:

1. `gh release list --repo gotomts/claude-collections` で対象 collection の draft を確認
2. `gh release view --repo gotomts/claude-collections <tag-name>` で draft 内容を確認
3. 内容のまとまり (機能完成 / 数 PR 蓄積 / リファクタ完了 / docs まとめ等) を評価し publish 推奨 or 待機を提案
4. ユーザー承認後、`gh release edit --repo gotomts/claude-collections <tag-name> --draft=false` で publish 実行

### Backup 1: セッション開始時の未 publish draft 確認

Claude Code セッション開始時に未 publish draft の有無を確認し、溜まっている場合は publish 判断を proactively 提案する。`gh release list --repo gotomts/claude-collections` で状態確認。

### Backup 2: 月次 draft レビュー

月次で draft 状態を人間がレビューする。詳細は各コレクションの `ROADMAP.md` (例: `indie-studio/docs/ROADMAP.md` の「リリース運用」セクション)。

### 導入 PR の bootstrap

release-drafter は config をデフォルトブランチ (main) から読むため、本ワークフローを導入する PR / 設定追加の PR では autolabeler が動かない。導入 PR は手動で label を付与する (例: `docs` / `chore`)。
```

- [ ] **Step 3: 追記内容の確認**

Run: `tail -40 AGENTS.md`

Expected: 「## リリースノート運用」見出しと「導入 PR の bootstrap」の節までが表示される。

- [ ] **Step 4: commit**

```bash
git add AGENTS.md
git commit -m "$(cat <<'EOF'
docs: AGENTS.md にリリースノート運用節を追記 (ADR-0004)

PR merge 後の Claude Code セッションで publish 判断を必ず実行する trigger
規約、セッション開始時の未 publish draft 確認 (backup 1)、月次 draft レビュー
(backup 2)、導入 PR の手動 label bootstrap 手順を明記。

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 5: indie-studio/docs/ROADMAP.md に「リリース運用」節を追加

**Files:**
- Modify: `indie-studio/docs/ROADMAP.md` (末尾に追記)

**Interfaces:**
- Consumes: Task 1 ADR-0004 / Task 4 AGENTS.md 規約 (リンク参照)
- Produces: indie-studio 固有の月次レビュー手順と安定化フェーズ移行 TODO

- [ ] **Step 1: 既存 ROADMAP.md 末尾の確認**

Run: `tail -10 indie-studio/docs/ROADMAP.md`

Expected: 末尾は「## 残る実装レベルの論点」の bullet list で終わるはず。追記場所は末尾 (新セクションを最後に追加)。

- [ ] **Step 2: ROADMAP.md に節を追記**

Append the following content to the end of `indie-studio/docs/ROADMAP.md`:

```markdown

## リリース運用 (ADR-0004)

`indie-studio` の変更履歴は GitHub Releases (`indie-studio/v0.0.x` 系) に集約する。設定は `.github/release-drafter-indie-studio.yml` + `.github/workflows/release-drafter-indie-studio.yml`、運用規約 (PR merge 後の publish 判断 trigger / セッション開始時の draft 確認 / 導入 PR の bootstrap) は root [`AGENTS.md`](../../AGENTS.md) の「## リリースノート運用」節を参照。

### 月次 draft レビュー (backup 2)

毎月 1 回、以下のコマンドで未 publish draft を確認し、必要に応じて publish 判断する:

```bash
gh release list --repo gotomts/claude-collections | grep 'indie-studio/'
```

PR merge 後の Claude Code セッションでの判断 (primary)、セッション開始時の確認 (backup 1) でも漏れた case の最終 safety net。

### 安定化フェーズ移行時の TODO

ADR-0003 の version 戦略 2 段階移行で `indie-studio` を安定化フェーズに切り替える際:

- `indie-studio/.claude-plugin/plugin.json` に `version: "0.1.0"` を明示 (ADR-0003 を extends する新 ADR)
- `.github/release-drafter-indie-studio.yml` の `version-resolver` を kissasoft-mcp 同形 (`feat→minor` / `major→major`) に書き換え (ADR-0004 を extends する新 ADR)
- `💥 Breaking` category を追加、autolabeler の major 検出パターン追加 (同上)
- 上記 ADR を 1 本にまとめても可
```

- [ ] **Step 3: 追記内容の確認**

Run: `tail -25 indie-studio/docs/ROADMAP.md`

Expected: 「## リリース運用 (ADR-0004)」と TODO リストが表示される。

- [ ] **Step 4: commit**

```bash
git add indie-studio/docs/ROADMAP.md
git commit -m "$(cat <<'EOF'
docs(indie-studio): ROADMAP にリリース運用節を追記 (ADR-0004)

月次 draft レビュー (backup 2) のコマンドと、安定化フェーズ移行時の TODO
(plugin.json semver / version-resolver 書き換え / Breaking category 追加) を
記録。運用規約本体は root AGENTS.md の「リリースノート運用」節を参照。

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 6: PR 作成 + bootstrap publish 検証

**Files:** なし (操作と検証のみ)

**Interfaces:**
- Consumes: Task 1〜5 の全成果物
- Produces: `indie-studio/v0.0.1` の初回 GitHub Release (publish 済み)

- [ ] **Step 1: 全 YAML を最終検証**

Run: `python3 -c "import yaml; yaml.safe_load(open('.github/release-drafter-indie-studio.yml')); yaml.safe_load(open('.github/workflows/release-drafter-indie-studio.yml'))" && echo "OK"`

Expected: `OK` が出力される。

- [ ] **Step 2: GitHub Repository Workflow permissions の確認**

事前確認 (ユーザー作業):
- GitHub UI で `Settings → Actions → General → Workflow permissions` が **「Read and write permissions」** になっていることを確認
- 「Read repository contents and packages permissions」のみだと release-drafter が `contents: write` で 403 失敗する

確認方法 (CLI):
```bash
gh api repos/gotomts/claude-collections/actions/permissions/workflow
```

Expected: `"default_workflow_permissions": "write"` が返ってくる。`"read"` なら GitHub UI から手動切り替え。

- [ ] **Step 3: ブランチを push**

```bash
git push -u origin docs/add-release-notes-workflow
```

Expected: push 成功、tracking 設定。

- [ ] **Step 4: PR を作成**

```bash
gh pr create --title "feat: claude-collections にリリースノート運用 (release-drafter + GitHub Releases) を導入 (ADR-0004)" --body "$(cat <<'EOF'
## Summary

- ADR-0004 を起草。配置は GitHub Releases のみ、ツールは release-drafter@v6、collection 単位 config 分離、slash tag (`indie-studio/v<semver>`)、テスト期は `v0.0.x` で実 publish、publish 判断と操作は Claude Code (ユーザー承認下)、autolabeler 自動付与、kissasoft-mcp 同形 6 categories。
- `.github/release-drafter-indie-studio.yml` + `.github/workflows/release-drafter-indie-studio.yml` を追加。`paths: ['indie-studio/**']` filter で collection 単位の独立 draft を維持。
- root `AGENTS.md` に「## リリースノート運用」節を追記 (PR merge 後の publish 判断 trigger / セッション開始時の draft 確認 / 月次 draft レビュー / 導入 PR の bootstrap 手順)。
- `indie-studio/docs/ROADMAP.md` に「## リリース運用 (ADR-0004)」節を追記 (月次レビュー手順 + 安定化フェーズ移行 TODO)。

仕様の根拠は `docs/superpowers/specs/2026-06-23-release-notes-workflow-design.md` (commit 0c11ef0)、実装計画は `docs/superpowers/plans/2026-06-23-release-notes-workflow.md`。

## Bootstrap 注意

本 PR は release-drafter 導入 PR のため autolabeler が動かない (release-drafter は config を main から読むため)。merge 前に手動で `docs` ラベルを付与する必要あり (本 PR は主に ADR + 規約追加のため `docs` 相当)。

## Test plan

- [ ] YAML 構文 OK (`python3 -c "import yaml; yaml.safe_load(...)" `)
- [ ] GitHub Repository Settings → Actions → Workflow permissions = Read and write
- [ ] 本 PR に手動で `docs` ラベルを付与
- [ ] PR merge 後、`Release Drafter (indie-studio)` workflow が成功
- [ ] `gh release list` で `indie-studio/v0.0.1` の draft が作成されている (デフォルトで draft 含む)
- [ ] `gh release view indie-studio/v0.0.1` で本 PR の変更が「📝 Docs」もしくは「🔧 Chore」カテゴリに表示
- [ ] Claude Code がユーザー承認下で `gh release edit indie-studio/v0.0.1 --draft=false` を実行し初回 publish 完了

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

Expected: PR URL が出力される。

- [ ] **Step 5: 導入 PR に手動 label 付与**

```bash
gh pr edit --add-label "docs" $(gh pr view --json number -q .number)
```

Expected: ラベル付与成功。autolabeler は次 PR 以降で動作するため、本 PR のみ手動。

- [ ] **Step 6: PR merge 後の workflow 確認**

PR merge をユーザーが完了させた後 (review → squash or merge commit):

```bash
gh run list --workflow="Release Drafter (indie-studio)" --limit 3
```

Expected: 最新 run の `status: completed`、`conclusion: success`。失敗時は `gh run view <run-id> --log` で詳細確認。

- [ ] **Step 7: draft Release の存在確認**

```bash
gh release list --repo gotomts/claude-collections
```

Expected: `indie-studio/v0.0.1` の draft が一覧に存在。

- [ ] **Step 8: draft 内容の確認**

```bash
gh release view indie-studio/v0.0.1 --repo gotomts/claude-collections
```

Expected: 本 PR のタイトルが「📝 Docs」カテゴリ配下に表示される (PR title は `feat:` 接頭辞だが、本 PR は手動で `docs` label を付けたので Docs に分類される。または `feat` label 自動付与で Features に分類される — 実際の表示で確認)。

- [ ] **Step 9: 初回 publish (ユーザー承認下)**

ユーザーに承認確認:
> 「`indie-studio/v0.0.1` の draft 内容を確認しました。これを初回 publish して claude-collections のリリースノート運用を正式に開始しても良いですか? (Y/n)」

ユーザーが Y で承認した場合:
```bash
gh release edit indie-studio/v0.0.1 --draft=false --repo gotomts/claude-collections
```

Expected: 「published」となる。GitHub UI の Releases タブで公開状態を確認可能。

- [ ] **Step 10: publish 完了の最終確認**

```bash
gh release view indie-studio/v0.0.1 --repo gotomts/claude-collections --json isDraft,tagName,name
```

Expected: `{"isDraft": false, "tagName": "indie-studio/v0.0.1", "name": "indie-studio/v0.0.1"}`。

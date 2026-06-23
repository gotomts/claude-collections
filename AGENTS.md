# AGENTS.md（claude-collections リポジトリ・正本）

このリポジトリは**複数のスキル+エージェント集（コレクション）**をホストする（root `docs/adr/0001`）。エージェントが本リポジトリで作業するときの規約を定める。`CLAUDE.md` は本ファイルを参照する薄いポインタ。

## 構成規約

- 各コレクションは `<collection>/` 配下に**自己完結**する：`skills/`・`agents/`・`docs/adr/`・`CONTEXT.md`・`ROADMAP.md`・`.claude-plugin/plugin.json`。
- root には repo 横断の `AGENTS.md`（本ファイル）・`CLAUDE.md`（ポインタ）・`CONTEXT-MAP.md`（コレクション索引）・`docs/adr/`（横断決定）・`.claude-plugin/marketplace.json`（plugin marketplace 宣言）。
- コレクション一覧と所在は `CONTEXT-MAP.md`。
- 配布構造（marketplace + 各 plugin）の決定は [`docs/adr/0003`](docs/adr/0003-plugin-marketplace-distribution.md)。

## スキル/エージェントを足す・直すとき

- 該当コレクションの `<collection>/skills/<skill>/SKILL.md` ／ `<collection>/agents/<name>.md` に置く（root 直下に置かない）。
- **エージェントは実在職種名で**設計する（成果物名・概念で割らない）。
- スキル/エージェントは frontmatter の `name` で識別・起動される（`subagent_type` も `name` 参照・path 非依存）。ディレクトリを深くしても呼び出しは壊れない。
- 設計判断は該当コレクションの `docs/adr/` を読む。決定は inline／git／ADR に残す（専用の決定ログ file は作らない）。

## 既存コレクション

- **`indie-studio`**：個人開発のサービス設計〜デザイン〜開発を自律で回すハーネス。設計の真実源は `indie-studio/CONTEXT.md` と `indie-studio/docs/adr/`。

## リリースノート運用

各コレクションの変更履歴は GitHub Releases に集約する (リポジトリ内 `CHANGELOG.md` ファイルは持たない)。ツールは [release-drafter@v6](https://github.com/release-drafter/release-drafter)、collection 単位に config + workflow を分離 (`.github/release-drafter-<collection>.yml` / `.github/workflows/release-drafter-<collection>.yml`)。設計判断は [`docs/adr/0004`](docs/adr/0004-release-notes-workflow.md)。

### tag 命名

- format: `<collection>/v<semver>` (slash 区切り、例: `indie-studio/v0.0.1`)
- テスト期: `v0.0.x` 系で publish、version-resolver は全 patch 固定 (`0.1.0` 自動突入を抑制)
- 安定化フェーズ: `v0.1.0` 以降 semver (ADR-0004 を extends する新 ADR で切り替え)

### publish 判断 (PR merge 後 trigger)

PR を main に merge した直後の Claude Code セッションで、publish 判断を **必ず実行する**:

1. `gh release list --include-drafts --repo gotomts/claude-collections` で対象 collection の draft を確認
2. `gh release view --repo gotomts/claude-collections <tag-name>` で draft 内容を確認
3. 内容のまとまり (機能完成 / 数 PR 蓄積 / リファクタ完了 / docs まとめ等) を評価し publish 推奨 or 待機を提案
4. ユーザー承認後、`gh release edit --repo gotomts/claude-collections <tag-name> --draft=false` で publish 実行

### Backup 1: セッション開始時の未 publish draft 確認

Claude Code セッション開始時に未 publish draft の有無を確認し、溜まっている場合は publish 判断を proactively 提案する。`gh release list --include-drafts --repo gotomts/claude-collections` で状態確認。

### Backup 2: 月次 draft レビュー

月次で draft 状態を人間がレビューする。詳細は各コレクションの `ROADMAP.md` (例: `indie-studio/docs/ROADMAP.md` の「リリース運用」セクション)。

### 導入 PR の bootstrap

release-drafter は config をデフォルトブランチ (main) から読むため、本ワークフローを導入する PR / 設定追加の PR では autolabeler が動かない。導入 PR は手動で label を付与する (例: `docs` / `chore`)。

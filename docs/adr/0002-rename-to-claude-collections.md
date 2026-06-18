# リポジトリ名を `agents` から `claude-collections` に改名

`agents` という repo 名は、ADR-0001 で導入したコレクション層（複数の skill+agent コレクションをホストする）と、agents だけでなく skills も含むという repo の実態を表現できていなかった。`claude-collections` に改名する。GitHub 側は永続リダイレクトされ、PR・clone は新旧 URL どちらでも到達可能。

## Status

accepted

## Considered Options

- **却下：`agents`（現状）** — skills と「コレクションをホストする」上位層が見えない。ADR-0001 と乖離。
- **却下：`harness-collections`** — 「harness」は `indie-studio` コレクション（G1-G5 / S1-S5 のオーケストレーション付き）の設計思想であって、repo 全体の本質ではない。将来のコレクションが harness とは限らない（単発の review/docs/design skill セット等）。
- **却下：`skill-collections` / `agent-collections`** — プラットフォーム中立だが、現状のサブエージェント機構（`tools`・`model`・`color` frontmatter／Task tool による spawn／`subagent_type` 参照）は Claude Code 前提という実態を隠してしまう。SKILL.md フォーマット自体は Codex/Copilot/Gemini にも広がりつつあるが、agents 側は Claude 寄りのままなので、現時点で中立名を選ぶのは前倒し。
- **採用：`claude-collections`** — ADR-0001 のコレクション構造と1:1で対応し、Claude Code 前提という現状の実装と整合する。将来クロスプラットフォーム化が進んだら改名は再検討する。

## Consequences

- GitHub の旧 URL（`gotomts/agents`）は永続リダイレクトでアクセス可能。既存 PR（例 PR #2）の URL もリダイレクト経由で生存。
- ローカルクローンパス（ghq）は `~/ghq/github.com/gotomts/claude-collections` に再配置する。`git remote set-url` で remote URL も更新。
- 既存 ADR は履歴として保全し、本文は触らない。改名時点で意味のずれが大きくなる箇所（[indie-studio/docs/adr/0009](../../indie-studio/docs/adr/0009-agents-repo-as-harness-home.md)）には冒頭ノートで本 ADR への接続を残す。
- repo 名をハードコードしている外部参照（dotfiles の配送設定、`~/.claude` への symlink/登録計画、CI/CD 等）は新名で揃える。

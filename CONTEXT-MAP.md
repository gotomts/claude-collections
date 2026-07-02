# CONTEXT-MAP

`claude-collections` リポジトリは Claude Code 用のスキル+エージェント集（コレクション）を複数ホストする（root `docs/adr/0001`）。各コレクションは自己完結し、自分の `CONTEXT.md`（ユビキタス言語）と `docs/adr/`（設計判断）を持つ。本マップは各コレクションの所在を指す索引。

## コレクション

| コレクション | 概要 | CONTEXT | ADR |
|---|---|---|---|
| [`indie-studio`](indie-studio/) | 個人開発のサービス設計〜デザイン〜開発をオールインで回す AI 自律開発ハーネス（G1 アンカー / S1 企画→ブリーフ / S2 プロトタイプ / S3 技術設計 / S4 分解 / S5 実装） | [`indie-studio/CONTEXT.md`](indie-studio/CONTEXT.md) | [`indie-studio/docs/adr/`](indie-studio/docs/adr/) |
| [`enhance-superpowers`](enhance-superpowers/) | superpowers (公式) を base に、Spec フェーズで 5 成果物 (summary/design/gwt/pr-description/plan) を plan-last 順序で確定 (design/gwt/pr-description は Phase 3 でまとめ生成、ADR-0011)、後工程 (gwt-test / write-review-response / finish-spec-pr) を連鎖駆動。agent 能動 dispatch + 監査ログ (dispatch log) + セキュリティレビュー (2 層) + コンプライアンス trigger (機微情報 / ライセンス / AI 利用ポリシー) を内包 | [`enhance-superpowers/CONTEXT.md`](enhance-superpowers/CONTEXT.md) | [`enhance-superpowers/docs/adr/`](enhance-superpowers/docs/adr/) |

## shared/

- 真実源として `shared/agents/` と `shared/skills/` を持つ。コレクションではなく **vendoring の元データ**（ADR-0004 / ADR-0005）。
- 各コレクションが `dependencies.json` で pick し、`make sync` で `<collection>/agents/` および `<collection>/skills/` に generated file として展開される。
- agents の現状の中身：engineering 系 13 エージェント（executor 5 + quality 4 + leadership 4）。indie-studio は全 13 体、enhance-superpowers は 4 体 (code-reviewer / qa-engineer / software-architect / security-engineer) を取り込み。
- skills の現状の中身：start-stage-branch (branch + worktree helper) / finish-stage-pr (push + PR open helper、enhance-superpowers 取り込み時に body-source-path 引数拡張で後方互換改修)。
- 配布対象外（marketplace.json には列挙しない）。install 先には流れない。

## repo 横断

- 構成規約・コレクションの足し方 → root [`AGENTS.md`](AGENTS.md)
- repo 横断の決定 → root [`docs/adr/`](docs/adr/)

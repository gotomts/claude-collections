# CONTEXT-MAP

`claude-collections` リポジトリは Claude Code 用のスキル+エージェント集（コレクション）を複数ホストする（root `docs/adr/0001`）。各コレクションは自己完結し、自分の `CONTEXT.md`（ユビキタス言語）と `docs/adr/`（設計判断）を持つ。本マップは各コレクションの所在を指す索引。

## コレクション

| コレクション | 概要 | CONTEXT | ADR |
|---|---|---|---|
| [`indie-studio`](indie-studio/) | 個人開発のサービス設計〜デザイン〜開発をオールインで回す AI 自律開発ハーネス（G1 アンカー / S1 企画→ブリーフ / S2 プロトタイプ / S3 技術設計 / S4 分解 / S5 実装） | [`indie-studio/CONTEXT.md`](indie-studio/CONTEXT.md) | [`indie-studio/docs/adr/`](indie-studio/docs/adr/) |

## shared/

- 真実源として `shared/agents/` を持つ。コレクションではなく **vendoring の元データ**（ADR-0004）。
- 各コレクションが `dependencies.json` で pick し、`make sync` で `<collection>/agents/` に generated file として展開される。
- 現状の中身：engineering 系 13 エージェント（executor 5 + quality 4 + leadership 4）。
- 配布対象外（marketplace.json には列挙しない）。install 先には流れない。

## repo 横断

- 構成規約・コレクションの足し方 → root [`AGENTS.md`](AGENTS.md)
- repo 横断の決定 → root [`docs/adr/`](docs/adr/)

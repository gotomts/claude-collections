# CONTEXT-MAP

`claude-collections` リポジトリは Claude Code 用のスキル+エージェント集（コレクション）を複数ホストする（root `docs/adr/0001`）。各コレクションは自己完結し、自分の `CONTEXT.md`（ユビキタス言語）と `docs/adr/`（設計判断）を持つ。本マップは各コレクションの所在を指す索引。

## コレクション

| コレクション | 概要 | CONTEXT | ADR |
|---|---|---|---|
| [`indie-studio`](indie-studio/) | 個人開発のサービス設計〜デザイン〜開発をオールインで回す AI 自律開発ハーネス（G1 アンカー / S1 企画→ブリーフ / S2 プロトタイプ / S3 技術設計 / S4 分解 / S5 実装仕様→委譲） | [`indie-studio/CONTEXT.md`](indie-studio/CONTEXT.md) | [`indie-studio/docs/adr/`](indie-studio/docs/adr/) |
| [`enhance-superpowers`](enhance-superpowers/) | superpowers (公式) を base に、Spec フェーズで 5 成果物 (summary/design/gwt/pr-description/plan) を plan-last 順序で確定 (design/gwt/pr-description は Phase 3 でまとめ生成、enhance-superpowers ADR-0011)、実装フェーズは enhance-executing-plans (enhance-superpowers ADR-0012)、後工程 (gwt-test / write-review-response / finish-spec-pr) を連鎖駆動。全 skill に Step 0 状態判定 (enhance-superpowers ADR-0012) + agent 能動 dispatch (silent failure 回避) + 監査ログ (dispatch log) + セキュリティレビュー (2 層) + コンプライアンス trigger (機微情報 / ライセンス / AI 利用ポリシー) を内包 | [`enhance-superpowers/CONTEXT.md`](enhance-superpowers/CONTEXT.md) | [`enhance-superpowers/docs/adr/`](enhance-superpowers/docs/adr/) |

## shared

- **3 つ目の plugin**（ADR-0009・marketplace.json に列挙）。`shared/agents/` と `shared/skills/` を**単一の実体**として提供する。vendoring（`make sync` による複製）は廃止した。
- agents の現状の中身：13 エージェント。実装 5 体 (backend-engineer / frontend-engineer / mobile-engineer / infrastructure-engineer / performance-engineer) + レビュー 4 体 (code-reviewer / reviewer / qa-engineer / security-engineer) + 設計・統括 4 体 (software-architect / tech-lead / engineering-manager / principal-engineer)。**shared/agents/ は collection 非依存の中立語彙で書く**（root ADR-0004 から継承した中立語彙原則）。collection 固有 context (ステージ番号 / 参照 docs パス / 進行 protocol 等) は呼び出し元 skill が invocation 時に prompt で渡す。**コードレビュー activity は `code-review` skill (CodeRabbit) を default**、`shared:code-reviewer` agent は判定 aid 専用に予約 (enhance-superpowers ADR-0013)。
- skills の現状の中身：start-stage-branch (branch + worktree helper) / finish-stage-pr (push + PR open helper、body-source-path 引数で呼び出し元の PR 本文を差し替え可能)。
- **参照は修飾名で**：`shared:software-architect` / `shared:finish-stage-pr` のように `plugin:name` 形式で書く。**agent は bare name が解決されないため修飾必須**、skill は名前空間が効く（同名 skill は共存できる）が、表記を揃えるため同じく修飾形を使う（ADR-0009）。
- indie-studio / enhance-superpowers を使う場合は **install 必須の依存**。

## repo 横断

- 構成規約・コレクションの足し方 → root [`AGENTS.md`](AGENTS.md)
- repo 横断の決定 → root [`docs/adr/`](docs/adr/)

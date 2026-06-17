# リポジトリは複数のスキル+エージェント集をコレクション単位で持つ

`agents` リポジトリは単一のスキル+エージェント集ではなく、**複数のコレクション**をホストする。各コレクションは `<collection>/` 配下に**自己完結**する（自分の `skills/`・`agents/`・`docs/adr/`・`CONTEXT.md`・`ROADMAP.md` を持つ＝モノレポ的）。root には repo 横断の規約（`AGENTS.md`）・索引（`CONTEXT-MAP.md`）・横断決定（`docs/adr/`）を置く。初コレクションは `indie-studio`（個人開発のサービス設計〜デザイン〜開発をオールインで回す AI 自律開発ハーネス）。

## Status

accepted

## Considered Options

- **却下：単一コレクションの flat 構成**（`skills/`・`agents/` を root 直下）。将来別のコレクションを足せず、「様々なスキル+エージェント集をホストする」という目的に反する。
- **却下：型優先**（`skills/<collection>/`・`agents/<collection>/`）。コレクションが skills と agents に分断され、1ユニットとして自己完結しない。
- **採用：コレクション優先**（`<collection>/{skills,agents,docs,CONTEXT.md}`）。各コレクションが1つの自己完結ユニット。

## Consequences

- 新コレクションは `<collection>/` 配下に `skills/`・`agents/`・`docs/adr/`・`CONTEXT.md` を足し、`CONTEXT-MAP.md` に登録する。
- スキル/エージェントは frontmatter の `name` で識別・起動されるため（`subagent_type` も `name` 参照・path 非依存）、コレクション配下に深くしても呼び出しは壊れない。
- **配送**（`~/.claude` への symlink/登録）は複数コレクションを横断して集約する必要がある（要対応・各コレクションの ROADMAP 参照）。
- コレクション固有の設計判断はそのコレクションの `docs/adr/` に、repo 横断の規約は root の `AGENTS.md` と `docs/adr/` に置く。

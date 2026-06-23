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

## shared/ の共有エージェント

- engineering 系（executor / quality / leadership）の共通エージェントは `shared/agents/` を真実源とする（ADR-0004）。
- 各コレクションは `<collection>/.claude-plugin/dependencies.json` の `shared.agents[]` で取り込み宣言する。
- 取り込みの実体化は `make sync COLLECTION=<name>` で指定 collection を sync。`make sync` 単独実行時は TTY なら interactive picker（all/各 collection を選択）、非 TTY（CI/pipe）なら全 collection を一括 sync。`<collection>/agents/<name>.md` に generated file が書き出される（frontmatter に `x-source` / `x-source-hash` / `x-synced-at` を持つ）。
- generated file は **手編集禁止**。shared 側を編集して `make sync` で反映させる。
- `make verify` で drift を機械的に検知（CI も実行）。手元での確認は `make status`。
- shared/agents/ の編集 PR では、影響を受ける全 collection の generated を `make sync` で更新してから commit する。CI verify が忘れを構造的に防ぐ。
- コレクション固有のエージェント（例：indie-studio の business-strategist 等）は従来通り `<collection>/agents/` に手書きで置く。shared/ と同名にしないこと。

## 既存コレクション

- **`indie-studio`**：個人開発のサービス設計〜デザイン〜開発を自律で回すハーネス。設計の真実源は `indie-studio/CONTEXT.md` と `indie-studio/docs/adr/`。

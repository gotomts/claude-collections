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

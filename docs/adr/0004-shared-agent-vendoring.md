# 共有エージェントは shared/ を真実源とする vendoring 方式で配布する

collection 間で共通利用したいエージェント（engineer 系・reviewer 系等）は、リポジトリ root の `shared/agents/` を**真実源**とし、各 collection は `<collection>/.claude-plugin/dependencies.json` で**取り込みたいエージェントを宣言**する。実体化は `scripts/sync-shared.sh` が generated file として `<collection>/agents/` に書き出し、CI で drift を検知する。ADR-0003（リポジトリ = marketplace、各 collection = 1 plugin）を extends する。rules（CLAUDE.md 相当の規約文）は当面 collection 内で完結させ、本 ADR の対象外とする。

## Status

accepted（[ADR-0003](0003-plugin-marketplace-distribution.md) を extends：plugin 境界をまたいで agent を共有する手段を追加）

## Considered Options

### 共有手段

- **却下：shared-agents を独立 plugin として marketplace に列挙**。install 依存が `marketplace.json` から見えず README 運用に依存する。collection ごとに必要な agent が異なる（indie-studio は engineer + reviewer 系、別 collection は reviewer のみ等）という要件に対して all-or-nothing で粒度不一致。`name` グローバル名前空間で agent が衝突するリスクもある。
- **却下：root の `_shared/agents/` を各 collection に symlink**。git の symlink 追跡は OS/filesystem 依存で fragile（Windows・network filesystem・pencil 等の外部ツールが symlink を解決できる保証なし）。`install 先に余計なものを流さない`（ADR-0003）原則と整合させづらい。
- **却下：永続的に手動コピペ**。drift が機械的に検知できず、shared 更新と collection への反映が静かにズレる。複数 collection で同じ agent を持つ運用は破綻する。
- **採用：vendoring（宣言的依存 + ツール実体化 + CI verify）**。Go vendor / Rust cargo / npm の package-lock と同型の枯れたパターン。collection ごとに必要な agent を pick でき、真実源は 1 箇所、drift は CI で機械的に保証される。

### 真実源の所在

- **却下：各 collection に重複定義**。同一 agent が複数箇所に存在し、修正が散らばる。「共有で育てたい」動機と矛盾。
- **採用：リポジトリ root の `shared/agents/`**。collection ではない（`marketplace.json` に列挙しない）、単なる真実源ディレクトリ。Claude Code から見ると install 対象外。

### 取り込み宣言の場所

- **却下：`plugin.json` 内に専用フィールド**（`x-shared-deps` 等）。plugin.json は JSON Schema 制約があり、未知フィールドを足すと marketplace 検証で警告される可能性。責務分離としても plugin 配布メタと vendoring 依存は別物。
- **採用：`<collection>/.claude-plugin/dependencies.json`**（plugin.json と同階層の別ファイル）。`shared.agents[]` にファイル basename（`backend-engineer` 等）を列挙。存在しない名前は sync 時に error。

### 実体化方式

- **却下：sync 時のみ実体化し git に commit しない**（generated file を `.gitignore`）。install 先で sync を再実行できない（Claude Code plugin は build step を持たない）ため、配布物として成立しない。
- **採用：generated file を git commit する**。`<collection>/agents/<name>.md` は generated だが tracked。理由：(1) plugin install 先で再生成不能、(2) PR で人間が差分レビューできる、(3) CI の verify 対象になる。

### drift 検知方式

- **却下：sync 実行の手動運用のみ**。reviewer や CI が機械的に検知できないため、shared 更新と collection 反映の乖離を防げない。
- **採用：`scripts/sync-shared.sh verify` を CI で実行**。lock ファイル（`<collection>/.claude-plugin/dependencies.lock.json`）に各 synced ファイルの source path と SHA256 を記録し、(a) shared/ の現在 hash と lock の source hash、(b) lock の output hash と <collection>/agents/ の現在 hash、両方を比較。差分があれば PR を fail させる。

### generated file の識別方式

- **却下：先頭にコメントブロックを置く**（`<!-- generated -->` 等）。Claude Code の agent loader が frontmatter より前のコメントをどう扱うか未確定。frontmatter parser が破綻するリスク。
- **採用：frontmatter 内に `x-source` / `x-source-hash` / `x-synced-at` を埋める**。`x-` prefix は未知フィールドの慣習。Claude Code は frontmatter の未知フィールドを無視する想定（公式仕様で明示されていない点はリスクとして残るが、実装上は `name`・`description`・`tools` 等の既知フィールドのみ参照しているため安全）。

### rules の扱い

- **却下：本 ADR と同じ vendoring 方式で `shared/rules/` を導入**。現状 collection は indie-studio 1 つで rule 重複が存在しない。抽象化が空中戦になる。YAGNI。
- **採用：collection 内で完結（`<collection>/CLAUDE-rules.md` に直接記述）**。host への適用は手動コピペ。将来 collection が増えて rule 重複が発生した時点で、本 ADR を extends する形で `shared/rules/` への昇格を別 ADR で記録する。

## Consequences

- 新 collection 追加時の手順は `<collection>/.claude-plugin/dependencies.json` を書き、`scripts/sync-shared.sh` を実行するだけ。pick したエージェントが `<collection>/agents/` に generated file として現れる。collection 固有のエージェント（例：indie-studio の `business-strategist`）は同ディレクトリに**手書きで**共存させる（generated file は frontmatter の `x-source` で識別可能、手書きは持たない）。
- `shared/agents/<name>.md` を更新したら、それを pick している全 collection で `sync-shared.sh update` を実行し、generated file 群を更新する PR を出す必要がある。CI の verify でブロックされるため、忘れは構造的に防がれる。
- generated file は git tracked なので、PR diff に「shared 更新 1 件 + 各 collection の generated 更新 N 件」が並ぶ。レビュー時の認知負荷は若干上がるが、(1) 共有変更の影響範囲が一目で見える、(2) install 先での再実行が不要、というメリットの方が大きい。
- `shared/agents/` 配下のエージェントと collection 固有エージェントで **`name` 衝突は禁止**。sync が error で停止する。命名規約は `shared/` のものを「役職名そのまま」、collection 固有を「役職名 + 文脈接頭辞」とする等で衝突を避ける（具体規約は本 ADR の対象外、運用で詰める）。
- 本 ADR は agents のみを対象とする。rules は collection 内完結で進め、痛みが出たら別 ADR で `shared/rules/` を導入する。`shared/skills/` は要望が出ていないため未検討（同じ vendoring パターンを適用可能だが、現時点で先回りはしない）。
- `scripts/sync-shared.sh` の実装言語は bash + jq とする（依存最小、macOS は brew で簡単に導入可）。サブコマンドは `install` / `update` / `verify` / `status` の 4 つ。実装仕様は本 ADR の決定の範囲を超えるため、別途 README または `scripts/README.md` で詳述する。
- 本 ADR は repo 横断の決定（複数 collection 共通の vendoring 機構）であるため、root の `docs/adr/` に置く（ADR-0001 の「横断決定は root」原則に従う）。

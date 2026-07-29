# 0009. shared/ を plugin 化し、agent の vendoring を廃止する

## Status

Accepted (2026-07-28)。ADR-0004 (shared-agent-vendoring) と ADR-0005 (shared-skills-vendoring) を **supersede** する。**ADR-0003 が定めた配布構造** (リポジトリ = 1 marketplace、各コレクション = 1 plugin) はそのまま継承し、marketplace に配る plugin を 2 個から 3 個に増やす。

> 注記 (2026-07-28)：本 ADR の初版は配布経路を「ADR-0003 / ADR-0008 が定めた local path + public repo の二経路」と書いていたが、ここで参照していた**旧 ADR-0008（`public-repo-distribution`）は非-decision の誤記録として PR #30 で削除済み**だった（外部 consumer サポートを決めた事実が無いのに、それを決定として記録していたため）。よって本 ADR が依拠する配布構造の根拠は **ADR-0003 のみ**とし、public/private の framing は本 ADR の主張から外す。本 ADR の決定内容（plugin 数を 3 に増やす）は影響を受けない。
>
> **現在の [ADR-0008](0008-repository-visibility-public.md) は別物**（`repository-visibility-public`・2026-07-28 に新規作成）。削除で空いた番号を連番維持のために継いだもので、上記で削除されたものとは内容が異なる。

> ※ 注記 (2026-07-29)：本 ADR が記録した agent 名の重複禁止は、[ADR-0010](0010-external-plugin-agent-name-collision.md) で**外部 marketplace の plugin まで適用範囲を拡張**した。衝突は本リポジトリの collection 間で閉じない。同 ADR で `shared:code-reviewer` は `shared:implementation-reviewer` に改名されている。



## Context

ADR-0004 / ADR-0005 は、collection の自己完結を守るために `shared/agents/` と `shared/skills/` を**真実源**とし、`make sync` で各 collection に generated file として複製する vendoring 方式を採った。結果、13 の engineering 系 agent が indie-studio と enhance-superpowers の双方に同名で実体化していた。

**この構成は実際に壊れていた。** 両 plugin を install した状態で agent を dispatch しようとすると:

```text
Agent(subagent_type: "indie-studio:ux-researcher") → Agent type 'indie-studio:ux-researcher' not found
Agent(subagent_type: "ux-researcher")              → Agent type 'ux-researcher' not found
```

registry に載るのは `enhance-superpowers:*` の 13 体のみで、**indie-studio 側の 19 体は 1 体も解決できない**。判明した事実は 4 つ:

1. 同名 agent を持つ 2 plugin が共存すると、負けた側の agent セットが registry から落ちる。
2. 巻き添えで、衝突していない indie-studio 固有 6 体 (ux-researcher / product-manager / business-strategist / product-designer / visual-designer / ui-prototyper) まで消える。
3. その結果 **indie-studio の全 skill が職種エージェントを 1 体も起動できない**。共通ステージ形 (ディレクター + 職種 + 評価・**indie-studio** ADR-0013) が成立していなかった。
4. **skill は名前空間が正しく効く**（`indie-studio:finish-stage-pr` と `enhance-superpowers:finish-stage-pr` は共存できていた）。壊れるのは agent だけ、という非対称がある。

加えて root `AGENTS.md` の「エージェントは frontmatter の `name` で識別・起動される (`subagent_type` も `name` 参照・path 非依存)」という記述が実挙動と食い違っていた。実際には `plugin:agent` 修飾が必須である。

vendoring を維持したまま衝突を避ける案 (sync 時に `is-` / `es-` 等の prefix を付ける) も検討したが、registry に同一内容の agent が 26 体並ぶだけで、根本の重複は消えない。

## Decision

**`shared/` を marketplace の 3 つ目の plugin にし、agent と skill の vendoring を両方とも廃止する。**

- `shared/.claude-plugin/plugin.json` を新設し、`.claude-plugin/marketplace.json` に `shared` を列挙する。ADR-0004 が定めた「shared は配布対象外」を撤回する。
- `shared` plugin が engineering 系 13 agent と helper skill 2 本 (start-stage-branch / finish-stage-pr) を**単一の実体**として提供する。
- 各 collection の `dependencies.json` と generated file (agents 13 体 × 2、skills 3 本) を削除する。collection には**固有 agent のみ**が残る (indie-studio 6 体、enhance-superpowers 0 体)。
- **agent の dispatch は `plugin:agent` 形式の修飾名で行う** (`shared:software-architect` / `indie-studio:ux-researcher`)。bare name は解決されないため、全 SKILL.md の dispatch 名を修飾名に書き換える。
- vendoring 機構一式 (`scripts/sync-shared.sh`・Makefile の `sync` / `verify` / `status` target・`.github/workflows/verify-shared.yml`) を削除する。同期すべき複製が存在しない以上、drift 検知の対象がない。

skill も agent と同様に vendoring を廃止する。skill 自体は衝突していなかったが、`shared/` が plugin になると `shared/skills/` も自動ロードされるため、vendoring を残すと同一 skill が 3 コピー (shared / indie-studio / enhance-superpowers) になり現状より悪化する。ADR-0005 が想定した「collection 側で固有拡張を入れる余地」は、実際には一度も使われていない (3 コピーは `x-` frontmatter を除いて完全に同一で、`body-source-path` 拡張は shared 側へ取り込み済み) ため、失うものはない。

`shared/agents/` を collection 非依存の中立語彙で書く原則 (ADR-0004) は維持する。collection 固有の context (ステージ番号・参照 docs パス・進行 protocol) は、従来どおり呼び出し元 skill が invocation 時に prompt で渡す (indie-studio ADR-0031)。

## Consequences

- **indie-studio の agent dispatch が初めて実際に動くようになる。** 固有 6 体が registry に載り、shared 13 体は `shared:` 修飾で解決される。
- indie-studio と enhance-superpowers は `shared` plugin に**依存**する。両者を使う場合は `shared` の install が必須であり、README / marketplace description で明示する。
- registry に載る engineering 系 agent は 26 体 (13 × 2 の重複) から 13 体になる。
- `make sync` / `make verify` / `make status` は消滅する。shared/ を編集したら即座に全 consumer へ反映されるため、sync 忘れという失敗モード自体が無くなる。CI の `verify-shared` job も不要になる。
- `shared/` が `.claude-plugin/plugin.json` を持つため、release-drafter の auto-discovery (ADR-0006) が `shared` を collection として認識し、専用の draft と tag prefix (`shared/v0.0.x`) を持つようになる。`make regen-drafter-configs` で config を生成する。
- あわせて drafter の `include-paths` から `shared/skills/finish-stage-pr/` を除去し、各 collection の draft は `<collection>/` 配下のみを集約する。vendoring 時代は shared/ の変更が `make sync` で `<collection>/agents/` にも現れるため consumer の draft に載っていたが、`shared` が自前の draft を持つ以上、**shared/ の変更は shared の draft にのみ載せる**（consumer 側で二重計上しない）。ADR-0006 が記した include-paths の前提（「vendoring 元」「全コレクションが finish-stage-pr を vendoring している前提」）は本 ADR で失効する。
- root `AGENTS.md` の agent 起動に関する記述 (`name` 参照・path 非依存) を、`plugin:agent` 修飾必須に訂正する。
- 「各コレクションは自己完結する」という構成規約は、**ディレクトリ構造の規約**として読む。実行時に他 plugin の agent / skill を参照することは妨げない。

## Alternatives Considered

- **sync 時に collection prefix を付与 (`is-software-architect` / `es-software-architect`)**：vendoring 機構と自己完結を維持できるが、registry に同一内容の agent が 26 体並ぶ。重複という根本問題が残り、全 SKILL.md の書き換えコストは本案と変わらない。却下。
- **indie-studio 側の重複 13 体だけを削除し、`enhance-superpowers:*` を dispatch する**：変更は最小だが、indie-studio の S1 / S3 / S4 まで enhance-superpowers に依存することになり、両 collection の語彙分離 (enhance-superpowers `CONTEXT.md` の禁止語彙) と噛み合わない。却下。
- **`plugin:agent` 修飾の徹底のみ**：衝突で片方が registry から消えている以上、修飾しても呼べない (`indie-studio:ux-researcher` が not found である事実が反証)。単独では解決にならない。却下。

## 関連

- ADR-0003 (plugin-marketplace-distribution): 配布構造 (marketplace + per-collection plugin)。本 ADR は plugin 数のみ増やし、構造は継承する
- ADR-0004 (shared-agent-vendoring) / ADR-0005 (shared-skills-vendoring): 本 ADR が supersede する。中立語彙原則のみ継承
- ADR-0006 (release-drafter-auto-discovery): `shared` が collection として auto-discover される
- indie-studio ADR-0031 (skill-invocation-context-for-neutral-agents): 中立 agent への context 受け渡し規律。本 ADR 後も有効

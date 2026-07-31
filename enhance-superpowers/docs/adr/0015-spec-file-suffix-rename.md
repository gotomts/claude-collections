# 0015. 実装仕様の suffix を `design` → `spec` に改名する

5 成果物のうち実装の詳細仕様を指すファイル名 suffix を **`design` から `spec` に変える**。生成順・Phase 構成・承認単位は変えない。

## Status

Accepted (2026-07-31)。

ADR-0011 の**成果物名のみを改定する** (extends)。plan-last 順序 / Phase 対応 / 3 file 一括承認は**すべて有効なまま**。

**読み替え規約**: ADR-0002 / 0006 / 0007 / 0008 / 0011 / 0012 の本文にある `design.md` は、本 ADR 以降 `spec.md` を指す。ADR は immutable のため本文は書き換えない (root `AGENTS.md` の ADR 規律)。

## Context

`design` を使い続ける実害が indie-studio 側で確認された。

- **生成先での名前衝突**。成果物が生成されるのは**サービス repo 側**であり、そこには repo-root の `DESIGN.md` (デザイン憲法) が存在する運用がある (indie-studio ADR-0020 / 0023 / 0029)。同じ repo の実装フェーズに `design.md` があると読み違えを招く。
- **同じ役割のファイルが 2 つの名前を持っていた**。indie-studio は ADR-0034 で自コレクションの実装仕様 suffix を `spec` に改名したが、「enhance-superpowers は変更しない」前提 (indie-studio ADR-0032 D5) だったため、**enhance-superpowers を単体で使うと `design.md`、`implementation-spec` 経由だと `spec.md`** が出る不一致が残った。indie-studio ADR-0034 は Consequences でこの不一致を「受け入れる」と明記していた。

indie-studio ADR-0034 が統一を却下した根拠は 2 つあり、いずれも本 ADR の時点では解ける:

| 却下根拠 | 現在の評価 |
|---|---|
| 業務稼働中のコレクションの成果物名を変えられない | 改名するかどうかは enhance-superpowers 側の判断。本 ADR で改名を選ぶ |
| 作業中 branch の `*-design.md` が Step 0 で検出されなくなる | Step 0 に legacy 検出を入れれば救済できる (下記 D3)。**改名の唯一の実害はこれで消える** |

## Decision

### D1. suffix を `spec` にする

5 成果物の suffix は `summary` / **`spec`** / `gwt` / `pr-description` / `plan`。ファイル名は `{YYYY-MM-DD}-{slug}-spec.md`。

`design` の語は **UI デザイン側に明け渡す**。実装フェーズでは使わない。

ADR-0011 が定めた生成順 (`summary → spec → gwt → pr-description → plan`)・Phase 対応・Phase 3 の 3 file 一括承認は**変更しない**。変わるのは名前だけ。

### D2. frontmatter の key も `spec` にする

`templates/summary.md` と `templates/gwt.md` の frontmatter key `design:` を `spec:` に変え、値を `./{YYYY-MM-DD}-{slug}-spec.md` にする。`templates/review-response.md` は key が既に `spec:` なので値のみ変える。

### D3. Step 0 は legacy `*-design.md` を救済する

`enhance-brainstorming` / `enhance-executing-plans` の Step 0 は、`*-design.md` を見つけたら**改名前の実装仕様として `*-spec.md` と同じ成果物に扱う**。

`enhance-brainstorming` では user に「`*-spec.md` に rename して続けるか / そのまま続けるか」を 1 問確認し、**回答で実装仕様の実体 path (`{実装仕様}`) を確定する**。

- **rename する** → `git mv` した上で、**既存 `summary.md` / `gwt.md` の frontmatter にある実装仕様への参照も新 path に更新する** (更新しないと参照が dangling する)
- **そのまま続ける** → `{実装仕様}` は `*-design.md` のまま。**後続 Step (gwt 生成の Read / pr-description のスコープ参照 / 一括提示 / 5 成果物の存在確認) はすべてこの path を使う**

「そのまま続ける」を選べるようにする以上、**後続 Step が `spec.md` を literal に参照してはならない**。参照は `{実装仕様}` の placeholder に寄せ、Step 0 の回答で解決する (SKILL.md 冒頭で `{出力先}` と同じ形の規約として定義する)。ここを揃えないと「Step 0 は実装仕様ありと判定するが後続 Step が読めない」状態になり、legacy branch の再開が停止する。

両方存在する場合は `*-spec.md` を正とし、どちらを使うか 1 問確認する。

これにより**本 ADR より前に着手した branch は改名なしで再開できる**。

### D4. 委譲先にファイル名を明示する

Phase 3 で `superpowers:brainstorming` に委譲するとき (Y 方式 / ADR-0006)、**生成ファイル名 `{date}-{slug}-spec.md` を prompt で明示する**。委譲先は自身の規約で `design.md` の名前で書こうとするため、渡さないと改名前の名前で出力される。

Y 方式そのもの (合意済み summary を context として渡す) は継続。

## Consequences

- **名前の不一致が解消する。** enhance-superpowers 単体でも `implementation-spec` 経由でも `*-spec.md` が出る。indie-studio ADR-0034 Consequences の「同じ役割のファイルが 2 つの名前を持つ」は本 ADR で解消した。
- **indie-studio ADR-0034 D2 (invocation 時に `*-spec.md` を明示する) は冗長になる**が、有害ではないので indie-studio 側の決定としてそのまま残す。ただし同 D2 の根拠として `implementation-spec/SKILL.md` に書かれていた「`enhance-executing-plans` は `design.md` と名指ししている」という記述は事実でなくなるため、実態に合わせて訂正する。
- **過去に生成済みの成果物は改名しない。** `docs/superpowers/` 配下に既にある `*-design.md` は当時の記録としてそのまま残す。in-flight の branch は D3 で救済する。
- **ADR 本文は書き換えない。** 読み替え規約を Status に置き、ADR-0011 / 0012 には本 ADR を指すナビゲーション注記のみ足す (注記の追加は immutable の例外・root `AGENTS.md`)。

## Alternatives Considered

- **`design` のまま維持する** (indie-studio ADR-0034 が受け入れた状態) — 改名コストはゼロだが、2 つの名前の併存が恒久化し、生成先 repo の `DESIGN.md` と紛らわしい状態も残る。却下。
- **indie-studio 側を `design` に戻して統一する** — UI デザインとの語彙衝突という根本問題が戻る (indie-studio ADR-0034 が実害を確認済み)。却下。
- **`impl-spec` / `detail-design` 等の第三の名前にする** — `spec` は indie-studio が既に採用しており、そちらに揃えるのが最小コスト。新しい名前を作る理由がない。却下。
- **legacy 検出を入れずに一括改名する** — 実装は最小だが、in-flight の branch が Step 0 で「未着手」と誤判定される。indie-studio ADR-0034 が改名を却下した唯一の実質的な根拠がこれなので、潰さずに改名するのは筋が悪い。却下。

## 関連

- ADR-0011 (plan-last-order-and-design-gwt-prd-merged): 名前の出所。本 ADR が suffix のみ改定する親
- ADR-0012 (implementation-phase-skill-and-state-detection): Step 0 状態判定。D3 の legacy 検出を追加する先
- ADR-0006 (superpowers-brainstorming-context-delegation): Y 方式。D4 でファイル名明示を追加
- ADR-0007 / ADR-0008: dispatch log の追記先 / 機微情報チェックの対象 file。名前のみ読み替え、決定は不変
- indie-studio ADR-0034 (implementation-spec-file-suffix): 対向の決定。本 ADR で名前不一致が解消する
- indie-studio ADR-0032 D5: 「enhance-superpowers を一切変更しない」は indie-studio 側の前提。本 ADR は enhance-superpowers 側の決定として改名する。方向は ADR-0034 D1 と一致するため委譲契約は壊れない
- root `AGENTS.md`: ADR 規律 (決定の書き換えは新 ADR で行う / ナビゲーション注記は例外)

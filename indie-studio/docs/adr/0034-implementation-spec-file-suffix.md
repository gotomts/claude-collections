# 実装仕様のファイル名 suffix を `spec` にする（ADR-0032 D2 の改定）

`implementation-spec` が生成する実装詳細仕様のファイル名 suffix を **`design` から `spec` に変える**。ADR-0032 D2 が `design` を採った根拠は事実誤認だったため、あわせて訂正する。

## Status

accepted（2026-07-29）。[ADR-0032](0032-s5-spec-in-harness-implementation-delegated.md) の **D2 を改定**する（extends）。D1 / D3 / D3-a / D4 / D5 と、D2 のうち suffix 以外の契約項目は**すべて有効なまま**。

## Context

ADR-0032 D2 は suffix に `design` を採用し、その根拠をこう書いた：

> **suffix は `design` を使う**（`spec` にはしない）。`enhance-executing-plans` と `gwt-test` が `design` で glob するため、改名すると発見できない。

**この根拠は事実誤認だった。** 委譲先の 4 skill を実際に検査した結果：

| skill | `design` への言及 |
|---|---|
| `gwt-test` | **ゼロ**（「`gwt-test` が `design` で glob する」は完全な誤り） |
| `write-review-response` | ゼロ |
| `finish-spec-pr` | ゼロ |
| `enhance-executing-plans` | 4 箇所あるが**いずれも必須ではない** |

`enhance-executing-plans` の 4 箇所の内訳は、(a) Step 0 の glob 列挙、(b) executor へ渡す「参照 docs」のパス、(c) 失敗時メッセージ。**ハード要件は `*-plan.md` の存在のみ**で、Step 0 の判定は `plan.md` のレビュー履歴だけで行われ `design` の有無で分岐しない。

つまり **`enhance-superpowers` を変更せずに改名できる**。ADR-0032 D5（enhance-superpowers 不変）と両立する。

一方、`design` を使い続ける実害が確認された。成果物が生成されるのは**サービス repo 側**であり、そこには S1b `design-direction` が作る repo-root の **`DESIGN.md`（デザイン憲法）が常に存在する**（複数 repo で共通の運用）。同じ repo の実装フェーズに `design.md` があると読み違えを招く。

## Decision

### D1. suffix を `spec` にする

5 成果物の suffix は `summary` / **`spec`** / `gwt` / `pr-description` / `plan`。ファイル名は `{YYYY-MM-DD}-{slug}-spec.md`。

`design` の語は **UI デザイン側に明け渡す**（`DESIGN.md` / `design-direction` / `product-designer` / `visual-designer`）。実装フェーズでは使わない。

### D2. 委譲時に参照先を prompt で伝える

`enhance-executing-plans` は executor へ渡す「参照 docs」を `design.md` と名指ししている（同 skill Step 3）。そのため `implementation-spec` は **invocation 時に「実装の詳細仕様は `*-spec.md`」と prompt で明示**する。

これは **context 提供であって引数でも改修でもない**ため、ADR-0032 D5（enhance-superpowers 不変）に反しない。

### D3. 入力契約の必須度を正確に記す

ADR-0032 D2 は「委譲先が Step 0 で glob するため崩すと連鎖が壊れる」と 5 成果物を一律に扱っていたが、**必須度は一様でない**。実際に崩すと壊れるのは 2 つだけ：

- **`*-plan.md` の存在** — `enhance-executing-plans` Step 0 が前提として要求。無ければ error 中断
- **`*-gwt.md` の checklist（`- [ ] AC-N:`）と `## 変更履歴` / `## レビュー履歴`** — `gwt-test` が判定に使う

`summary` / `spec` / `pr-description` は Step 0 の glob 列挙に現れるだけで、判定に使われない。

**過度に強い制約として書いたことが、本 ADR で訂正した誤った結論を招いた。** 契約は「守るべき理由」とセットで、実際の必須度に忠実に書く。

## Consequences

- **同じ役割のファイルが 2 つの名前を持つ。** `enhance-superpowers` を単体で使うと `design.md`、`implementation-spec` 経由だと `spec.md` が出る。`enhance-superpowers` は業務稼働中で成果物名を変えられないため（ADR-0032 D5）、この不一致は受け入れる。読み手が迷わないよう `implementation-spec/SKILL.md` に対応を注記する。
- `implementation-spec` は本 ADR 時点で**一度も実行されていない**ため、既存成果物の移行は不要。
- ADR-0032 の D2 は suffix に関してのみ本 ADR で置き換わる。他の契約項目（ファイル名フォーマット、配置、`plan.md` / `gwt.md` の必須セクション）は有効。

## Alternatives Considered

- **`enhance-superpowers` 側も `spec.md` に改名して統一する**：名前の不一致は消えるが、**業務稼働中のコレクションの成果物名を変える**ことになり、既存の作業中 branch にある `*-design.md` が Step 0 で検出されなくなる。ADR-0032 D5 に反する。却下。
- **`design` のまま維持する**：改名コストはゼロだが、生成先 repo の `DESIGN.md` と紛らわしい状態が恒久的に残る。実際に読み違えが発生した。却下。
- **ADR-0032 を直接書き換えて訂正する**：手数は最小だが、`## Decision` 内の決定の書き換えにあたり `AGENTS.md` の ADR 規律に反する（同規律は本セッションの root PR #37 で明文化したばかり）。却下し、本 ADR で extends する形を採った。

## 関連

- [ADR-0032](0032-s5-spec-in-harness-implementation-delegated.md)：本 ADR が D2 を改定する親。D1 / D3 / D3-a / D4 / D5 は有効
- ADR-0020（DESIGN.md）／ADR-0023（design-direction）：`design` の語を明け渡す先
- enhance-superpowers ADR-0011（5 成果物と生成順）：`design.md` という名前の出所。**本 ADR は enhance-superpowers を変更しない**
- root ADR：`AGENTS.md` の ADR 規律（決定の書き換えは新 ADR で行う）

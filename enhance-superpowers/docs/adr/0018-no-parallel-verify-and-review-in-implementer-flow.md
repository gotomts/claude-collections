# 0018. implementer 側では AC 検証とコードレビューを並走させない

## Status

Accepted (2026-08-06)。[ADR-0017](0017-reviewer-side-skill-and-parallel-sessions.md) を **extends** する。

ADR-0017 の Decision（特に D3 = レビュワー側 `pr-review` で子セッション 2 本を同一 worktree・タブ 2 枚で並走させる）は**そのまま有効**。本 ADR は D3 を implementer 側（`gwt-test` / `enhance-executing-plans`）へ拡張するかを検討し、**拡張しない**と決める。

## Context

### 検討の起点と、その前提の誤り

起点は issue #51 で、前提はこうだった：

> Step 3 のブラウザ操作と Step 8 のコードレビューは**互いの結果に依存しない**。それでも逐次なので、所要時間は単純な和になる。

**この読みは誤りである。** `gwt-test` SKILL.md の実物を読むと、依存は**片方向に存在する** — Step 8 が Step 3〜6 の結果に依存する。

| 引用元 | 記述 | 意味 |
|---|---|---|
| `gwt-test/SKILL.md:92-93` | 「全 AC 達成 → Step 6 へ / AC 未達あり → Step 5 へ」 | Step 4 の判定が経路を分岐させる |
| 同 `:100` | 「user に『AC 未達につき実装に差し戻します』と提示 → user 1 問確認 → 実装フェーズに戻る（`enhance-executing-plans` skill に chain）」 | AC 未達なら**コードが書き換わる** |
| 同 `:108` | 「qa-engineer が『抜けたシナリオあり』と判定した場合、user に 1 問確認 → gwt.md の AC 追加 → Step 3（再検証）へ戻る」 | 網羅性 NG なら検証自体をやり直す |

つまり **Step 8 に到達するのは「全 AC 達成」かつ「qa-engineer の網羅性 OK」のときだけ**であり、Step 3〜6 は Step 8 の前提条件になっている。逆向き（Step 3 が Step 8 に依存する）が無いのは正しいが、それは「互いに依存しない」ことを意味しない。

現行の逐次順序は偶然ではなく、**この依存の表現**である。

### implementer 側と レビュワー側 の構造差

ADR-0017 D3 が成立したのはレビュワー側の事情による。同じ構図が implementer 側には無い。

| 論点 | レビュワー側（`pr-review`） | implementer 側（`gwt-test`） |
|---|---|---|
| 動作確認が未達だったとき | `pr-review/SKILL.md:294`「**実装への差し戻しは行わない**（レビュワー側 skill なので修正は PR 作者の責務）」 | `gwt-test/SKILL.md:100` 実装フェーズへ chain して**修正させる** |
| worktree に居る主体 | 子 2 本のみ（親は発動元リポジトリに居る） | 親（実装をやってきた本人）+ 子 |
| commit する主体 | **ゼロ**。ADR-0017 D4 が成果物を発動元リポジトリに置き「commit しない」と定める | 親。`CONTEXT.md`「コミット前提: 設計ドキュメントは worktree 同居・main 退避なし。**ただし implementer 側の成果物に限る**」 |
| 親の役回り | 巡回と join に専念できる | 巡回に加えて chain 下流（`write-review-response` → `finish-spec-pr`）を持つ |

### issue #51 の D1〜D4 との対応

| issue | 本 ADR |
|---|---|
| D1（並走させるか） | **D1 で却下** |
| D2（却下する場合、理由を記録するか） | **本 ADR 自体が記録**。特に「ADR-0017 D3 が implementer 側に適用されない理由」を D1 に明示した |
| D3（`enhance-executing-plans` Step 4 の扱い） | **D2 で対象外**と決定 |
| D4（draft PR に `/review` を回す案） | **D3 で却下** |

## Decision

### D1: `gwt-test` の AC 検証（Step 3〜7）とコードレビュー（Step 8）を並走させない

現行の逐次構造を維持する。理由は 4 つあり、1 が単独で採用を否定する。

**1. Step 8 は Step 3〜6 の結果に依存する（Context のとおり）。**

並走させると 2 つの損失が同時に起きる：

- **AC 未達時にレビュー結果を捨てる。** Step 4 で未達が出れば `:100` の経路で実装フェーズへ戻る。並走で先に走らせたレビューは、差し戻し後のコードには当たらない
- **これから変わるコードをレビューした結果になる。** 捨てそこねればさらに悪く、修正前のコードに対する findings が `write-review-response` へ渡り、既に直った箇所を採用/Skip 判定することになる

AC 未達は例外事象ではない。それを検出するために `gwt-test` が存在し、SKILL.md が差し戻し経路（Step 5）と再検証経路（Step 6-3）を両方持っている。逐次であればこの損失はゼロになる — レビューは「AC を満たしたコード」に対してだけ走る。

**2. ADR-0017 D3 の成立条件が implementer 側では崩れる。**

D3 が同一 worktree 共有の条件としたのは「**両者ともコードを書かない**」ことである。`gwt-test` の Step 8 側はこれを満たす（`SKILL.md:157`「本 skill 内では修正しない。findings を review-source として Step 8-6 の `write-review-response` chain に渡す」）。**満たさないのは検証側**である — `:100` が実装フェーズへの chain を持つ以上、検証セッションはコードを書き換える経路を持つ。レビュワー側は `pr-review/SKILL.md:294` で構造的にこの経路を封じているが、implementer 側で同じ禁止を置くと `gwt-test` の中核機能（未達を実装に差し戻す）が消える。

**3. 親が同じ worktree に居て、commit 主体である。**

ADR-0017 D3 は「子 2 本が同一 worktree を共有する」形であり、commit する主体が 1 つも居ない（D4 が成果物を発動元リポジトリに置いて commit しないと定めたため）。implementer 側は 3 者が同じ worktree を共有し、うち親が commit 主体になる（`CONTEXT.md` の「コミット前提」）。D3 が index.lock 競合の条件として挙げた「書き込み先の分離」は、commit 主体が居る前提では検証されていない。

加えて **dev server とテスト再実行が同一 worktree で同時に走る**。`gwt-test` Step 2 が dev server / docker を起動し、Step 8 の `shared:implementation-reviewer` は `Bash` を持ってテスト / 型 / lint を再実行する（ADR-0016 D1）。ビルドキャッシュとロックファイルの奪い合いは言語・フレームワークごとに現れ方が違い、skill が一般に保証できない。

**4. 得られる時間短縮が、運用コストで相殺されやすい。**

chain 下流（`write-review-response` → `finish-spec-pr`）は AC 検証結果とレビュー findings の両方を必要とするため、親は join を待つ。短縮幅は `t_verify + t_review` から `max(t_verify, t_review)` への差分だけで、そこにタブ 2 枚の作成・rename・初回プロンプト投入・巡回ポーリング・join 統合が乗る。レビュワー側で D3 が成立したのは「親が subagent を抱えると巡回して blocked に回答する役が居なくなる」（ADR-0017 D3）ためだが、implementer 側の親は検証実務そのものを持つので、この利得構造が再現しない。

**まとめ：ADR-0017 D3 が implementer 側に適用されない理由。** D3 は「動作確認とコードレビューが**独立に完結する**」ことを暗黙の前提に置いていた。レビュワー側ではこの前提が構造的に保証される（修正は PR 作者の責務なので、レビュワーの観測結果が対象コードを変えない）。implementer 側では保証されない — 検証結果が実装を書き換える経路が設計の中核にある。**同じ 2 つの作業を並べているように見えても、依存グラフが違う。**

### D2: `enhance-executing-plans` Step 4 は対象外とする

同 SKILL.md `:115` が「review 指摘がある場合、user に 1 問確認 → 該当 executor に修正 dispatch（再実装）→ 同一 implementation-reviewer インスタンスへ continuation で再 review → 収束」を回しており、**この窓の中でコードが書き換わる**。D1 の理由 2 がそのまま、かつより強く当てはまる（`gwt-test` は差し戻しが chain 先で起きるが、Step 4 は同一 skill の同一ループ内で起きる）。

加えて Step 4 は slice ごとに走るループの内側にあり、並走の単位が「slice の実装 → その slice のレビュー」という**直列依存そのもの**である。並走させる相手が存在しない。

### D3: draft PR を作って `/review` を回してから ready にする案は採らない

理由は 3 つ。

**1. 待ち時間の置き場が無い。** この案の動機は「CodeRabbit が PR 作成直後には到着しない」（ADR-0016 D2）を draft 期間で吸収することだが、CodeRabbit のレビューは数分〜十数分かかる。skill が待てば chain 終端に待ちが入り、待たなければ現行の「時間が経ってから `write-review-response` を直接 invoke する」（同 D2）と挙動が同じになり、draft にした意味が無い。

**2. draft PR 本来の利点が、本リポジトリの前提では効かない。** draft の主な効用は「レビュー中に他人が誤って merge するのを防ぐ」ことだが、root [ADR-0012](../../../docs/adr/0012-author-only-distribution-premise.md) が定めるとおり**利用者は作者のみ**であり、誤って merge する相手が存在しない。

   ※ root ADR-0012 は「consumer 環境に依存するから」を却下理由に使うことを禁じているが、ここで使っているのは逆向きの推論である — consumer が存在しないという前提から、consumer 保護を目的とする機構の**利得が無い**と結論している。ADR-0012 が無効化するのは「consumer 環境に依存するから駄目」という却下理由であって、「consumer が居ないから利得が無い」という評価ではない。

**3. 覆すべき新事実が無い。** CodeRabbit ラウンドの扱いは ADR-0016 D2 が既に決めている（`write-review-response` が 3 ラウンド構成を持ち、CodeRabbit ラウンドは時間を置いて直接 invoke する）。本 issue の検討で、その決定の前提を崩す事実は 1 つも出ていない。D1 を却下したため「レビュー時間を隠蔽する」という動機も残らない。

### D4: SKILL.md への反映は `gwt-test` の規律 1 行に留める

D1 は現行挙動の追認なので、Step 定義・Phase 定義・失敗時テーブルはいずれも変更しない。触るのは 3 箇所に留める：

- `gwt-test` SKILL.md の**規律明示に 1 行**（「Step 3〜7 と Step 8 を並走させない。Step 8 は AC 達成と網羅性 OK を前提とする」）+ 関連に本 ADR の 1 行
- `CONTEXT.md` のレビュワー側の節に 1 段落（並走はレビュワー側だけであること）

規律明示に書く理由は、Step 定義を読んだだけでは依存が見えないため。実際 issue #51 は Step の並びだけを見て「互いに依存しない」と読んだ。規律明示セクションは「Step を読んでも分からない前提」を置く場所であり、この 1 行はそこに属する。`CONTEXT.md` は同 skill 一覧が `pr-review` の並走を明記している一方で implementer 側との違いに触れておらず、コレクション横断の読者が同じ誤読に到達しうるため 1 段落を足す。

`enhance-executing-plans` SKILL.md には**書かない**。D2 のとおり Step 4 には並走させる相手が存在せず、提起されていない案を否定する文を skill に置くと、読み手に「検討された案がある」と誤読させる。D2 の記録は本 ADR に閉じる。

## 判断が変わる条件

- **`gwt-test` から実装差し戻し経路（Step 5-4 の `enhance-executing-plans` chain）が無くなったとき。** D1 の理由 1 と 2 が同時に消える。ただしその変更自体が `gwt-test` の中核機能を削るので、先に別 ADR での検討が要る
- **chain 下流が AC 検証結果とレビュー findings を独立に消費するようになったとき。** 現在は `write-review-response` が両方を待つため join が必須だが、片方だけで進める設計になれば D1 の理由 4 が変わる
- **AC 未達の発生率が実測でほぼゼロになったとき。** 理由 1 の損失期待値が下がる。ただし「未達がほぼ出ない」なら `gwt-test` の存在意義そのものを問い直す方が先になる

D3 の判断が変わる条件は ADR-0016 D2 と同じ — CodeRabbit の到着が PR 作成直後に間に合うようになれば、draft 期間で吸収するという発想自体が不要になる。

## Consequences

- **implementer 側 5 skill の実行形態は変わらない。** 変更は本 ADR と D4 の 3 箇所（`gwt-test` SKILL.md の規律 1 行 + 関連 1 行、`CONTEXT.md` の 1 段落）に閉じる。`shared/` は無変更、indie-studio への影響も無い
- **コレクション内に「並走する skill」と「しない skill」が併存する。** `pr-review` だけが herdr の子セッションを使い、implementer 側 5 skill は使わない。ADR-0017 Consequences が既に「herdr 依存の skill と非依存の skill が混在する」と記録した状態が、本 ADR で確定する
- **時間短縮は得られない。** `gwt-test` の所要時間は AC 検証とセルフレビューの和のままである。これは受け入れたコストであり、依存関係を保つ対価として支払う
- **issue #51 の前提の誤りが記録に残る。** 「Step 3 と Step 8 は独立している」という読みは Step の並びだけを見れば自然に出るため、記録が無ければ同じ誤読から再検討が始まる

## Alternatives Considered

- **子セッション 2 本を同一 worktree で並走させる（ADR-0017 D3 の直輸入）** — D1 の 4 理由で却下
- **worktree を 2 つに分けて並走させる** — D1 の理由 3（親の commit / dev server 競合）は解消するが、理由 1（依存）と理由 4（join 待ち）が残る。加えて ADR-0017 D3 が却下したコスト（同一ブランチの 2 重 checkout 不可、依存インストール 2 回分、dev server の port 競合）をそのまま負う。却下
- **AC 検証が全て通ってからレビューを並走で開始する** — 依存は守られるが、Step 8 の開始時点で Step 3〜7 は終わっているので並走する相手が居ない。案として成立しない
- **`pr-review` を自分の PR に向ける** — issue #51 が起票時点で潰している。ADR-0017 D7 が `pr-review` を「他人の PR を受け取る側」と定義し、かつ D5 の crit ゲートで**自分の理解メモを自分でレビューする**ことになる。indie-studio [ADR-0008](../../../indie-studio/docs/adr/0008-adaptive-pr-review-gate.md) が却下した利益相反と同型で、[ADR-0016](0016-local-review-to-implementation-reviewer-and-builtin-review-after-pr.md) D4 が同じ線引きを既にしている。却下
- **Step 8 の 3 dispatch（`shared:implementation-reviewer` / `shared:security-engineer` / `/security-review`）を相互に並列化する** — 本 ADR の射程外。問うているのは Step 3 と Step 8 の並走であり、Step 8 内部の実行形態には触れない。現行 SKILL.md も 3 つの順序を規定しているだけで並列を禁じていない。必要になれば別 ADR で扱う

## 関連

- [ADR-0017](0017-reviewer-side-skill-and-parallel-sessions.md) (reviewer-side-skill-and-parallel-sessions) — 本 ADR が extends する。D3 はレビュワー側で有効なまま、implementer 側へは拡張しない
- [ADR-0016](0016-local-review-to-implementation-reviewer-and-builtin-review-after-pr.md) (local-review-to-implementation-reviewer-and-builtin-review-after-pr) — D1 = ローカルのコードレビュー宛先（本 ADR は宛先を変えない）、D2 = CodeRabbit ラウンドの扱い（D3 の却下根拠）、D4 = 人間レビューの代替にしない線引き
- [ADR-0013](0013-gwt-test-qa-engineer-always-dispatch-and-code-review-auto-invoke.md) (gwt-test-qa-engineer-always-dispatch-and-code-review-auto-invoke) — `gwt-test` の Step 6 / Step 8 を規定。本 ADR は実行順序を追認するだけで、dispatch 対象と強制性には触れない
- [ADR-0012](0012-implementation-phase-skill-and-state-detection.md) (implementation-phase-skill-and-state-detection) — skill chain と Step 0 状態判定。並走を導入しないため Phase 定義 table は不変
- root [ADR-0012](../../../docs/adr/0012-author-only-distribution-premise.md) (author-only-distribution-premise) — D3 理由 2 の前提（利用者は作者のみ）
- indie-studio [ADR-0008](../../../indie-studio/docs/adr/0008-adaptive-pr-review-gate.md) — 自己レビューの利益相反。`pr-review` を自分の PR に向ける案の却下根拠

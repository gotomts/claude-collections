# 視覚確認ゲートの「戻る」後に spec compliance 再チェックを挟む

S1b `design-direction` の視覚確認ゲート（ADR-0030）で人間が「戻る」を選び DESIGN.md を修正した後、mock 再生成の前に `shared:reviewer` を **continuation・scope 凍結**で再起動し、変更セクションの spec compliance のみを再検証する。合格後にのみ mock を再生成する。

## Status

accepted（2026-07-28）。[ADR-0030](0030-s1b-html-mock-step-and-ui-prototyper.md)（S1b HTML mock step と ui-prototyper）を **extends** する。ロスター・ゲート構造・2 ループ制限は変えない。

## Context

`design-direction` の進行は次の順序になっている（ADR-0029 / 0030）。

1. `indie-studio:product-designer` が DESIGN.md を **spec pin フォーマット**で compose（フラット map / unit suffix / hyphen variant / 英語単独セクション名）
2. `shared:reviewer` が fresh 起動で評価（**評価観点に spec compliance を含む**）。最大 3R で合格させる
3. `indie-studio:ui-prototyper` が **reviewer 合格版**の DESIGN.md から HTML mock を生成
4. 視覚確認ゲート（人間・最大 2 ループ）。「戻る」なら product-designer を continuation 再起動して token を修正し、**そのまま** ui-prototyper で mock を再生成

**ステップ 4 の「戻る」ループが、ステップ 2 の spec compliance 検証を迂回している。** reviewer が合格させた DESIGN.md を人間フィードバック起点で書き換えるのに、書き換え後の形式適合を誰も確認しないまま確定する。ADR-0029 が spec pin フォーマットを定めた目的（下流の Claude Design / Claude Code が機械的に読めること）が、最後の human-in-the-loop で崩れうる。

既存の緩和策は `ui-prototyper` の「collateral damage 防止」self-grill だが、これは**意味的な矛盾**（1 ループ目の修正が他セクションと食い違わないか）の検出であって、**形式的な spec 適合**の検証ではない。役割が違うため代替にならない。

外部レビュー（CodeRabbit・PR #31）で同じ穴が指摘されたことが本 ADR の直接の契機。

## Decision

**「戻る」ループの token 修正後・mock 再生成前に、`shared:reviewer` の再チェックを挟む。**

- **起動形は continuation**（fresh ではない）。ステップ 2 で合格済みの文脈を保持したまま差分だけを見る。
- **scope は凍結**：**変更されたセクション / token の spec compliance のみ**。未変更セクションと、ステップ 2 で決着済みの内容は再評価しない。
- **形式違反があれば** `indie-studio:product-designer` を continuation 再起動して修正 → 再チェック。このループは**視覚ゲートの 2 ループ制限とは別枠**とする（形式適合には妥協点がないため、人間の往復とは別に収束させる）。ただし同一 finding が 3 回連続で解消しなければ **⚠️未達**として決着させ、ディレクターが終端レポートに載せる（黙って通さない）。
- **合格後にのみ** `indie-studio:ui-prototyper` を起動して mock を再生成する。

`ui-prototyper` の collateral damage self-grill は**そのまま残す**。意味的矛盾（別軸）を見る役割であり、本 ADR の形式チェックとは互いを代替しない。

## Consequences

- reviewer 合格後に DESIGN.md を書き換えても、spec pin フォーマットの適合が保たれる。下流（Claude Design / S3 tech-design / S5 実装）が DESIGN.md を機械的に読める前提が崩れなくなる。
- 「戻る」1 回あたり reviewer の continuation 起動が 1 回増える。fresh + 3R の完全サイクルではないため、人間ゲートの往復回数（最大 2 ループ）は変わらない。
- 形式違反の修正ループが視覚ゲートの 2 ループ制限と独立に回るため、理論上は「戻る」1 回で reviewer ↔ product-designer が最大 3 往復しうる。infinite-tweak 防止のため 3 回で ⚠️未達に落とす。
- ADR-0030 のステップ列に 1 ステップ挿入されるが、ロスター（product-designer / visual-designer / ui-prototyper / reviewer）とゲート構造（3 問 direction-pick + 視覚確認ゲート）は不変。

## Alternatives Considered

- **「戻る」のたびに `shared:reviewer` を fresh で完全サイクル（最大 3R）回す**：検証は最も厚くなるが、最大 2 ループの視覚ゲートに対して重すぎる。ステップ 2 で合格済みの内容まで毎回洗い直すのは無駄で、人間を待たせる時間も増える。却下。
- **`ui-prototyper` の self-grill に spec compliance を足して兼務させる**：起動数は増えないが、**生成者に自分の入力の検証を兼ねさせる**ことになり独立性が失われる。ADR-0018 が評価を独立 context の役者に担わせている原則にも反する。却下。
- **何もしない（現状維持）**：人間が視覚ゲートで直接見ているのだから形式崩れも気づく、という論も立つが、人間が見ているのは **mock の見た目**であって DESIGN.md の**記述形式**ではない。検出者が存在しない。却下。

## 関連

- ADR-0029（design-md-format-google-labs-spec-pin）：本 ADR が守ろうとしている spec pin フォーマットの定義元
- ADR-0030（s1b-html-mock-step-and-ui-prototyper）：本 ADR が extends する。視覚確認ゲートと ui-prototyper の役割
- ADR-0018（評価ループ・差し戻し protocol）：continuation 再起動と scope 凍結の作法
- ADR-0019（決定記録 inline・⚠️繰り越しマーカー）：⚠️未達の決着方法

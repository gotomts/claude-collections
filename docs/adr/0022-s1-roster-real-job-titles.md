# S1 roster を実在職種で再構成——design-system-engineer 廃止・評価役＝レビュアー

ADR-0014 の原則「**現実の職種で設計（成果物名・概念で割らない）**」に照らすと、ADR-0011 の S1 roster には非職種（プロダクトクリティーク＝「批評」は活動）と混成（リスク・法務・品質＝3関心のごちゃ混ぜ）が混じっていた。ADR-0020 の DESIGN.md 再定義（デザイン憲法はデザイナーの成果物・生成機構は未定）も踏まえ、S1 roster を**実在職種**で再構成する。ファイル名＝実在職種で 1:1。

## Status

accepted（ADR-0011 / ADR-0014 の S1 roster〔8体〕を supersede。S3/S4/S5 は対象外）

## 最終 S1 roster（ディレクター＝スキル本体を除き spawn 対象5体）

| エージェント（ファイル） | 担当成果物 |
|---|---|
| UX リサーチャー（`ux-researcher`） | persona / usage-scenes |
| プロダクトマネージャー（`product-manager`） | feature-scope / roadmap / specific-topics / risks-assumptions / nfr-targets |
| ビジネスストラテジスト（`business-strategist`） | competition / pitch / monetization / marketing / kpi / legal |
| プロダクトデザイナー（`product-designer`） | screens.md / screen-specs/&lt;area&gt;/（DESIGN.md は機構確定後にデザイナーが作る） |
| レビュアー（`reviewer`） | 全成果物を anchors・真実源・カバレッジ逆引きで評価・差し戻し（ADR-0018 protocol） |
| ディレクター | スキル本体（spawn しない・統括/依存順起動/評価ルーティング/完全性ガード/ブリーフ組み上げ） |

## 変更点と理由

- **プロダクトクリティーク → レビュアー**。「批評」は活動であって職種でない。評価役は実在職種「レビュアー」にする（S5 の「コードレビュアー」と平仄）。
- **リスク・法務・品質（混成）を解体**：risks-assumptions / nfr-targets → **プロダクトマネージャー**（プロダクトの viability・品質目標は PM の領域）／legal → **ビジネスストラテジスト**（事業・法務・市場の外部環境をまとめて見る）。
- **事業・マーケストラテジスト → ビジネスストラテジスト**（実在職種名に統一）。
- **デザインシステムエンジニア廃止**：DESIGN.md は ADR-0020 でデザイナーの成果物となり、かつ生成機構が未定。design-system / design-tokens を別職種に割る必要は消え、**プロダクトデザイナーに統合**。

## Considered Options

- **却下：ADR-0011 の8体（プロダクトクリティーク・リスク法務品質・デザインシステムエンジニアを含む）を維持**。非職種・混成・冗長で ADR-0014 の「実在職種」原則に反する。
- **却下：legal を独立した「リーガルカウンセル」職種にする**。solo-dev 企画段の薄い「気づき」ページに専任職種は過剰。ビジネスストラテジストに吸収。
- **却下：評価役を「プリンシパルプロダクトマネージャー」にする**。corporate-ladder 的で不自然。シンプルに「レビュアー」。

## Consequences

- スキル1（service-discovery）の spawn 対象は5体＋ディレクター。
- **DESIGN.md（デザイン層の出口）はプロダクトデザイナー担当だが、ADR-0020 決定5 で生成機構が未定**。スキル1 初版ではデザイナーは screens / screen-specs のみを担い、DESIGN.md は TODO（機構確定後）。
- ADR-0011 のロスター表・ADR-0014 の S1 行は本 ADR を参照（supersede）。

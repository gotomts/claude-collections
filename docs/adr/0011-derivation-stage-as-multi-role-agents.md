# 企画→プロトタイプブリーフ段を多職種エージェント編成にする（ROADMAP「1スキル」を上書き）

アンカーからプロトタイプブリーフまでの段は、単一スキルではなく **多エージェントのチーム**である。service-designer（固定 15 ページ）＋ prototype-designer（5 成果物・約 25 画面）が**対話**で作っていた corpus を、**対話なしの自律 self-grill** で同じ深さで生成し、Claude Design 用ブリーフを組み立てる。編成は **ディレクター（オーケストレーター＝スキル本体）＋ 専門 6 ＋ 評価 1＝8 体**を、成果物名ではなく**現実の職種**に束ねる。ROADMAP 「最初の一手＝service-derivation スキルを作る」はこの多部品性を過小評価していたため、本 ADR が上書きする。

## Status

accepted（ROADMAP 最初の一手と CONTEXT 品質バーを改訂。ADR-0003 の screen-specs 条項を自律前提で精緻化）

## 職種ロスター（8 体）

| 職種（エージェント） | 担当成果物 |
|---|---|
| ディレクター（オーケストレーター／スキル本体） | 全体統括・依存順起動・評価差し戻し・corpus 統合・ブリーフ生成 |
| UX リサーチャー | persona / usage-scenes |
| プロダクトマネージャー | feature-scope / 機能別詳細素材 / roadmap / specific-topics |
| 事業・マーケストラテジスト | competition / pitch / monetization / marketing / kpi |
| リスク・法務・品質 | risks / legal / nfr-targets |
| プロダクトデザイナー（UX/UI） | design-concept / 画面一覧 / screen-specs |
| デザインシステムエンジニア | design-system / design-tokens |
| プロダクトクリティーク（評価） | 全成果物を anchors・真実源・カバレッジ逆引きで self-grill 評価し該当職種へ差し戻し |

## Considered Options

- **却下: 1 スキルで導出をインラインに回す（ROADMAP 当初）**。成果物は service-designer 15＋prototype-designer 5（約 25 画面）相当で、各々書式・真実源・観点が異なる。1 スキルでは専門性とコヒーレンスを両立できず、薄い corpus しか出ずプロトタイプがお粗末になる。
- **却下: 成果物ごとに専任エージェント（≈19 体）**。専門性は最大だが体数・オーケストレーションが過大で、方針レベルの thin なページに専任は過剰。
- **却下: moodboard を自律生成**。人間が Canvas に参考 UI を貼る視覚作業で自律化に向かない → **廃止**。
- **採用: 現実の職種に束ねた 8 体（heavy 専任＋thin まとめ）**。専門性とコヒーレンス・体数の現実性を両立。

## Consequences

- **screen-specs は「期待値」として先行導出する**（含む機能・状態・遷移・エッジ）。Claude Design に渡し、無駄画面の生成を防ぐ。G2 で期待値とプロトタイプの差を Claude Code（docs）／Claude Design（プロト）で並列訂正して育てる（ADR-0006）。これは ADR-0003「先行画面仕様は重複」を**自律前提で精緻化**：重複だったのは**対話で手書きするコスト**ゆえであり、自律導出ならそのコストは消え、先行導出の方が無駄を防ぎ安い。
- **デザイン層の出口は moodboard ではなく design-system ＋ design-tokens（機械可読）**。Claude Design にトークンを渡し、見た目を自前発明させずトークンに準拠させる。
- **画面一覧はプロトタイプの枠組み（骨格）**。エージェントがドラフト → **人間が枠組みレビュー（G4 相当の軽い関所）** → 以降自律（screen-specs／ブリーフ）。骨格ミスの是正を最も安い段階で行う（ADR-0007 の「枠組みは人間」に整合）。
- **premise シフト**：対話→自律 self-grill ／ Claude Chat→Claude Code ／ Obsidian→repo-native `docs/design/`（ADR-0010）／ prototype-builder→Claude Design（ADR-0003）／ 人間＝アンカー＋ゲート。維持：番号固定ページ・真実源を 1 つ・カバレッジ逆引き。
- **CONTEXT 品質バー**の「自律導出は全画面仕様を生成する」は本 ADR／ADR-0003 に整合させ、screen-specs を「先行導出する期待値かつ G2 で育つ正当化トレイル」と位置づける。
- **既存実装の作り直し**：`skills/service-derivation/SKILL.md` と `agents/service-deriver.md`（commit a509b46）は本モデルに反する（主従逆・4 項目・デザイン層欠落）。作り直し対象。残る未確定（評価ループの差し戻し protocol・`docs/design/` のファイル構成・機能別詳細素材の置き場・マネタイズ境界＝G2 繰り越しの扱い）を詰めてから再実装する。

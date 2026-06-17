# S3/S4/S5 ステージスキルの設計（6観点）と付随決定

S3（技術設計）・S4（分解）・S5（実装）のスキル（＝ディレクター playbook）を、6観点（入力／出力／手順／対話点／ステージ間フィードバック／旧スキルからの移行差分）で設計する。旧 tech-designer / issue-decomposer / feature-team を、自律＋枠組み対話・repo-native・共通形（ADR-0013/0014）へ移行する。

## Status

accepted

## アンカーは4独立ドキュメント（先行する訂正）

アンカー（ADR-0002）は4つの**別ドキュメント**：`anchors/prfaq.md`・`anchors/design-principles.md`・`anchors/provider.md`（③提供形態・PRFAQ とは別）・`anchors/monetization-binary.md`（④二値）。**提供形態は PRFAQ に含めない**（旧 service-designer の「PRFAQ 冒頭で宣言」は踏襲しない）。G1 で確定し、下流（S3 のスタック選定等）は読むだけで決め直さない。

## S3 技術設計スキル

- **入力**：S1 discovery corpus（feature-scope・nfr・screens.md・screen-specs・design-tokens 等）＋ S2 ハンドオフバンドル（プロトタイプ実体）＋ 参考リポジトリ（地図読み）。同 repo の `docs/discovery/` を直読み。
- **出力**：技術設計は `docs/tech/`（ADR-0016）。＋ repo セットアップ＝`AGENTS.md`（正本）・`CLAUDE.md`（`@AGENTS.md` ポインタ）・`DESIGN.md`（Claude Design ハンドオフのデザインシステム）・初期 `docs/adr/`・`CONTEXT.md` を配置/種まき。成果物＝S3 ロスター担当物。
- **手順**：ディレクターが依存順に職種起動（型→スタック→モジュール→ドメイン→運用基盤）→ プリンシパルエンジニア（評価）が設計レビュー・差し戻し（最大3R）→ 完全性ガード。2ステージ境界（コア技術判断→運用判断）で一拍。
- **対話点**：技術スタック選定（与えられた提供形態のもとで・参照リポ確認）／モジュール分割案の確認／ステージ1→2 境界合意／G3。
- **フィードバック**：S3→S1＝技術見積もり（配信実費・コスト・実現可能性）で S1 の繰り越し（マネタイズ価格・NFR 目標値・機能の実現可否）を確定し `docs/discovery/planning/` を更新（最終値は人間が対話で決める）。
- **移行差分**：対話で固める→自律＋枠組み対話／Obsidian→repo-native／単一スキル→ディレクター＋職種6＋評価／完全性ガード・評価差し戻しを追加。型（monorepo＋モジュラーモノリス＋クリーンアーキ＋DDD）・参考リポ地図読みは維持。

## S4 分解スキル

- **入力**：S3 の技術設計（`F-{MODULE}-{連番}` 機能一覧・モジュール構造・ドメインモデル）＋ S1 の screen-specs（受入条件の材料）＋ プロトタイプ実体。同 repo 直読み。必須＝F-ID 機能一覧・モジュール（欠ければ停止）。
- **出力**：**index.md は repo-native**（`docs/` 配下・G4 レビューの骨格）＋ 承認後 **Linear に実 issue 起票**（Linear は維持＝issue トラッカーは外部でよい。repo-native 原則は文書 corpus に限る）。issue 本文＝受入条件・参照リンク・冪等キー `S-{nn}`。
- **手順**：ディレクター → EM/TL がスライス分解（＝1PR）・依存・capability 束ね → QA エンジニアが受入条件（BDD/チェックリスト）生成 → プリンシパルエンジニア（評価）が分解レビュー・差し戻し → 完全性ガード（F-ID カバレッジ漏れゼロ）。器構築 issue を依存の根に。
- **対話点**：index.md レビュー（粒度・依存・タグ・束ね境界＝G4）＋ 起票の明示承認（外部書き込み・省略不可）。
- **タグ**：**HITL/AFK は ADR-0005 通り「self-grill への粗いヒント」として残す**（完全廃止しない）。これとは別レイヤで **ADR-0008 のレビュー要否タグ（根幹/非根幹）**を G4 で付け、G5 の自動 merge/人間 merge を分ける。
- **移行差分**：対話→自律＋枠組み対話／index.md を Obsidian→repo-native／推奨スキル注釈（dev-\*）→ 職種スキル割当（ADR-0014）／feature-team 前提（参照リンク経由のみ）は S5 作り直しに合わせ見直し。

## S5 実装スキル

- **入力**：Linear issue（依存順・受入条件・参照リンク）＋ 同 repo の技術設計 docs（CLAUDE.md/ADR/CONTEXT/screen-specs）を直読み。
- **出力**：コード＋テスト＋ PR（GitHub・1スライス=1PR）＋ 実装知見を ADR/CONTEXT に追記。
- **手順**：ディレクターが束ね親（capability）単位で起動 → 該当スタックの開発エンジニアを並列でスライス実装 → 評価3観点（品質/セキュリティ/性能）がレビュー・差し戻し（最大3R）→ PR。停止ゼロ（decide-record-proceed・仮定は PR に明記）。完全性ガード（受入条件充足）。
- **テスト（QA を置かない＝option 2）**：開発エンジニアが unit/widget/受入/E2E を書く（垂直スライス＝test を貫く）。網羅性は評価3観点が見る。**E2E 方針はスタック依存で S3 テスト戦略が決める**：Web は Playwright で E2E をしっかり／モバイルは Maestro（RN/Expo）・integration_test＋patrol（Flutter）で**主要フローに絞り**、網羅は integration/widget で稼ぐ（フル網羅 E2E はモバイルでは非現実的）。CI は Firebase Test Lab 等。
- **対話点**：G5 PR レビュー＋merge（根幹のみ・ADR-0008）。非根幹は自動 merge。実装途中は停止しない（ADR-0004）。
- **フィードバック**：実装で設計の穴・screen-specs の曖昧が出たら decide-record-proceed で仮定を PR に明記、ADR 候補は ADR を書いて PR で晒す。重大なら S3/S1 へ差し戻し。
- **移行差分**：補助設計（feature-team の Phase 0/3/3.5 停止）→ 停止ゼロ自走／dev-\*/rev-\* エージェント→ 実在職種（スキルは存続・ADR-0014）／pr-publisher → ディレクター吸収。

## Consequences

- S5 ロスターは QA を外し8体（ADR-0014 を更新）。
- 技術設計・分解・実装の repo-native 出力構成は別途確定（議題：各ステージの出力構成）。

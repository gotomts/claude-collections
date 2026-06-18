---
name: tech-design
description: 完成したプロトタイプ(Claude Design ハンドオフ)と S1 discovery corpus を起点に、技術スタック・アーキテクチャ・モジュール構成・ドメインモデル・運用基盤を固めたいときに使う、AI 自律開発ハーネスのステージ3(技術設計)スキル。サービス repo のセットアップ(AGENTS.md/CLAUDE.md/初期 ADR/CONTEXT 種まき)もここで行う。企画は上流(service-discovery)、分解・実装は下流スキルの責務。
maintainer: gotomts
---

# tech-design

AI 自律開発ハーネスの **ステージ3（技術設計）** スキル。実行環境は **Claude Code**。スキル本体を読んだメインセッションが**ディレクター**となり、職種エージェントを依存順に起動して技術設計 corpus を自律導出し、サービス repo をセットアップする。共通ステージ形（ADR-0013）＝ディレクター＋職種＋評価。

到達点：**完成プロトタイプ → 実装可能な技術設計**を、人間の枠組み対話（スタック・モジュール・G3）だけで、黙って欠落を通さずに固める。

## いつ使うか

- プロトタイプ（Claude Design）が固まり、本実装の技術を決める段階に入ったとき。
- 既存の S1 corpus ＋ プロトタイプから、スタック・アーキ・モジュール・ドメインモデルを起こしたいとき。
- ハーネス4スキル（ADR-0017）の2番目として人間が起動するとき。

**ここで扱わないこと**：企画・デザイン（上流 service-discovery）。issue 分解・実装（下流スキル）。

## 入力

- **S1 discovery corpus**：同 repo `docs/discovery/`（feature-scope・nfr・screens.md・screen-specs・planning）を直読み。
- **プロトタイプ実体**：Claude Design ハンドオフバンドル（HTML/CSS/JS・スクショ・component spec・DESIGN.md）。**DESIGN.md は読むだけ**（配置はしない・ADR-0020）。
- **参考リポジトリ**：あれば**地図読み**（構成の参考にする。丸コピーしない）。

## ステージ構造（2ステージ＋G3）

```
ステージ1: コア技術判断(型→スタック→モジュール→ドメインモデル)
  →〔一拍: 人間とスタック・モジュール分割を確認〕
ステージ2: 運用判断(インフラ・IaC・CI/CD・非機能実現・運用基盤)
  → アーキ/インフラゲート(人間/G3 検証)
  → S3→S1 フィードバック(価格/NFR/実現可否を確定し planning 更新)
```

## 設計スタンス（既定の型・ADR-0015）

- **既定＝monorepo ＋ モジュラーモノリス ＋ クリーンアーキテクチャ ＋ DDD**。ゼロから選び直さず、この型を起点にする。
- **スタックは提供形態（`anchors/provider`）を起点に決める**（Web / iOS / Android / 複数）。
- 参考リポジトリは**地図読み**（構成・規約の参考。コピーしない）。

## ロスターと依存順

| エージェント | 担当 |
|---|---|
| `software-architect` | アーキ・ディレクトリ構成・モジュール一覧・型・ドメインモデル(Mermaid)・接頭辞付き機能一覧 `F-{MODULE}-{連番}`・ユビキタス言語(CONTEXT 種まき) |
| `tech-lead` | 技術スタック・`AGENTS.md`(正本)＋`CLAUDE.md`(ポインタ)・開発プロセス・git 運用・テスト戦略 |
| `infrastructure-engineer` | インフラ・IaC・CI/CD・非機能実現・運用基盤 |
| `security-engineer` | セキュリティ設計 |
| `principal-engineer` | 評価（設計レビュー・差し戻し・ADR-0018） |

依存順：型/スタック → モジュール → ドメインモデル → 運用基盤。ステージ1（architect・tech-lead）合格 → ステージ2（infra・security）。

## ディレクター制御フロー

スキル1（service-discovery）と同型。**Agent tool**（`subagent_type`＝エージェント名）で spawn、**ADR-0018 の評価ループ**（インクリメンタル＋依存順・round1 fresh→凍結 continuation・成果物ごと3R・上流再オープン深さ1）、**完全性ガード**（期待マニフェスト＝tech corpus ＋ repo セットアップ一式、✅/➖/⚠️）、ゲートで**ギャップレポート＋繰り越し一覧**を提示（ADR-0019）。`principal-engineer` が評価役。

## 対話点

技術スタック選定（提供形態のもと・参照リポ確認）／モジュール分割案の確認／ステージ1→2 境界の合意／G3（アーキ・インフラ検証）。決めるのは人間、書くのは AI（ADR-0012）。

## S3→S1 フィードバック

技術見積もり（配信実費・コスト・実現可能性）で、S1 の繰り越し／⚠️保留（マネタイズ価格・NFR 目標値・機能の実現可否）を確定・修正し `docs/discovery/planning/` を更新する（最終値は人間が対話で決める・ADR-0013）。

## 出力レイアウト（ADR-0016）

```
<service-repo>/
├── AGENTS.md     # エージェント横断の指示(正本・tech-lead)
├── CLAUDE.md     # @AGENTS.md ポインタ(tech-lead)
├── CONTEXT.md    # ユビキタス言語の種まき(architect)
├── docs/
│   ├── adr/      # 初期 ADR の種まき
│   └── tech/     # スタック/アーキ/モジュール/F-ID/ドメインモデル/開発の進め方/運用基盤
└── (DESIGN.md は S1 後に作成済み・S3 は読むだけ・ADR-0020)
```

## self-grill・decide-record-proceed・繰り越し

スキル1 と同じ（ADR-0004/0005/0019）。曖昧点は根拠ある決定を下し**担当ページに inline** で残して進む。専用の決定ログ file は作らない。アーキ判断で不可逆・驚き・実トレードオフのものは**初期 ADR**として種まき。繰り越しは ⚠️繰り越し マーカー。

## 破壊的操作の禁止

push / PR / merge / 課金 / 外部送信はしない。repo へのファイル書き込みと commit に留める。

## 関連 ADR

ステージ全体＝ADR-0013/0017。ロスター＝ADR-0014。スキル設計（6観点）＝ADR-0015。評価ループ＝ADR-0018。決定記録＝ADR-0019。DESIGN.md＝ADR-0020。レイアウト＝ADR-0016。

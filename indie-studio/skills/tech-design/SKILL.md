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
- **S1a stack-direction 出力**（**読むだけ**・決め直さない・ADR-0026）：`docs/tech/stack-direction/stack.md` / `data-profile.md` / `third-party.md` / `build-vs-buy.md`。スタック・データプロファイル基本・3rd party 制約・build vs buy 判定は本スキルでは決め直さず、S1a 確定値を起点に詳細化する。
- **プロトタイプ実体**：Claude Design ハンドオフバンドル（HTML/CSS/JS・スクショ・component spec・DESIGN.md）。**DESIGN.md は読むだけ**（配置はしない・ADR-0020）。
- **参考リポジトリ**：あれば**地図読み**（構成の参考にする。丸コピーしない）。

## ステージ構造（2ステージ＋G3）

```
ステージ1: コア技術判断
  - スタック → 読むだけ（S1a 確定済・ADR-0026）
  - モジュール → software-architect
  - ドメインモデル → software-architect
  - パフォーマンス予算 → software-architect（追加・ADR-0027）
  - build vs buy 詳細 → tech-lead（追加・ADR-0027）
  →〔一拍: 人間とモジュール分割を確認〕
ステージ2: 運用判断
  - インフラ・IaC・CI/CD・非機能実現 → infrastructure-engineer
  - セキュリティ設計 → security-engineer
  - コスト積算 → infrastructure-engineer（追加・ADR-0027）
  - 運用 sustainability → infrastructure-engineer（追加・ADR-0027）
  - 規制・法令 → security-engineer（追加・ADR-0027）
  - リスク台帳 → principal-engineer（追加・ADR-0027）
  → アーキ/インフラゲート（人間/G3、実現可能性スコアカード付き・ADR-0027）
  → S3→S1 フィードバック（価格/NFR/実現可否を確定し planning 更新）
```

## 設計スタンス（既定の型・ADR-0015）

- **既定＝monorepo ＋ モジュラーモノリス ＋ クリーンアーキテクチャ ＋ DDD**。ゼロから選び直さず、この型を起点にする。
- **スタックは提供形態（`anchors/provider`）を起点に決める**（Web / iOS / Android / 複数）。
- 参考リポジトリは**地図読み**（構成・規約の参考。コピーしない）。

## ロスターと依存順

| エージェント | 担当（既存 + ADR-0027 追加観点） |
|---|---|
| `software-architect` | アーキ・ディレクトリ構成・モジュール一覧・型・ドメインモデル(Mermaid)・接頭辞付き機能一覧 `F-{MODULE}-{連番}`・ユビキタス言語(CONTEXT 種まき)・**パフォーマンス予算（NFR→技術選定マッピング・追加）** |
| `tech-lead` | （スタックは S1a 確定済を読むだけ）・`AGENTS.md`(正本)＋`CLAUDE.md`(ポインタ)・開発プロセス・git 運用・テスト戦略・**build vs buy 詳細（コスト試算・SLA リスク・移行コスト・追加）** |
| `infrastructure-engineer` | インフラ・IaC・CI/CD・非機能実現・運用基盤・**コスト積算（追加）**・**運用 sustainability（追加）** |
| `security-engineer` | セキュリティ設計・**規制・法令（GDPR / accessibility / 業界規制・追加）** |
| `principal-engineer` | 評価（設計レビュー・差し戻し・ADR-0018）・**リスク台帳（SPOF / ベンダーロックイン / bus factor / 追加）**・**G3 スコアカード派生ビュー（追加）** |

依存順：（スタックは S1a 確定済）→ モジュール → ドメインモデル → パフォーマンス予算 → build vs buy 詳細 → 運用基盤 → コスト積算・運用 sustainability・規制・リスク台帳。ステージ1（architect・tech-lead）合格 → ステージ2（infra・security・principal）。

## ディレクター制御フロー

スキル1（service-discovery）と同型。**Agent tool**（`subagent_type`＝エージェント名）で spawn、**ADR-0018 の評価ループ**（インクリメンタル＋依存順・round1 fresh→凍結 continuation・成果物ごと3R・上流再オープン深さ1）、**完全性ガード**（期待マニフェスト＝tech corpus ＋ repo セットアップ一式、✅/➖/⚠️）、ゲートで**ギャップレポート＋繰り越し一覧**を提示（ADR-0019）。`principal-engineer` が評価役。

## 対話点

技術スタック選定（提供形態のもと・参照リポ確認）／モジュール分割案の確認／ステージ1→2 境界の合意／G3（アーキ・インフラ検証）。決めるのは人間、書くのは AI（ADR-0012）。

## G3 ゲート：実現可能性スコアカード（ADR-0027）

G3 ゲートで人間に晒すべき意思決定情報を 1 枚に集約する。`principal-engineer` が完了報告に**派生ビュー（集約参照）**として組み込み、専用ログファイルは作らない（ADR-0019）。観点 12 軸（既存 6 + ADR-0027 追加 6）ごとに **A 成立 / B 疑義あり / C 困難** を A/B/C で表示する。

形式：

```
## 実現可能性スコアカード（G3 ゲート用・派生ビュー）

| 観点 | スコア | 根拠（1 行） |
|---|---|---|
| スタック適合性 | A/B/C | <根拠> |
| データプロファイル実現性 | A/B/C | <根拠> |
| 3rd party 制約適合 | A/B/C | <根拠> |
| build vs buy 妥当性 | A/B/C | <根拠> |
| パフォーマンス予算 | A/B/C | <根拠> |
| コスト持続性 | A/B/C | <根拠> |
| 運用 sustainability | A/B/C | <根拠> |
| 規制適合 | A/B/C | <根拠> |
| セキュリティ設計 | A/B/C | <根拠> |
| リスク台帳 | A/B/C | <根拠> |
| モジュール構成 | A/B/C | <根拠> |
| ドメインモデル | A/B/C | <根拠> |
```

- 人間は B/C を見て「許容するか／設計に戻すか」を判断する（決めるのは人間、書くのは AI／ADR-0012）。
- B/C の判断結果は ADR-0019 inline 規律で各観点ページに残し、G3 では別ファイルを作らない。
- スコアカードは findings 一覧の**コピーではなく集約参照**（同じ事実を 2 箇所に書かない・ADR-0024 `Red-team index` と同型）。

## S3→S1 フィードバック

技術見積もり（配信実費・コスト・実現可能性）で、S1 の繰り越し／⚠️保留（マネタイズ価格・NFR 目標値・機能の実現可否）を確定・修正し `docs/discovery/planning/` を更新する（最終値は人間が対話で決める・ADR-0013）。

## 出力レイアウト（ADR-0016 / 0027）

```
<service-repo>/
├── AGENTS.md     # エージェント横断の指示(正本・tech-lead)
├── CLAUDE.md     # @AGENTS.md ポインタ(tech-lead)
├── CONTEXT.md    # ユビキタス言語の種まき(architect)
├── docs/
│   ├── adr/      # 初期 ADR の種まき
│   └── tech/
│       ├── stack-direction/  # S1a 確定済（読むだけ）
│       │   ├── stack.md
│       │   ├── data-profile.md
│       │   ├── third-party.md
│       │   └── build-vs-buy.md
│       ├── architecture.md       # アーキ・モジュール構成（architect）
│       ├── domain-model.md       # ドメインモデル（architect）
│       ├── perf-budget.md        # ★追加：パフォーマンス予算（architect・ADR-0027）
│       ├── build-vs-buy-detail.md # ★追加：build vs buy 詳細（tech-lead・ADR-0027）
│       ├── ops.md                 # インフラ・IaC・CI/CD・非機能（infra）
│       ├── cost-model.md         # ★追加：コスト積算（infra・ADR-0027）
│       ├── ops-sustainability.md # ★追加：運用 sustainability（infra・ADR-0027）
│       ├── security.md           # セキュリティ設計（security）
│       ├── compliance.md         # ★追加：規制・法令（security・ADR-0027）
│       └── risk-register.md      # ★追加：リスク台帳（principal・ADR-0027）
└── (DESIGN.md は S1b 後に作成済み・S3 は読むだけ・ADR-0020)
```

## self-grill・decide-record-proceed・繰り越し

スキル1 と同じ（ADR-0004/0005/0019）。曖昧点は根拠ある決定を下し**担当ページに inline** で残して進む。専用の決定ログ file は作らない。アーキ判断で不可逆・驚き・実トレードオフのものは**初期 ADR**として種まき。繰り越しは ⚠️繰り越し マーカー。

## 破壊的操作の禁止

push / PR / merge / 課金 / 外部送信はしない。repo へのファイル書き込みと commit に留める。

## 関連 ADR

ステージ全体＝ADR-0013/0017。ロスター＝ADR-0014。スキル設計（6観点）＝ADR-0015（強化＝ADR-0027）。評価ループ＝ADR-0018。決定記録＝ADR-0019。DESIGN.md＝ADR-0020。レイアウト＝ADR-0016/0027。スタック関連の入力＝ADR-0026（S1a stack-direction）。実現可能性 6 観点と G3 スコアカード＝ADR-0027。命名規約＝ADR-0025。

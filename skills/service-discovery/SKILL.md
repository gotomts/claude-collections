---
name: service-discovery
description: アンカー4点(PRFAQ / デザイン原則 / 提供形態 / マネタイズ二値)からサービスの企画・デザイン discovery corpus と Claude Design 用プロトタイプブリーフを起こしたいときに使う、AI 自律開発ハーネスのステージ1スキル。新規サービスをアンカーから立ち上げる・既存アンカーから企画を導出する・プロトタイプを作る前段を整える、といった場面で使う。技術設計・分解・実装は下流スキルの責務でここでは扱わない。
maintainer: gotomts
---

# service-discovery

AI 自律開発ハーネスの **ステージ1（G1 アンカー＋S1 導出 → ブリーフ）** スキル。実行環境は **Claude Code**。このスキルを読んだメインセッションが**ディレクター**となり、人間とアンカーを対話で固め、職種エージェントを依存順に起動して discovery corpus を自律導出し、Claude Design へ渡すプロトタイプブリーフまで組み上げる。

到達点：**「アンカー → 触れるプロトタイプの直前」までを、人間の一問一答ゼロ（アンカー対話を除く）で、黙って欠落を通さずに支える**。質は対話量ではなく self-grill の徹底度から出す（ADR-0004/0005）。

## いつ使うか

- 4つのアンカー（PRFAQ・デザイン原則・提供形態・マネタイズ二値）を人間と決め、そこから企画・デザインを自律導出したいとき。
- 既存アンカー（repo の `docs/discovery/anchors/`）から corpus とブリーフを起こしたいとき。
- ハーネスの4スキル（ADR-0017）の1番目として、人間が起動するとき。

**ここで扱わないこと**：技術スタック・アーキテクチャ・分解・実装（下流スキル）。プロトタイプ生成そのもの（Claude Design＝claude.ai・S2）。

## ステージ構造

```
G1 アンカー対話(type-2: 人間が決め AI が書く)
  → S1 自律導出(職種エージェント×依存順 + レビュアー評価ループ)
  → 画面一覧レビュー(軽い人間ゲート)
  → 残り自律導出(screen-specs)
  → ブリーフ組み上げ
  → 人間が claude.ai(Claude Design)へ  ← このスキルの終端
```

- 各点の「決める／検証する」は人間、**書くのは AI**（ADR-0012）。
- DESIGN.md（デザイン憲法）の組み上げは **生成機構が未確定（ADR-0020 決定5）**。本スキル初版では扱わず TODO（後述）。

## 入力（アンカー4点）

ADR-0002 / 0015。4つの**別ドキュメント**：

| ファイル | 内容 | 決め方 |
|---|---|---|
| `anchors/prfaq.md` | 価値とゴール（PR・ゴールライン・FAQ） | G1 対話 |
| `anchors/design-principles.md` | 優先順位（トレードオフ） | G1 対話 |
| `anchors/provider.md` | 提供形態（iOS/Web 等・PRFAQ とは別） | G1 対話 |
| `anchors/monetization-binary.md` | マネタイズする/しない（二値） | G1 対話 |

既に `anchors/` にあれば読むだけ（決め直さない）。無ければ G1 対話で人間と固め、AI が書き出す。

## G1：アンカー対話（type-2）

- 4アンカーだけを人間と対話で決める。**ペルソナ・使用シーン以降は対話しない**（自律導出）。
- 確認質問は **1ターンに1つ・yes/no か番号**で（散文の開いた質問をしない）。
- 決めるのは人間、**書くのは AI**。合意できたアンカーから `anchors/` に書き出す。
- 提供形態が未確定なら S1 の画面導出に進めない（下流が前提にする）。ここで確定させる。

## S1：ロスターと依存順

ディレクター（＝スキル本体）が、5つの職種エージェントを **依存順** に起動する（ADR-0022）。

| エージェント | 担当成果物 | 依存 |
|---|---|---|
| `ux-researcher` | persona / usage-scenes | アンカー |
| `product-manager` | feature-scope / roadmap / specific-topics / risks-assumptions / nfr-targets | persona・usage-scenes |
| `business-strategist` | competition / pitch / monetization / marketing / kpi / legal | feature-scope |
| `product-designer` | screens.md / screen-specs/&lt;area&gt;/ | feature-scope（＋ persona・design 原則） |
| `reviewer` | 全成果物の評価・差し戻し（独立職種） | 各成果物 |

依存順の目安：persona → feature-scope → （competition/pitch ほか並列）→ screens.md →〔画面一覧レビュー〕→ screen-specs。独立な成果物は並列起動してよい。

## ディレクター制御フロー

1. **インクリメンタル＋依存順ゲーティング**（ADR-0018）：担当職種が成果物を出す → `reviewer` が即評価 → 合格してから依存下流を起動。バッチ評価しない。
2. **評価ループ**（ADR-0018）：成果物ごとに最大3ラウンド差し戻し。round1 の `reviewer` は fresh で完全な findings マニフェスト、round2-3 は continuation で解消のみ検証（スコープ凍結）。担当職種は continuation 再起動。finding ごとに ✅解消／➖省略(理由)／⚠️未達(理由) を返す。
3. **上流再オープン**（ADR-0018）：下流評価中に上流の構造的欠陥（`blocker`）が判明したら、ディレクター判断で上流を1段だけ再オープン（深さ1・上流自身の残り3R を消費）。枯渇なら decide-record-proceed。
4. **完全性ガード**（ADR-0011）：期待マニフェストを持ち、各成果物を ✅/➖/⚠️ で決着。
5. **ゲートレポート**：ゲート（画面一覧レビュー）で、➖省略/⚠️未達（ギャップレポート）＋ ⚠️繰り越し マーカー一覧（繰り越し決定）を人間に提示（ADR-0019）。黙って欠落を通さない。

## self-grill・decide-record-proceed・繰り越し

- **self-grill**（ADR-0005）：各職種は griller と answerer を兼ね、anchors を答え合わせ材料に自答して精緻化する。人間に質問を投げない（停止しない）。
- **decide-record-proceed**（ADR-0004）：曖昧点は根拠ある決定を下し、根拠を**担当ページに inline** で残して進む。専用の決定ログ file は作らない（ADR-0019）。
- **繰り越し決定**（ADR-0019）：触ってから決めるべき判断（第1号＝マネタイズ無料/有料境界）は、所有ページに **⚠️繰り越し マーカー＋候補**を inline で残す。ディレクターがゲートで走査・提示し、G2 で人間が確定する。

## 画面一覧レビュー（軽い人間ゲート）

- `product-designer` が `screens.md`（画面一覧）をドラフト → **人間が枠組み（骨格）をレビュー**（ADR-0011・G4 相当の軽い関所）。
- 骨格ミスを最も安い段階で正す。承認後は自律で screen-specs へ進む。
- ここでディレクターはゲートレポート（ギャップ＋繰り越し）を併せて提示する。

## 出力レイアウト

サービス repo の `docs/discovery/`（ADR-0016 / 0021）：

```
docs/discovery/
├── anchors/    prfaq / design-principles / provider / monetization-binary
├── planning/   01,02,05-14,99 (番号固定・feature-details は無い)
├── design/     screens.md ・ screen-specs/<area>/<screen>.md
└── brief.md
```

- 番号固定ページ（service-designer 由来の 01-14,99 から 03/04・09二値を anchors へ抜いたもの）。下流がファイル名を名指し参照できるよう番号は安定させる。
- `screen-specs/<area>/` の `<area>` は feature-scope の機能グループ（ユーザー行動軸）を流用（ADR-0021）。
- 機能軸の業務ルールは該当 screen-spec に inline で attach（feature-details は廃止・ADR-0021）。
- 視覚デザイン（DESIGN.md）は repo-root・本スキルでは未実装（下記 TODO）。

## ブリーフ組み上げ

- 導出 corpus（特に screen-specs＝先行導出した期待値・ADR-0011）から、Claude Design に渡す `brief.md` を組み上げる。
- screen-specs は「無駄画面を作らせない」ための期待値。G2 でプロトタイプとの差を訂正して育てる（書き戻し・ADR-0006/0013）。
- 完了時、人間に「次は claude.ai（Claude Design）でプロトタイプ」と案内してこのスキルを終える。

## 品質バー（端折り禁止）

- 「minimal」は人間の入力最小化を指し、**導出物の最小化ではない**（ADR-0011）。全画面・全状態を端折らない。
- 抽象語で止めない（「落ち着いた」→ 具体の決定まで）。お粗末なプロトタイプ設計は不可。

## 破壊的操作の禁止

- push / PR / merge / 課金 / 外部送信はしない。repo へのファイル書き込みと commit に留める。
- アンカーは決め直さない（G1 で確定済み・下流は読むだけ）。

## TODO（未確定）

- **DESIGN.md（デザイン憲法）の生成**：ADR-0020 決定5 で生成機構が未定。mood/aesthetic は**人間との枠組み対話＋参考画像入力**を要し純自律でない。担い手＝プロダクトデザイナー（ADR-0022）だが、いつ・どの環境で・何から組み上げるかが未確定のため**本スキル初版では実装しない**。確定後に追加する。

## 関連 ADR

ステージ全体＝ADR-0013 / 0017。職種＝ADR-0022。評価ループ＝ADR-0018。決定記録＝ADR-0019。DESIGN.md＝ADR-0020。レイアウト＝ADR-0016 / 0021。アンカー＝ADR-0002 / 0015。

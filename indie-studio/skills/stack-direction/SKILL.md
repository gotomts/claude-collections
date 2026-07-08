---
name: stack-direction
description: アンカー4点（特に provider＝提供形態）と S1 discovery corpus を起点に、プロトタイプ前に握るべき技術判断 4 観点（スタック決定 / データプロファイル当たり / 3rd party 依存と制約 / build vs buy）を tech-lead が self-grill で導出して docs/indie-studio/tech/stack-direction/ に書き出したいときに使う、AI 自律開発ハーネスのサブステージ S1a スキル。上流＝S1 service-discovery（discovery corpus）、下流＝S1b design-direction（DESIGN.md の Components が本スキル出力に依存する）。S3 tech-design はここで決まったスタックを読むだけ。新規プロトタイプ前の技術判断起こしと既存判断の更新の両方に使う。モジュール構成・ドメインモデル・運用基盤は下流（S3 tech-design）の責務でここでは扱わない。
maintainer: gotomts
---

# stack-direction

AI 自律開発ハーネスの **サブステージ S1a（S1 後段 → S1b 入力起こし）** スキル。実行環境は **Claude Code**。このスキルを読んだメインセッションが**ディレクター**となり、アンカー（特に `provider`）と S1 discovery corpus を起点に、`tech-lead` を依存順に起動して技術判断 4 観点を自律導出する。プロトタイプ品質に直結する技術制約を S2 より前に確定させ、`S1b design-direction` の DESIGN.md `## Components` が提供形態と整合するようにする（ADR-0026）。

到達点：**プロトタイプの interaction 雛形（iOS HIG / Material / Web）と build vs buy の方針を、人間ゲート 0〜2 回の対話だけで決め切る**。質は対話量ではなく self-grill の徹底度から出す（ADR-0004 / 0005 / 0026）。

## いつ使うか

- `service-discovery`（S1）が完了し、`docs/indie-studio/discovery/` に anchors + planning + design が揃った状態で、プロトタイプ前に握るべき技術判断（スタック / データプロファイル / 3rd party 制約 / build vs buy）が**まだ無い**とき。
- 既存の技術判断を update したいとき（提供形態変更・3rd party の rate limit 変更等）。
- ハーネスの 6 スキル（ADR-0017 / 0023 / 0026）の **S1a** として、S1 と S1b の間で人間が起動するとき。

**ここで扱わないこと**：モジュール構成・ドメインモデル・運用基盤（下流 S3 tech-design の責務）／DESIGN.md 組み上げ（下流 S1b design-direction）／プロトタイプ生成そのもの（Claude Design＝claude.ai・S2）。

## ステージ構造

```
S1 完了（anchors + planning + design）
  → ステージ1: スタック判断（提供形態 + データプロファイル → スタック候補）
    →〔一拍: スタック候補の確認（提供形態が複数の場合のみ）〕
  → ステージ2: 3rd party + build vs buy 判断
    →〔一拍: build vs buy 方針確認（PRFAQ にオフライン優先等の制約がある場合のみ）〕
  → 完全性ガード → S1b design-direction へ
```

- 各点の「決める／検証する」は人間、**書くのは AI**（ADR-0012）。
- 対話点は**条件付き発火**（該当なしなら全自走・ADR-0004）。

## 入力

| 区分 | 中身 | 場所 |
|---|---|---|
| 必須 | アンカー4点（PRFAQ・デザイン原則・**提供形態**・マネタイズ二値）― 提供形態が起点 | `docs/indie-studio/discovery/anchors/` |
| 必須 | feature-scope（扱う機能）・nfr-targets（NFR 目標値）― データプロファイル / 3rd party 判定の材料 | `docs/indie-studio/discovery/planning/` |
| 推奨 | persona / usage-scenes ― data freshness / 利用頻度の判定材料 | `docs/indie-studio/discovery/planning/` |

## 出力

`<service-repo>/docs/indie-studio/tech/stack-direction/` 配下に 4 ファイル（ADR-0026）：

```
docs/indie-studio/tech/stack-direction/
├── stack.md          # スタック選定と根拠（言語・FW・主要ライブラリ・データストア）
├── data-profile.md   # 扱うデータの種別・量・成長・freshness の当たり
├── third-party.md    # 3rd party 依存一覧と hard constraints（rate limit・料金・SLA・ToS）
└── build-vs-buy.md   # foundational capability ごとの build / buy 判定表
```

各ファイルは prose first（散文で「何を」「なぜ」「どう」を 2-3 文上限で）+ 構造化データ second（YAML 表 / Markdown 表）。決定根拠は inline（ADR-0019）。

## ロスターと依存順

ディレクター（＝スキル本体）が 2 つの職種エージェントを **依存順** に起動する（ADR-0013 共通形 / ADR-0026）。

| エージェント | 担当成果物 | 依存 |
|---|---|---|
| `tech-lead` | stack.md / data-profile.md / third-party.md / build-vs-buy.md（4 観点を一体で担当） | アンカー・S1 corpus |
| `reviewer` | 全成果物の評価・差し戻し（独立職種） | 各成果物 |

依存順：stack + data-profile（一体）→ third-party → build-vs-buy。`tech-lead` 内で順に書き、`reviewer` が成果物ごとにインクリメンタル評価。

## ディレクター制御フロー

**起動機構**：ディレクターは `tech-lead` を **Agent tool**（`subagent_type=tech-lead`）で spawn。プロンプトに `mode=stack-direction`・アンカーの所在・S1 corpus の所在・出力先（`docs/indie-studio/tech/stack-direction/`）を渡す。差し戻しは continuation で再起動（ADR-0018）。

**起動 context（中立 agent への invocation 必須要素・ADR-0031）**：`shared/agents/` の `tech-lead` / `reviewer` は body に indie-studio 固有値を持たない中立 agent（入力契約で「呼び出し元 skill が指定」と宣言）。上記の mode/所在/出力先に加え、次も prompt へ**明示的に埋める**。

- **`tech-lead`**: **architecture 規約**＝クリーンアーキ ＋ DDD（既定の型・スタックはこの型と矛盾させない）。**stage**＝`stage=1`（stack ＋ data-profile）→ `stage=2`（third-party ＋ build-vs-buy）を continuation で。**進行 protocol**＝停止ゼロ（条件付き発火の対話点 2 つを除く）／decide-record-proceed（根拠は担当ページ inline・ADR-0019）／未決は `⚠️繰り越し` マーカー＋候補を inline。**品質バー**＝抽象語で止めない（「クラウド」→ AWS/GCP/Vercel、3rd party hard constraints は数値・料金プランまで）。
- **`reviewer`**: **評価観点**＝上流（アンカー・S1 corpus）整合／既約性（恣意的でないか）／prose first・tokens second／内部一貫性。**差し戻し protocol**＝成果物ごと round1 fresh→continuation・最大 3R（ADR-0018）。

**期待マニフェスト**（完全性ガードの基準）：4 成果物（stack / data-profile / third-party / build-vs-buy）。各成果物を ✅生成合格 / ➖省略(理由) / ⚠️未達(理由) で決着（ADR-0011）。

**並列/直列**：4 観点は依存関係が強い（stack ← data-profile → third-party → build-vs-buy）ため直列実行。`reviewer` の差し戻しは成果物単位で independent に最大 3R（ADR-0018）。

1. **ステージ1 起動**：`tech-lead` を `mode=stack-direction stage=1` で spawn。stack.md + data-profile.md を一体で生成。
2. **対話点 1（条件付き）**：提供形態（`provider.md`）が複数（例：Web + iOS）の場合、優先順を yes/no か番号で人間確認。単一なら全自走。
3. **ステージ1 評価**：`reviewer` を spawn。差し戻しがあれば `tech-lead` を continuation で再起動（最大 3R）。
4. **ステージ2 起動**：`tech-lead` を `mode=stack-direction stage=2` で continuation 再起動。third-party.md + build-vs-buy.md を生成。
5. **対話点 2（条件付き）**：PRFAQ / design-principles に「オフライン優先」「自前 UI 必須」等の制約がある場合、build vs buy の方針を yes/no か番号で人間確認。該当なしなら全自走。
6. **ステージ2 評価**：`reviewer` で評価ループ。
7. **完全性ガード**：4 成果物を ✅/➖/⚠️ で決着。
8. **⚠️繰り越し提示**：プロトを触ってから決めるべき論点は `⚠️繰り越し` マーカー + 候補を inline で残し、ディレクターが終端でレポート（ADR-0019）。

## 対話点（条件付き発火）

1. **スタック候補の確認**（提供形態が複数の場合）：「提供形態が Web + iOS の両方ですが、プロトタイプは [1] Web 優先 [2] iOS 優先 [3] 同時 のどれを優先しますか？」
2. **build vs buy 方針確認**（PRFAQ に特定制約がある場合）：「PRFAQ に "オフライン優先" がありますが、auth は [1] SaaS（Apple/Google Sign-In）採用 [2] 自前実装（オフライン対応強化）のどちらにしますか？」

両方とも該当しなければ**全自走**（ADR-0004 規律内、アンカー対話を除く一問一答ゼロ）。

## self-grill 観点

- スタックが提供形態から既約か（恣意的でないか）／既定の型（クリーンアーキ + DDD）と矛盾しないか。
- データプロファイルの「量・成長」が NFR 目標値と整合しているか（指数的な scaling cost を見逃していないか）。
- 3rd party の rate limit が無料プラン UX を成立させない場合に、料金プラン or 自前実装の選択肢を build-vs-buy で吸収しているか。
- build vs buy の判定が PRFAQ / design-principles の制約と矛盾しないか（オフライン優先なのに SaaS auth を選ぶ等の矛盾を出していないか）。
- 4 観点の出力が prose first / tokens second になっているか（YAML 表だけで終わっていないか）。

## decide-record-proceed・繰り越し

- **self-grill**（ADR-0005）：`tech-lead` は griller と answerer を兼ね、アンカーと S1 corpus を答え合わせ材料に自答する。人間に質問を投げない（停止しない、条件付き発火の対話点 2 つを除く）。
- **decide-record-proceed**（ADR-0004）：曖昧点は根拠ある決定を下し、根拠を**該当ページに inline** で残して進む。専用の決定ログ file は作らない（ADR-0019）。
- **繰り越し決定**（ADR-0019）：プロトを触ってから決めたい論点（例：3rd party の SaaS A vs B の選定）は `⚠️繰り越し` マーカー + 候補を inline で残し、ディレクターが終端でレポート提示。G2 で人間が確定する。

## 下流への影響

- **`S1b design-direction`**：`## Components` セクションを書くときに本スキルの `stack.md` と `build-vs-buy.md` を読む。提供形態固有の component 仕様（HIG button / Material button / Web button 等）と SaaS 採用箇所の組み込み UX（Stripe Checkout の hosted page / Apple Sign-In の native sheet 等）が DESIGN.md に整合する。
- **`S3 tech-design`**：本スキル出力（4 ファイル）を**読むだけ**で決め直さない。S3 ステージ1 の「型 → スタック → モジュール → ドメインモデル」のうち、スタック関連は本スキル確定済として扱い、S3 では「モジュール → ドメインモデル → パフォーマンス予算 → build vs buy 詳細」に注力する（ADR-0027）。

## 品質バー（端折り禁止）

- 「minimal」は人間の入力最小化を指し、**導出物の最小化ではない**（ADR-0011）。4 観点を端折らない。
- 抽象語で止めない（「クラウド」→ AWS / GCP / Vercel 等の具体まで／「BaaS」→ Firebase / Supabase 等の具体まで）。
- 3rd party の hard constraints は数値・料金プランの具体まで（「rate limit あり」では止めない、「100 req/min・無料プラン」まで明示）。

## 破壊的操作の禁止

- push / PR / merge / 課金 / 外部送信はしない。repo へのファイル書き込みと commit に留める（ADR-0004）。
- アンカー（`docs/indie-studio/discovery/anchors/`）は決め直さない（G1 で確定済み・読むだけ）。
- S1 corpus（`docs/indie-studio/discovery/planning/` / `design/`）は触らない（S1 担当の領域）。

## 前提・後段

- **前提**：`S1 service-discovery` 完了（`docs/indie-studio/discovery/anchors/` と `docs/indie-studio/discovery/planning/` 一式）。
- **後段**：`S1b design-direction`（DESIGN.md 組み上げ）。本スキル出力（`docs/indie-studio/tech/stack-direction/`）を `S1b` の `## Components` 記述で参照する。

## 関連 ADR

スキル追加判断＝ADR-0026。共通形＝ADR-0013。評価ループ＝ADR-0018。決定記録＝ADR-0019。ロスター＝ADR-0022（`tech-lead` は S1a / S3 の multi-context 職種）。命名規約＝ADR-0025。出力レイアウト＝ADR-0016（`docs/indie-studio/tech/` 配下）。

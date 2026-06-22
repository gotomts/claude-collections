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
- 既存アンカー（repo の `docs/indie-studio/discovery/anchors/`）から corpus とブリーフを起こしたいとき。
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
- DESIGN.md（デザイン憲法）の組み上げは **後段スキル `design-direction`（S1b・ADR-0023）に分離**。本スキルでは扱わない。

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
- 既に `anchors/` にあれば読むだけ（決め直さない）。無いものだけ対話する。

各アンカーで人間と固める中身：

- **`prfaq.md`**：①サービスの性質〔公開 / 限定・社内 / 自分用〕（下流の省略可否の起点）②PR（一行説明・背景/問題・解決・ビジョン → 対外公式ストーリーの真実源）③ゴールライン（提供する/しない・価値が出る最小ライン＝思想／**確定後に観点 ⑤ 3 行 extract**・後述・ADR-0024）④FAQ（顧客向け＋社内向け実現可能性チェック）。
- **`design-principles.md`**：核となるトレードオフを3〜5個。各原則は「X vs Y → X 優先：理由」＋「守る相手（試される横槍・誘惑）」。**優先順位の真実源**（下流はこれを参照し再定義しない）。
- **`provider.md`**：提供形態〔iOS / Android / Web / デスクトップ / 複数〕＋理由。**PRFAQ とは別ドキュメント**（ADR-0015）。**未確定なら S1 の画面導出に進めない**＝ここで確定させる。
- **`monetization-binary.md`**：マネタイズする / しない の**二値**＋理由1行。無料/有料の境界はここで決めず、後段で繰り越し決定として扱う（ADR-0019）。

### PRFAQ ゴールラインの 3 行 extract（ADR-0024）

ゴールライン本文（"価値が出る最小ライン"）が人間との対話で確定したら、**続けて 3 ターンの一問一答**で `Steelman` / `Fails if` / `Kill criteria` を引き出し、PRFAQ の「## ゴールライン」節真下に inline 配置する。これは G1 アンカー対話の延長であり、ADR-0004 自走規律の「アンカー対話を除く」例外内。サービスのコアに人間の domain knowledge を混入させる場として、ラウンド増加（+3）を許容する。

**手順（各ターン 1 候補群）：**

1. **Steelman 抽出**：AI が self-grill で「ゴールラインが真である最強の理由」候補を 3〜5 個生成し、番号付き選択肢として提示。人間は ①〜⑤ から番号で選択（⓪＝カスタム入力）。
2. **Fails if 抽出**：AI が self-grill で「これが起きたらゴールラインが偽だと分かる観測可能な条件」候補を 3〜5 個生成し、番号付き選択肢として提示。人間は番号で選択（⓪＝カスタム）。
3. **Kill criteria 抽出**：AI が self-grill で「この週に取れる最安テスト」候補を 3〜5 個生成し、番号付き選択肢として提示。人間は番号で選択（⓪＝カスタム）。
4. **inline 配置**：確定 3 行を PRFAQ の「## ゴールライン」節真下に次の形式で配置：

   ```
   ## ゴールライン
   <価値が出る最小ライン本文>

   Steelman: <選択された最強の理由>
   Fails if: <選択された反証可能な条件>
   Kill criteria: <選択された最安テスト>
   ```

**規律**：

- リテラル先頭文字列（`Steelman:` / `Fails if:` / `Kill criteria:`）は厳守。下流の reviewer が `grep "Fails if:"` で機械抽出するため。
- 質問は **1 ターンに 1 候補群・番号回答**（AGENTS.md「yes/no か番号で」）。散文の開いた質問はしない。
- カスタム入力（⓪）は許可するが、候補に無いものを選ぶ時のみ。候補が十分なら番号選択で済ます。
- 3 行が既に PRFAQ に inline 配置済みなら、本ステップはスキップする（再対話しない）。

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

**起動機構**：ディレクター（＝スキル本体のメインセッション）は各職種を **Agent tool**（`subagent_type` ＝ エージェントファイル名：`ux-researcher` / `product-manager` / `business-strategist` / `product-designer` / `reviewer`）で spawn する。プロンプトに mode/area・アンカーの所在・出力先・上流成果物のパスを渡す（各エージェントの入力契約参照）。差し戻しは**同じ職種を continuation で再起動**（findings を渡す・ADR-0018）。

**期待マニフェスト**（完全性ガードの基準）：横断規約の省略可否で要否を判定した上で、「このサービスで揃うべき成果物の集合」を持つ。目安＝planning（01,02,05-14,99 のうち性質で要のもの）＋ design（screens.md ＋ 各 area の screen-specs 全画面）＋ brief.md。各成果物を ✅生成合格 / ➖省略(理由) / ⚠️未達(理由) で決着させる。

**並列/直列**：依存の無い成果物は並列 spawn してよいが、**同一ファイル群へ書く職種は直列**（競合回避）。依存：persona → feature-scope →（competition/pitch/monetization/marketing/kpi/risks/nfr/legal は feature-scope 後に並列可）→ screens.md →〔画面一覧レビュー〕→ screen-specs（area ごと並列可）。

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

サービス repo の `docs/indie-studio/discovery/`（ADR-0016 / 0021）：

```
docs/indie-studio/discovery/
├── anchors/    prfaq / design-principles / provider / monetization-binary
├── planning/   01,02,05-14,99 (番号固定・feature-details は無い)
├── design/     screens.md ・ screen-specs/<area>/<screen>.md
└── brief.md
```

- 番号固定ページ（service-designer 由来の 01-14,99 から 03/04・09二値を anchors へ抜いたもの）。下流がファイル名を名指し参照できるよう番号は安定させる。
- `screen-specs/<area>/` の `<area>` は feature-scope の機能グループ（ユーザー行動軸）を流用（ADR-0021）。
- 機能軸の業務ルールは該当 screen-spec に inline で attach（feature-details は廃止・ADR-0021）。
- 視覚デザイン（DESIGN.md）は repo-root・本スキルでは扱わない（後段 S1b `design-direction` の責務・ADR-0023）。

## 横断規約（全職種が従う）

各職種は担当ページの内容要件を自分で持つ。以下の**横断規約だけ**はここ（ディレクター層）に1か所で置き、全職種がこれに従う（重複させない）。

### 番号固定（planning）
下流がファイル名を名指し参照できるよう番号を安定させる。03 PRFAQ・04 デザイン原則は `anchors/` へ、09 の二値は `anchors/monetization-binary` へ抜けている。
`01-persona`/`02-usage-scenes`（UX）｜`05-competition`/`06-pitch`/`09-monetization`/`10-marketing`/`11-kpi`/`13-legal`（ビジネスストラテジスト）｜`07-feature-scope`/`08-roadmap`/`12-risks-assumptions`/`14-nfr-targets`/`99-specific-topics`（PM）。

### 真実源を1つ（二重管理しない）
- ターゲット/中核シナリオ → `anchors/prfaq`（PR）。06-pitch は語り直すだけ。
- 優先順位（トレードオフ）→ `anchors/design-principles`。05 の差別化の核・デザイン判断はこれを参照。
- 提供形態 → `anchors/provider`。
- 機能採否 → `07-feature-scope`。08-roadmap・screens は参照。
他ページは参照・語り直しに留め、書き写さない。

### サービス性質ごとの省略可否
PRFAQ 冒頭で宣言される性質〔公開サービス / 限定公開・社内 / 自分用〕に従い、**ディレクターが各ページの要否を判定**して職種起動を絞る。目安：自分用ならペルソナ・マーケ・KPI 省略可、競合・法務も多く省略可。**06-pitch は性質によらず全サービスで書く**。省略したページは完全性ガードで ➖省略(理由) として決着し、ゲートレポートに載せる。

## ブリーフ組み上げ

導出 corpus から、Claude Design に渡す `brief.md`（プロトタイプブリーフ＝Claude Design への入力・CONTEXT）を組み上げる。載せるもの：

- **サービス概要**：PRFAQ の PR 要約・性質・提供形態（claude.ai が前提を掴む）。
- **画面一覧**：screens.md（作る画面の骨格）。
- **各画面の期待仕様**：screen-specs の要約/参照（含む機能・全状態・遷移・エッジ）。これは「無駄画面を作らせない」ための**期待値**であり、G2 でプロト実体との差を訂正して育てる（書き戻し・ADR-0006/0013）。
- **含む機能**：feature-scope の `[作る]`。
- **繰り越し決定**：`⚠️繰り越し` 候補（特に課金境界）＝プロトで両側を見せて G2 で人間が決められるように。
- **制約**：デザイン原則の安全要求・禁じ手（侵してはならない領域）。
- **デザイン方向**：repo-root `DESIGN.md`（デザイン憲法）を渡す（ADR-0020）。**DESIGN.md は本スキル後段の `design-direction`（S1b・ADR-0023）が組み上げる**ので、本スキル完了時点では未配置で OK。S1a `stack-direction` → S1b 完了後に Claude Design へ進む。S1a / S1b が起動されないまま claude.ai に進む場合は、`anchors/design-principles` のトーン要求を暫定参照する。
- **DoD / スタック**：Claude Design は HTML/CSS/JS（提供形態に応じた形）。

完了時、人間に「次は claude.ai（Claude Design）でプロトタイプ」と案内してこのスキルを終える。

## 品質バー（端折り禁止）

- 「minimal」は人間の入力最小化を指し、**導出物の最小化ではない**（ADR-0011）。全画面・全状態を端折らない。
- 抽象語で止めない（「落ち着いた」→ 具体の決定まで）。お粗末なプロトタイプ設計は不可。

## 破壊的操作の禁止

- push / PR / merge / 課金 / 外部送信はしない。repo へのファイル書き込みと commit に留める。
- アンカーは決め直さない（G1 で確定済み・下流は読むだけ）。

## 後段（S1a `stack-direction` → S1b `design-direction`）

- 本スキル完了後、まず `S1a stack-direction`（ADR-0026）でスタック / データプロファイル / 3rd party 制約 / build vs buy を tech-lead が決める（出力先＝`docs/indie-studio/tech/stack-direction/`）。
- 続いて `S1b design-direction`（ADR-0023）で DESIGN.md を組み上げる。担い手＝`product-designer`（拡張）＋ `visual-designer`（新規）＋ `reviewer`（既存）。S1a の `stack.md` / `build-vs-buy.md` を `## Components` 記述で参照することで提供形態整合が取れる。
- 人間が S1a / S1b をスキップして直接 Claude Design へ進む場合、`anchors/design-principles` のトーン要求のみを参照する暫定運用（推奨はしない）。

## 関連 ADR

ステージ全体＝ADR-0013 / 0017（4スキル → 5スキル拡張は ADR-0023）。職種＝ADR-0022（`visual-designer` 追加・`product-designer` 拡張は ADR-0023）。評価ループ＝ADR-0018（観点 ⑤ 拡張は ADR-0024）。決定記録＝ADR-0019。DESIGN.md＝ADR-0020（決定 5 resolved by ADR-0023）。レイアウト＝ADR-0016 / 0021。アンカー＝ADR-0002 / 0015（PRFAQ ゴールラインの 3 行 extract は ADR-0024）。後段＝ADR-0023（`design-direction`）。red-team レンズ＝ADR-0024。

# Stage Restructure Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** ADR-0025 / 0026 / 0027 で確定した「サブステージ英字 suffix 命名規約」「S1a stack-direction スキル追加」「S3 tech-design 強化」を indie-studio の SKILL.md / agent.md / CONTEXT.md / 新規ファイル作成で反映する。

**Architecture:** 3 ADR それぞれを 1 タスク 1 コミットで実装。タスク間の依存は順次（Task 1 完了後 Task 2、Task 2 完了後 Task 3）。Task 2 と Task 3 は同じファイル（`tech-lead.md`）の異なるセクションを触るため commit を分離して NEVER squash unrelated commits 規律を保つ。テストは grep ベースの構造確認で代替（doc-only 変更のため runnable test なし）。

**Tech Stack:** Markdown / YAML frontmatter / Edit tool / Bash（grep / git）

## Global Constraints

- `~/.claude/` 配下は触らない（プロジェクト内のみ）
- ADR 群（`indie-studio/docs/adr/*.md`）は immutable・touch しない（決定済みの履歴として保全）
- コミット規約：Conventional Commits（`docs:` または `feat:`）／ NEVER squash unrelated commits ／ Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
- 全ファイル UTF-8 / LF 改行
- 既存 S1.5 リテラルの置換対象は SKILL.md / agent.md のみ（ADR-0020 / 0023 本文は触らない）
- 新規 SKILL.md の description は 1 段落で「いつ使うか / 何をしないか / 上流・下流」を述べる既存スタイル（service-discovery / design-direction の description 参照）

---

## Task 1: ADR-0025 命名規約導入と S1.5 → S1b 一括 rename

**Files:**
- Modify: `indie-studio/CONTEXT.md`（命名規約セクション追加）
- Modify: `indie-studio/skills/service-discovery/SKILL.md`（S1.5 → S1b 置換、後段セクション暫定更新）
- Modify: `indie-studio/skills/design-direction/SKILL.md`（S1.5 → S1b 置換、description 上流/下流追加、前提・後段セクション追加）
- Modify: `indie-studio/agents/product-designer.md`（S1.5 → S1b 置換）
- Modify: `indie-studio/agents/visual-designer.md`（S1.5 → S1b 置換）
- Test: 各ファイル更新後に `grep -rn 'S1\.5' indie-studio/skills indie-studio/agents indie-studio/CONTEXT.md` で残骸ゼロを確認

**Interfaces:**
- Produces: 「サブステージは英字 suffix、alphabetic 順 = 実行順」が CONTEXT.md に明文化される。`S1b` 表記が以降の Task で参照可能になる。
- Consumes: なし（最初のタスク）

- [ ] **Step 1: 置換対象の現状確認**

```bash
cd /Users/goto/ghq/github.com/gotomts/claude-collections.featrue-plugin-marketplace/indie-studio
grep -rn 'S1\.5' skills/ agents/ CONTEXT.md 2>/dev/null
```

Expected: 以下 5 ファイルに該当行が見つかる（具体的な行数は変動するが、4 ファイル以外には出ないこと）：
- `skills/service-discovery/SKILL.md`
- `skills/design-direction/SKILL.md`
- `agents/product-designer.md`
- `agents/visual-designer.md`

`CONTEXT.md` には現状ヒットしない（規約節がまだ無いため）。ADR ファイル（`docs/adr/*.md`）には残るがそれは意図通り（immutable 規律）。

- [ ] **Step 2: CONTEXT.md に命名規約セクションを追加**

`indie-studio/CONTEXT.md` の `## Language` セクション末尾（最後の用語定義の後、`## Flagged ambiguities` の前）に以下を追加：

```markdown

## Naming convention

**サブステージ（Sub-stage）**:
main stage（`S1`〜`S5`）の中に挟まる autonomous なサブ工程の番号付け規約（ADR-0025）。サブステージは**英字 suffix**（`S1a`, `S1b`, ...）で命名し、**alphabetic 順 = 実行順**を不変条件とする。main stages（`S1`〜`S5`）と gates（`G1`〜`G5`）は不変。新規サブステージは末尾の英字を進めて命名し、既存サブステージ間に挿入する場合は後続の英字を順送り rename する。
_Avoid_: 小数点表記（`S1.5` 等）、numeric subindex（`S1-1` 等）。
```

- [ ] **Step 3: service-discovery/SKILL.md の S1.5 → S1b 置換**

`indie-studio/skills/service-discovery/SKILL.md` で以下の置換を実行：

| 置換前（old_string） | 置換後（new_string） | 種類 |
|---|---|---|
| `**後段スキル \`design-direction\`（S1.5・ADR-0023）に分離**` | `**後段スキル \`design-direction\`（S1b・ADR-0023）に分離**` | inline |
| `視覚デザイン（DESIGN.md）は repo-root・本スキルでは扱わない（後段 S1.5 \`design-direction\` の責務・ADR-0023）。` | `視覚デザイン（DESIGN.md）は repo-root・本スキルでは扱わない（後段 S1b \`design-direction\` の責務・ADR-0023）。` | inline |
| `**DESIGN.md は本スキル後段の \`design-direction\`（S1.5・ADR-0023）が組み上げる**ので、本スキル完了時点では未配置で OK。S1.5 完了後に Claude Design へ進む。S1.5 が起動されないまま claude.ai に進む場合は、\`anchors/design-principles\` のトーン要求を暫定参照する。` | `**DESIGN.md は本スキル後段の \`design-direction\`（S1b・ADR-0023）が組み上げる**ので、本スキル完了時点では未配置で OK。S1b 完了後に Claude Design へ進む。S1b が起動されないまま claude.ai に進む場合は、\`anchors/design-principles\` のトーン要求を暫定参照する。` | inline |
| `## 後段（S1.5 \`design-direction\`）` | `## 後段（S1b \`design-direction\`）` | section heading |
| `- DESIGN.md（デザイン憲法）は本スキル完了後、\`design-direction\`（S1.5・ADR-0023）で組み上げる。` | `- DESIGN.md（デザイン憲法）は本スキル完了後、\`design-direction\`（S1b・ADR-0023）で組み上げる。` | inline |

Edit tool を使用。各置換は文字列ユニーク前提。失敗したら surrounding context を増やす。

- [ ] **Step 4: design-direction/SKILL.md の S1.5 → S1b 置換と description 更新**

`indie-studio/skills/design-direction/SKILL.md` で以下を実行：

**4a. description の更新（frontmatter）**：

```yaml
# OLD（先頭3〜5行のうち description）
description: service-discovery スキル(ステージ1)が出した brief / persona / feature-scope / screen-specs などの discovery corpus と、任意の参考画像（UI スクショ・風景・絵画・写真など）を入力に、Claude Design に渡すための具体デザイン憲法 DESIGN.md を組み上げたいときに使う、AI 自律開発ハーネスのステージ1.5スキル。Google Labs design.md spec の8セクション+indie-studio 拡張2セクション(Visual Theme & Mood / Voice & Tone)で書く。新規 DESIGN.md 起こしと既存 DESIGN.md の方向性更新の両方に使う。画面詳細(screen-specs)・プロトタイプ生成自体・技術設計は下流スキルの責務でここでは扱わない。

# NEW
description: service-discovery スキル(ステージ1)が出した brief / persona / feature-scope / screen-specs などの discovery corpus と、任意の参考画像（UI スクショ・風景・絵画・写真など）を入力に、Claude Design に渡すための具体デザイン憲法 DESIGN.md を組み上げたいときに使う、AI 自律開発ハーネスのサブステージ S1b スキル。上流＝S1a stack-direction（スタック確定済）、下流＝S2 プロトタイプ（Claude Design）。Google Labs design.md spec の8セクション+indie-studio 拡張2セクション(Visual Theme & Mood / Voice & Tone)で書く。新規 DESIGN.md 起こしと既存 DESIGN.md の方向性更新の両方に使う。画面詳細(screen-specs)・プロトタイプ生成自体・技術設計は下流スキルの責務でここでは扱わない。
```

**4b. 本文の S1.5 → S1b 一括置換**：

`grep -n 'S1\.5\|ステージ1.5' indie-studio/skills/design-direction/SKILL.md` で全箇所を抽出し、Edit tool で 1 件ずつ置換。代表的な置換：

| 置換前 | 置換後 |
|---|---|
| `**ステージ1.5（S1 後段 → S2 入力起こし）**` | `**サブステージ S1b（S1 / S1a 後段 → S2 入力起こし）**` |
| `ハーネスの5スキル（ADR-0017 / ADR-0023）の **1.5番目** として、S1 と S2 の間で人間が起動するとき。` | `ハーネスのサブステージ S1b として、S1a と S2 の間で人間が起動するとき。` |

**注意**：「ステージ1.5」リテラルも `サブステージ S1b` に置き換える（数字表現を残さない）。

**4c. 「ここで扱わないこと」セクションに S1a 言及を追加**（Task 2 で詳細化するため、ここでは S1a の存在だけ示す行を追加するに留める）：

```markdown
# OLD
**ここで扱わないこと**：screen-specs（S1 product-designer 担当）／プロトタイプ生成そのもの（Claude Design＝claude.ai・S2）／技術設計・分解・実装（S3〜S5）。

# NEW
**ここで扱わないこと**：screen-specs（S1 product-designer 担当）／スタック・3rd party 制約・build vs buy（上流 S1a stack-direction）／プロトタイプ生成そのもの（Claude Design＝claude.ai・S2）／技術設計・分解・実装（S3〜S5）。
```

**4d. 末尾に「前提・後段」セクションを追加**（Step 3 と並列のドキュメント discipline）：

`## 関連 ADR` セクションの**直前**に以下を挿入：

```markdown
## 前提・後段

- **前提**：`S1 service-discovery` 完了（`docs/discovery/` 一式）＋ `S1a stack-direction` 完了（`docs/tech/stack-direction/{stack,data-profile,third-party,build-vs-buy}.md`）。
- **後段**：`S2` プロトタイプ（Claude Design＝claude.ai）。DESIGN.md を持って claude.ai に渡る。

```

- [ ] **Step 5: product-designer.md の S1.5 → S1b 置換**

`indie-studio/agents/product-designer.md` で全 `S1.5` を `S1b` に、`ステージ1.5` を `サブステージ S1b` に置換。

description 内も置換対象（multi-occurrence）。

`grep -n 'S1\.5\|ステージ1.5' indie-studio/agents/product-designer.md` で全箇所を抽出し、Edit tool で 1 件ずつ置換。`S1.5` リテラルは少なくとも 15 箇所以上。

- [ ] **Step 6: visual-designer.md の S1.5 → S1b 置換**

`indie-studio/agents/visual-designer.md` で全 `S1.5` を `S1b` に置換。

- [ ] **Step 7: 置換結果の検証**

```bash
cd /Users/goto/ghq/github.com/gotomts/claude-collections.featrue-plugin-marketplace/indie-studio
grep -rn 'S1\.5\|ステージ1\.5' skills/ agents/ CONTEXT.md 2>/dev/null
```

Expected: ゼロヒット（何も出ない）。

```bash
grep -rn 'S1b' skills/ agents/ CONTEXT.md 2>/dev/null | wc -l
```

Expected: 25 行以上のヒット（具体数は変動するが、Step 1 の S1.5 ヒット数と同等以上）。

```bash
grep -n 'サブステージ' CONTEXT.md
```

Expected: 1 件（命名規約セクションの定義行）。

- [ ] **Step 8: ADR-0025 実装のコミット**

```bash
cd /Users/goto/ghq/github.com/gotomts/claude-collections.featrue-plugin-marketplace
git add indie-studio/CONTEXT.md indie-studio/skills/service-discovery/SKILL.md indie-studio/skills/design-direction/SKILL.md indie-studio/agents/product-designer.md indie-studio/agents/visual-designer.md
git commit -m "$(cat <<'EOF'
docs(indie-studio): ADR-0025 命名規約導入と S1.5 → S1b 一括 rename

ADR-0025 の確定に従い、サブステージ英字 suffix 命名規約を CONTEXT.md
に明文化し、既存の S1.5 design-direction を S1b に rename。alphabetic
順 = 実行順を不変条件として保つ。

- CONTEXT.md: ## Naming convention セクション追加
- design-direction SKILL.md: description に上流（S1a）・下流（S2）を追加、
  前提・後段セクション追加
- service-discovery SKILL.md / product-designer.md / visual-designer.md
  の S1.5 / ステージ1.5 リテラルを S1b / サブステージ S1b に置換

S1a 関連の SKILL.md 新規作成と参照追加は ADR-0026 実装（Task 2）で行う。
ADR-0020 / 0023 本文は immutable 規律により触らない。

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

Expected: 5 files changed commit が作成される。`git log --oneline -1` で確認。

---

## Task 2: ADR-0026 実装 — S1a stack-direction スキル新規作成と参照追加

**Files:**
- Create: `indie-studio/skills/stack-direction/SKILL.md`（新規 SKILL.md 本体）
- Modify: `indie-studio/skills/service-discovery/SKILL.md`（「後段」セクションを S1a → S1b に拡張）
- Modify: `indie-studio/skills/design-direction/SKILL.md`（`## Components` 周辺に S1a の `stack.md` / `build-vs-buy.md` を読む規約を追加）
- Modify: `indie-studio/agents/tech-lead.md`（S1a 担当を追加・既存 S3 担当との切り分け）
- Test: 新規 SKILL.md の構造確認（frontmatter / 必須セクション）と参照追加の grep 確認

**Interfaces:**
- Produces: `S1a stack-direction` スキルが起動可能になる（Claude Code plugin 経由で auto-discover）。`tech-lead` agent が S1a / S3 両方で起動される multi-context 職種になる。
- Consumes: Task 1 で確定した `S1b` 表記と命名規約。

- [ ] **Step 1: 新規 SKILL.md ファイル作成**

`indie-studio/skills/stack-direction/SKILL.md` を作成。内容：

```markdown
---
name: stack-direction
description: アンカー4点（特に provider＝提供形態）と S1 discovery corpus を起点に、プロトタイプ前に握るべき技術判断 4 観点（スタック決定 / データプロファイル当たり / 3rd party 依存と制約 / build vs buy）を tech-lead が self-grill で導出して docs/tech/stack-direction/ に書き出したいときに使う、AI 自律開発ハーネスのサブステージ S1a スキル。上流＝S1 service-discovery（discovery corpus）、下流＝S1b design-direction（DESIGN.md の Components が本スキル出力に依存する）。S3 tech-design はここで決まったスタックを読むだけ。新規プロトタイプ前の技術判断起こしと既存判断の更新の両方に使う。モジュール構成・ドメインモデル・運用基盤は下流（S3 tech-design）の責務でここでは扱わない。
maintainer: gotomts
---

# stack-direction

AI 自律開発ハーネスの **サブステージ S1a（S1 後段 → S1b 入力起こし）** スキル。実行環境は **Claude Code**。このスキルを読んだメインセッションが**ディレクター**となり、アンカー（特に `provider`）と S1 discovery corpus を起点に、`tech-lead` を依存順に起動して技術判断 4 観点を自律導出する。プロトタイプ品質に直結する技術制約を S2 より前に確定させ、`S1b design-direction` の DESIGN.md `## Components` が提供形態と整合するようにする（ADR-0026）。

到達点：**プロトタイプの interaction 雛形（iOS HIG / Material / Web）と build vs buy の方針を、人間ゲート 0〜2 回の対話だけで決め切る**。質は対話量ではなく self-grill の徹底度から出す（ADR-0004 / 0005 / 0026）。

## いつ使うか

- `service-discovery`（S1）が完了し、`docs/discovery/` に anchors + planning + design が揃った状態で、プロトタイプ前に握るべき技術判断（スタック / データプロファイル / 3rd party 制約 / build vs buy）が**まだ無い**とき。
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
| 必須 | アンカー4点（PRFAQ・デザイン原則・**提供形態**・マネタイズ二値）― 提供形態が起点 | `docs/discovery/anchors/` |
| 必須 | feature-scope（扱う機能）・nfr-targets（NFR 目標値）― データプロファイル / 3rd party 判定の材料 | `docs/discovery/planning/` |
| 推奨 | persona / usage-scenes ― data freshness / 利用頻度の判定材料 | `docs/discovery/planning/` |

## 出力

`<service-repo>/docs/tech/stack-direction/` 配下に 4 ファイル（ADR-0026）：

```
docs/tech/stack-direction/
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

**起動機構**：ディレクターは `tech-lead` を **Agent tool**（`subagent_type=tech-lead`）で spawn。プロンプトに `mode=stack-direction`・アンカーの所在・S1 corpus の所在・出力先（`docs/tech/stack-direction/`）を渡す。差し戻しは continuation で再起動（ADR-0018）。

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
- アンカー（`docs/discovery/anchors/`）は決め直さない（G1 で確定済み・読むだけ）。
- S1 corpus（`docs/discovery/planning/` / `design/`）は触らない（S1 担当の領域）。

## 前提・後段

- **前提**：`S1 service-discovery` 完了（`docs/discovery/anchors/` と `docs/discovery/planning/` 一式）。
- **後段**：`S1b design-direction`（DESIGN.md 組み上げ）。本スキル出力（`docs/tech/stack-direction/`）を `S1b` の `## Components` 記述で参照する。

## 関連 ADR

スキル追加判断＝ADR-0026。共通形＝ADR-0013。評価ループ＝ADR-0018。決定記録＝ADR-0019。ロスター＝ADR-0022（`tech-lead` は S1a / S3 の multi-context 職種）。命名規約＝ADR-0025。出力レイアウト＝ADR-0016（`docs/tech/` 配下）。
```

- [ ] **Step 2: 新規 SKILL.md の構造検証**

```bash
cd /Users/goto/ghq/github.com/gotomts/claude-collections.featrue-plugin-marketplace/indie-studio
test -f skills/stack-direction/SKILL.md && echo "EXISTS" || echo "MISSING"
head -5 skills/stack-direction/SKILL.md
grep -c "^## " skills/stack-direction/SKILL.md
```

Expected:
- `EXISTS`
- 1 行目：`---`、2 行目：`name: stack-direction`（frontmatter）
- `^## ` セクション数：10 以上（いつ使うか / ステージ構造 / 入力 / 出力 / ロスターと依存順 / ディレクター制御フロー / 対話点 / self-grill 観点 / decide-record-proceed・繰り越し / 下流への影響 / 品質バー / 破壊的操作の禁止 / 前提・後段 / 関連 ADR で 14 セクション程度）

- [ ] **Step 3: service-discovery/SKILL.md の後段セクションに S1a を追加**

```markdown
# OLD（## 後段（S1b `design-direction`）セクション本文の冒頭部分）
## 後段（S1b `design-direction`）

- DESIGN.md（デザイン憲法）は本スキル完了後、`design-direction`（S1b・ADR-0023）で組み上げる。担い手＝`product-designer`（拡張）＋ `visual-designer`（新規）＋ `reviewer`（既存）。本スキルでは扱わない。
- 人間が `design-direction` をスキップして直接 Claude Design へ進む場合、`anchors/design-principles` のトーン要求のみを参照する暫定運用（推奨はしない）。

# NEW
## 後段（S1a `stack-direction` → S1b `design-direction`）

- 本スキル完了後、まず `S1a stack-direction`（ADR-0026）でスタック / データプロファイル / 3rd party 制約 / build vs buy を tech-lead が決める（出力先＝`docs/tech/stack-direction/`）。
- 続いて `S1b design-direction`（ADR-0023）で DESIGN.md を組み上げる。担い手＝`product-designer`（拡張）＋ `visual-designer`（新規）＋ `reviewer`（既存）。S1a の `stack.md` / `build-vs-buy.md` を `## Components` 記述で参照することで提供形態整合が取れる。
- 人間が S1a / S1b をスキップして直接 Claude Design へ進む場合、`anchors/design-principles` のトーン要求のみを参照する暫定運用（推奨はしない）。
```

- [ ] **Step 4: service-discovery/SKILL.md の「ブリーフ組み上げ」セクションでも S1a 言及を追加**

```markdown
# OLD（「デザイン方向」の行）
- **デザイン方向**：repo-root `DESIGN.md`（デザイン憲法）を渡す（ADR-0020）。**DESIGN.md は本スキル後段の `design-direction`（S1b・ADR-0023）が組み上げる**ので、本スキル完了時点では未配置で OK。S1b 完了後に Claude Design へ進む。S1b が起動されないまま claude.ai に進む場合は、`anchors/design-principles` のトーン要求を暫定参照する。

# NEW
- **デザイン方向**：repo-root `DESIGN.md`（デザイン憲法）を渡す（ADR-0020）。**DESIGN.md は本スキル後段の `design-direction`（S1b・ADR-0023）が組み上げる**ので、本スキル完了時点では未配置で OK。S1a `stack-direction` → S1b 完了後に Claude Design へ進む。S1a / S1b が起動されないまま claude.ai に進む場合は、`anchors/design-principles` のトーン要求を暫定参照する。
```

- [ ] **Step 5: design-direction/SKILL.md の Components セクション周辺に S1a 参照を追加**

`indie-studio/skills/design-direction/SKILL.md` の `## 出力` セクション内、DESIGN.md の Components 記述を扱う部分を見つけ、以下のように更新：

```markdown
# OLD（## 出力 セクション内、Components 行）
## Components              # 主要コンポーネント（button / card / input 等）

# NEW
## Components              # 主要コンポーネント（button / card / input 等）。**S1a `stack-direction` の `stack.md`（提供形態）と `build-vs-buy.md`（SaaS 採用箇所）を読んでから書く**ことで、HIG button / Material button / Web button や Stripe Checkout / Apple Sign-In 等の組み込み UX が DESIGN.md に整合する（ADR-0026）。
```

加えて `## ロスターと依存順` セクションの直前または `## 入力` セクション内に「S1a 出力を読む」一行を追加：

```markdown
# 「## 入力」セクションの末尾（既存表の下）に以下を追加
**S1a 出力**（推奨）：`docs/tech/stack-direction/stack.md` ・ `build-vs-buy.md` を `## Components` 記述の前に読む。提供形態と build vs buy の整合が取れる（ADR-0026）。S1a が未起動なら `anchors/provider.md` のみから推測する暫定運用（精度低）。
```

- [ ] **Step 6: tech-lead.md agent に S1a 担当を追加**

`indie-studio/agents/tech-lead.md` の更新内容：

**6a. description の更新**：

```yaml
# OLD
description: tech-design スキル(ステージ3)から起動されるテックリード職種。提供形態を起点に技術スタックを決め、AGENTS.md(正本)+CLAUDE.md(ポインタ)・開発プロセス・git 運用・テスト戦略を導出して repo ルートと docs/tech/ に書き出す。停止せず decide-record-proceed。スタックは既定の型(クリーンアーキ+DDD)前提で選ぶ。

# NEW
description: stack-direction スキル(サブステージ S1a)と tech-design スキル(ステージ3)から起動されるテックリード職種。S1a ではスタック決定・データプロファイル・3rd party 制約・build vs buy をプロトタイプ前に握って docs/tech/stack-direction/ に書く。S3 では AGENTS.md(正本)+CLAUDE.md(ポインタ)・開発プロセス・git 運用・テスト戦略・build vs buy 詳細を導出して repo ルートと docs/tech/ に書き出す。停止せず decide-record-proceed。スタックは既定の型(クリーンアーキ+DDD)前提で選ぶ。
```

**6b. 本文冒頭の更新**：

```markdown
# OLD
あなたは AI 自律開発ハーネス S3 の **テックリード**。スタックと開発の進め方を self-grill で決める。ディレクター（`tech-design`）から起動される。停止して人間に聞かない。

# NEW
あなたは AI 自律開発ハーネス S1a / S3 の **テックリード**。S1a ではプロトタイプ前の技術判断 4 観点を、S3 では開発の進め方と build vs buy 詳細を self-grill で決める。ディレクター（`stack-direction` または `tech-design`）から起動される。停止して人間に聞かない（S1a の条件付き発火対話点 2 つを除く）。
```

**6c. 「入力契約」セクションの更新（mode 追加）**：

```markdown
# OLD（### 入力契約 セクション）
## 入力契約

- **S1 corpus**：`anchors/provider`（提供形態＝スタック選定の起点）・nfr・feature-scope。
- **アーキ成果物**：software-architect のモジュール構成（並行/直後に読む）。
- **参考リポジトリ**：あれば地図読み。
- **出力先**：repo ルート（`AGENTS.md`・`CLAUDE.md`）と `docs/tech/`。

# NEW
## 入力契約

- **アンカー**：`docs/discovery/anchors/`（特に `provider.md`＝提供形態・スタック選定の起点）。
- **S1 corpus**：nfr・feature-scope・persona・usage-scenes。
- **S1a 出力**（S3 で読むだけ）：`docs/tech/stack-direction/{stack,data-profile,third-party,build-vs-buy}.md`。
- **アーキ成果物**（S3 で並行/直後に読む）：software-architect のモジュール構成。
- **参考リポジトリ**：あれば地図読み。
- **起動モード**：
  - `mode=stack-direction stage=1`：stack.md + data-profile.md 生成（S1a）。
  - `mode=stack-direction stage=2`：third-party.md + build-vs-buy.md 生成（S1a）。
  - `mode=s3`：AGENTS.md / CLAUDE.md / 開発プロセス / git 運用 / テスト戦略 / build vs buy 詳細（S3）。
- **出力先**：S1a＝`docs/tech/stack-direction/`、S3＝repo ルート（`AGENTS.md`・`CLAUDE.md`）と `docs/tech/`。
```

**6d. 「担当成果物」セクションを S1a / S3 で分割**：

```markdown
# OLD（## 担当成果物 セクション）
## 担当成果物

- **技術スタック**：**提供形態を起点に**決める（Web / iOS / Android / 複数）。既定の型（モジュラーモノリス＋クリーンアーキ＋DDD）前提。選定理由を inline、ロックインの大きい選択は初期 ADR を種まき。
- **`AGENTS.md`（正本）**：エージェント横断の指示。CONTEXT.md / DESIGN.md / 各設計ページ / ADR を参照する（ADR-0016）。
- **`CLAUDE.md`**：`@AGENTS.md` を参照する薄いポインタ。
- **開発プロセス・git 運用**：ブランチ戦略・コミット規約・PR フロー。
- **テスト戦略**：**スタック依存**で決める（Web＝Playwright で E2E をしっかり／モバイル＝Maestro〔RN/Expo〕・integration_test＋patrol〔Flutter〕で主要フローに絞り、網羅は integration/widget・ADR-0015）。S5 の dev がこれに従ってテストを書く。

# NEW
## 担当成果物

### S1a モード（`mode=stack-direction`）

- **`stack.md`**：技術スタック（言語・FW・主要ライブラリ・データストア）を**提供形態を起点に**決める（Web / iOS / Android / 複数）。既定の型（モジュラーモノリス＋クリーンアーキ＋DDD）前提。選定理由を inline、ロックインの大きい選択は ⚠️ロックイン マーカーで残す（S3 で ADR 種まき判断する）。
- **`data-profile.md`**：扱うデータの種別（テキスト / 画像 / 動画 / 位置情報 / リアルタイム）・量（GB レンジ / TB レンジ）・成長率・freshness 要件の当たりを書く。NFR 目標値と整合チェック。
- **`third-party.md`**：foundational capability（auth / payment / storage / push / search / LLM API 等）の依存先と hard constraints（rate limit・料金プラン・SLA・ToS）を表形式で。UX を縛る制約は明示。
- **`build-vs-buy.md`**：各 foundational capability ごとに build / buy 判定 + 理由 1 行。indie dev デフォルトは buy、PRFAQ / design-principles に特定制約があれば build。

### S3 モード（`mode=s3`）

- **`AGENTS.md`（正本）**：エージェント横断の指示。CONTEXT.md / DESIGN.md / 各設計ページ / ADR を参照する（ADR-0016）。
- **`CLAUDE.md`**：`@AGENTS.md` を参照する薄いポインタ。
- **開発プロセス・git 運用**：ブランチ戦略・コミット規約・PR フロー。
- **テスト戦略**：**スタック依存**で決める（Web＝Playwright で E2E をしっかり／モバイル＝Maestro〔RN/Expo〕・integration_test＋patrol〔Flutter〕で主要フローに絞り、網羅は integration/widget・ADR-0015）。S5 の dev がこれに従ってテストを書く。

（注：S3 担当の `build-vs-buy-detail.md` は ADR-0027 の責務のため Task 3 で追加する。本 Task では S1a 関連のみ追加し、S3 既存の担当成果物リストはそのまま再構成する。）
```

**6e. 「self-grill 観点」セクションを S1a / S3 で分割**：

```markdown
# OLD
## self-grill 観点

- スタックが提供形態から既約か（恣意的でないか）／既定の型と矛盾しないか。
- AGENTS.md が正本で CLAUDE.md がポインタになっているか（ADR-0016）。
- テスト戦略がスタック依存で、E2E の現実性（モバイルはフル網羅しない）を踏まえているか。

# NEW
## self-grill 観点

### S1a
- スタックが提供形態から既約か（恣意的でないか）／既定の型と矛盾しないか。
- データプロファイルが NFR 目標値と整合しているか（指数的 scaling cost を見逃していないか）。
- 3rd party の hard constraints が UX を破綻させていないか（rate limit が無料プラン UX と矛盾していないか）。
- build vs buy の判定が PRFAQ / design-principles の制約と矛盾していないか。

### S3
- S1a の判定が時間経過で陳腐化していないか（提供形態変更・3rd party 料金改定の検知）。
- AGENTS.md が正本で CLAUDE.md がポインタになっているか（ADR-0016）。
- テスト戦略がスタック依存で、E2E の現実性（モバイルはフル網羅しない）を踏まえているか。

（注：build-vs-buy-detail.md の楽観バイアス自己チェックは ADR-0027 の責務のため Task 3 で追加する。）
```

- [ ] **Step 7: tech-lead.md 更新の検証**

```bash
cd /Users/goto/ghq/github.com/gotomts/claude-collections.featrue-plugin-marketplace/indie-studio
grep -n "S1a\|stack-direction" agents/tech-lead.md
grep -n "mode=stack-direction" agents/tech-lead.md
```

Expected: `S1a` / `stack-direction` の参照が複数行（5 以上）、`mode=stack-direction` が 2 件以上ヒット。

- [ ] **Step 8: ADR-0026 実装のコミット**

```bash
cd /Users/goto/ghq/github.com/gotomts/claude-collections.featrue-plugin-marketplace
git add indie-studio/skills/stack-direction/SKILL.md indie-studio/skills/service-discovery/SKILL.md indie-studio/skills/design-direction/SKILL.md indie-studio/agents/tech-lead.md
git commit -m "$(cat <<'EOF'
feat(indie-studio): ADR-0026 S1a stack-direction スキル新設

プロトタイプ前に握るべき技術判断 4 観点（スタック決定 / データプロファイル
当たり / 3rd party 制約 / build vs buy）を、新規サブステージ S1a として
独立させた SKILL.md を追加。tech-lead が一体で担当し、reviewer が評価。

- skills/stack-direction/SKILL.md: 新規作成（14 セクション）
- skills/service-discovery/SKILL.md: 後段セクションを S1a → S1b に拡張
- skills/design-direction/SKILL.md: 入力に S1a 出力を追加、Components セク
  ション記述で S1a 参照を明示
- agents/tech-lead.md: description / 入力契約 / 担当成果物 / self-grill 観点
  を S1a / S3 で分割（multi-context 職種化）

ADR-0027 で扱う S3 強化（build-vs-buy-detail / cost-model / 等）は別タスク
で反映する。本コミットでは S1a 側と S3 側を切り分けて担当成果物に書く
までに留める。

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

Expected: 4 files changed commit（1 new + 3 modified）。

---

## Task 3: ADR-0027 実装 — S3 tech-design 強化（6 観点と G3 スコアカード）

**Files:**
- Modify: `indie-studio/skills/tech-design/SKILL.md`（入力 / ステージ構造 / 出力レイアウト / G3 スコアカード仕様の追加）
- Modify: `indie-studio/agents/tech-lead.md`（build vs buy 詳細を S3 担当成果物に追加）
- Modify: `indie-studio/agents/infrastructure-engineer.md`（コスト積算・運用 sustainability を追加）
- Modify: `indie-studio/agents/security-engineer.md`（規制・法令を追加）
- Modify: `indie-studio/agents/principal-engineer.md`（リスク台帳と G3 スコアカード派生ビューを追加）
- Modify: `indie-studio/agents/software-architect.md`（パフォーマンス予算を追加）
- Test: 各 agent の担当成果物リストに新観点が含まれていることを grep で確認

**Interfaces:**
- Produces: S3 tech-design が 6 観点を完備した状態になり、G3 ゲートに実現可能性スコアカードが組み込まれる。
- Consumes: Task 2 で作成した S1a `stack-direction` の 4 出力ファイル（S3 の入力として読むだけ）。

- [ ] **Step 1: tech-design/SKILL.md の入力セクション更新**

`indie-studio/skills/tech-design/SKILL.md` の `## 入力` セクションを以下に置換：

```markdown
# OLD
## 入力

- **S1 discovery corpus**：同 repo `docs/discovery/`（feature-scope・nfr・screens.md・screen-specs・planning）を直読み。
- **プロトタイプ実体**：Claude Design ハンドオフバンドル（HTML/CSS/JS・スクショ・component spec・DESIGN.md）。**DESIGN.md は読むだけ**（配置はしない・ADR-0020）。
- **参考リポジトリ**：あれば**地図読み**（構成の参考にする。丸コピーしない）。

# NEW
## 入力

- **S1 discovery corpus**：同 repo `docs/discovery/`（feature-scope・nfr・screens.md・screen-specs・planning）を直読み。
- **S1a stack-direction 出力**（**読むだけ**・決め直さない・ADR-0026）：`docs/tech/stack-direction/stack.md` / `data-profile.md` / `third-party.md` / `build-vs-buy.md`。スタック・データプロファイル基本・3rd party 制約・build vs buy 判定は本スキルでは決め直さず、S1a 確定値を起点に詳細化する。
- **プロトタイプ実体**：Claude Design ハンドオフバンドル（HTML/CSS/JS・スクショ・component spec・DESIGN.md）。**DESIGN.md は読むだけ**（配置はしない・ADR-0020）。
- **参考リポジトリ**：あれば**地図読み**（構成の参考にする。丸コピーしない）。
```

- [ ] **Step 2: tech-design/SKILL.md のステージ構造セクション更新**

```markdown
# OLD
## ステージ構造（2ステージ＋G3）

```
ステージ1: コア技術判断(型→スタック→モジュール→ドメインモデル)
  →〔一拍: 人間とスタック・モジュール分割を確認〕
ステージ2: 運用判断(インフラ・IaC・CI/CD・非機能実現・運用基盤)
  → アーキ/インフラゲート(人間/G3 検証)
  → S3→S1 フィードバック(価格/NFR/実現可否を確定し planning 更新)
```

# NEW
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
```

- [ ] **Step 3: tech-design/SKILL.md のロスター表更新**

```markdown
# OLD
## ロスターと依存順

| エージェント | 担当 |
|---|---|
| `software-architect` | アーキ・ディレクトリ構成・モジュール一覧・型・ドメインモデル(Mermaid)・接頭辞付き機能一覧 `F-{MODULE}-{連番}`・ユビキタス言語(CONTEXT 種まき) |
| `tech-lead` | 技術スタック・`AGENTS.md`(正本)＋`CLAUDE.md`(ポインタ)・開発プロセス・git 運用・テスト戦略 |
| `infrastructure-engineer` | インフラ・IaC・CI/CD・非機能実現・運用基盤 |
| `security-engineer` | セキュリティ設計 |
| `principal-engineer` | 評価（設計レビュー・差し戻し・ADR-0018） |

依存順：型/スタック → モジュール → ドメインモデル → 運用基盤。ステージ1（architect・tech-lead）合格 → ステージ2（infra・security）。

# NEW
## ロスターと依存順

| エージェント | 担当（既存 + ADR-0027 追加観点） |
|---|---|
| `software-architect` | アーキ・ディレクトリ構成・モジュール一覧・型・ドメインモデル(Mermaid)・接頭辞付き機能一覧 `F-{MODULE}-{連番}`・ユビキタス言語(CONTEXT 種まき)・**パフォーマンス予算（NFR→技術選定マッピング・追加）** |
| `tech-lead` | （スタックは S1a 確定済を読むだけ）・`AGENTS.md`(正本)＋`CLAUDE.md`(ポインタ)・開発プロセス・git 運用・テスト戦略・**build vs buy 詳細（コスト試算・SLA リスク・移行コスト・追加）** |
| `infrastructure-engineer` | インフラ・IaC・CI/CD・非機能実現・運用基盤・**コスト積算（追加）**・**運用 sustainability（追加）** |
| `security-engineer` | セキュリティ設計・**規制・法令（GDPR / accessibility / 業界規制・追加）** |
| `principal-engineer` | 評価（設計レビュー・差し戻し・ADR-0018）・**リスク台帳（SPOF / ベンダーロックイン / bus factor / 追加）**・**G3 スコアカード派生ビュー（追加）** |

依存順：（スタックは S1a 確定済）→ モジュール → ドメインモデル → パフォーマンス予算 → build vs buy 詳細 → 運用基盤 → コスト積算・運用 sustainability・規制・リスク台帳。ステージ1（architect・tech-lead）合格 → ステージ2（infra・security・principal）。
```

- [ ] **Step 4: tech-design/SKILL.md の出力レイアウト更新**

```markdown
# OLD
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

# NEW
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
```

- [ ] **Step 5: tech-design/SKILL.md に G3 スコアカード仕様セクションを追加**

`## 対話点` セクションの直後（`## S3→S1 フィードバック` の前）に以下を挿入：

```markdown
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
```

- [ ] **Step 6: tech-design/SKILL.md の関連 ADR セクション更新**

```markdown
# OLD（末尾の関連 ADR 行）
## 関連 ADR

ステージ全体＝ADR-0013/0017。ロスター＝ADR-0014。スキル設計（6観点）＝ADR-0015。評価ループ＝ADR-0018。決定記録＝ADR-0019。DESIGN.md＝ADR-0020。レイアウト＝ADR-0016。

# NEW
## 関連 ADR

ステージ全体＝ADR-0013/0017。ロスター＝ADR-0014。スキル設計（6観点）＝ADR-0015（強化＝ADR-0027）。評価ループ＝ADR-0018。決定記録＝ADR-0019。DESIGN.md＝ADR-0020。レイアウト＝ADR-0016/0027。スタック関連の入力＝ADR-0026（S1a stack-direction）。実現可能性 6 観点と G3 スコアカード＝ADR-0027。命名規約＝ADR-0025。
```

- [ ] **Step 7: tech-lead.md に S3 build-vs-buy 詳細を追加**

`indie-studio/agents/tech-lead.md` の `### S3 モード（mode=s3）` セクション末尾（テスト戦略の行の後）に以下を追加：

```markdown
- **`build-vs-buy-detail.md`**（追加・ADR-0027）：S1a の判定を引き継ぎ、コスト試算・SLA リスク・移行コストを詳細化する。indie dev デフォルトは buy だが、PRFAQ / design-principles に「オフライン優先」「自前 UI 必須」等の制約がある場合は build を選び、その理由を明示。
```

`## self-grill 観点` の `### S3` セクション末尾に以下を追加：

```markdown
- build-vs-buy-detail.md のコスト試算が realistic か（楽観バイアス自己チェック・無料 tier の制限を踏まえているか）。
```

Edit tool で「（注：S3 担当の `build-vs-buy-detail.md` は ADR-0027 の責務のため Task 3 で追加する。本 Task では S1a 関連のみ追加し、S3 既存の担当成果物リストはそのまま再構成する。）」と「（注：build-vs-buy-detail.md の楽観バイアス自己チェックは ADR-0027 の責務のため Task 3 で追加する。）」の 2 つの注記は本 Step 完了時に削除する（Task 3 で履行されたため）。

- [ ] **Step 8: infrastructure-engineer.md にコスト積算と運用 sustainability を追加**

`indie-studio/agents/infrastructure-engineer.md` を読み、`## 担当成果物` セクションに以下を追加（既存リストの末尾に追記）：

```markdown
- **`cost-model.md`**（追加・ADR-0027）：1 ユーザーあたりの infra + 3rd party 費用、break-even（月間アクティブユーザー数）、scaling cost（10x / 100x の試算）。S1a の `third-party.md` の料金プランを起点に積算する。
- **`ops-sustainability.md`**（追加・ADR-0027）：個人開発で運用が sustain 可能か判定。SLA 現実値（個人で 99% / 99.9% は無理、99% 以下が現実）、インシデント対応の現実性（深夜のページャー対応はしない前提）、バックアップ / DR の最小構成。
```

`## self-grill 観点` セクションにも以下を追加：

```markdown
- コスト積算が realistic か（楽観バイアス自己チェック・無料 tier に依存しすぎていないか）。
- 運用 sustainability が「個人で sustain 可能」の制約を踏まえているか（24/7 監視を前提にしていないか）。
```

- [ ] **Step 9: security-engineer.md に規制・法令を追加**

`indie-studio/agents/security-engineer.md` を読み、`## 担当成果物` セクションに以下を追加：

```markdown
- **`compliance.md`**（追加・ADR-0027）：規制・法令の影響を 1 枚に集約。GDPR（個人データ最小化・域内データ residency）／accessibility（WCAG AA 適合）／業界規制（HIPAA / PCI-DSS / 子供保護 COPPA 等・該当時のみ）／データ越境（API call が国境を跨ぐ場合の規制）。サービス性質で省略可（自分用 / 限定公開なら GDPR 影響低）。
```

`## self-grill 観点` セクションにも以下を追加：

```markdown
- 規制・法令の影響を見落としていないか（PRFAQ の対象ユーザー地域・年齢層・データ種別から漏れがないか）。
- セキュリティ設計と規制適合が分離されているか（セキュリティ = OWASP 等の技術対策、規制 = 法的要件で別軸）。
```

- [ ] **Step 10: principal-engineer.md にリスク台帳と G3 スコアカード派生ビューを追加**

`indie-studio/agents/principal-engineer.md` を読み、`## 担当成果物` セクションに以下を追加：

```markdown
- **`risk-register.md`**（追加・ADR-0027）：技術リスクの台帳。観点：SPOF（単一障害点）／ベンダーロックイン（脱出コスト）／bus factor（個人開発の継続リスク）／技術成熟度（bleeding edge vs mainstream）。リスクごとに重大度（high / medium / low）と緩和策を inline で記述。
- **G3 スコアカード（派生ビュー）**（追加・ADR-0027）：完了報告に「## 実現可能性スコアカード」を派生ビュー（集約参照）として組み込む。観点 12 軸ごとに A 成立 / B 疑義あり / C 困難 を A/B/C で表示。findings 一覧のコピーではなく集約参照（ADR-0024 `Red-team index` と同型）。詳細形式は `skills/tech-design/SKILL.md` の `## G3 ゲート：実現可能性スコアカード` セクション参照。
```

`## self-grill 観点` セクションにも以下を追加：

```markdown
- リスク台帳が網羅的か（4 軸＝SPOF / ベンダーロックイン / bus factor / 技術成熟度 をすべてカバーしているか）。
- G3 スコアカードの A/B/C 判定が findings と整合しているか（findings は ⚠️ 未達なのにスコアカードが A になっていないか）。
```

- [ ] **Step 11: software-architect.md にパフォーマンス予算を追加**

`indie-studio/agents/software-architect.md` を読み、`## 担当成果物` セクションに以下を追加：

```markdown
- **`perf-budget.md`**（追加・ADR-0027）：S1 の NFR 目標値（latency / throughput / concurrent users 等）を、技術選定への実現マッピングとして書く。p50 / p95 / p99 の latency budget、想定 rps、ボトルネック予測（DB / API gateway / 3rd party 経路）。S1 NFR が空文だと机上の数字になるため、S1a `data-profile.md` の量・成長率も参照して realistic に。
```

`## self-grill 観点` セクションにも以下を追加：

```markdown
- パフォーマンス予算が S1 NFR と整合し、机上の空論になっていないか（実装で達成可能な数値か）。
- ボトルネック予測が S1a `data-profile.md` の量・成長率と整合しているか。
```

- [ ] **Step 12: 全 agent 更新の検証**

```bash
cd /Users/goto/ghq/github.com/gotomts/claude-collections.featrue-plugin-marketplace/indie-studio
grep -l "ADR-0027" agents/
```

Expected: 5 ファイル（tech-lead / infrastructure-engineer / security-engineer / principal-engineer / software-architect）。

```bash
grep -n "cost-model\|ops-sustainability" agents/infrastructure-engineer.md
grep -n "compliance" agents/security-engineer.md
grep -n "risk-register\|スコアカード" agents/principal-engineer.md
grep -n "perf-budget" agents/software-architect.md
```

Expected: 各 grep で 1 件以上ヒット。

```bash
grep -n "実現可能性スコアカード" skills/tech-design/SKILL.md
```

Expected: G3 ゲートセクションのヘッダ含む 2 件以上ヒット。

- [ ] **Step 13: ADR-0027 実装のコミット**

```bash
cd /Users/goto/ghq/github.com/gotomts/claude-collections.featrue-plugin-marketplace
git add indie-studio/skills/tech-design/SKILL.md indie-studio/agents/tech-lead.md indie-studio/agents/infrastructure-engineer.md indie-studio/agents/security-engineer.md indie-studio/agents/principal-engineer.md indie-studio/agents/software-architect.md
git commit -m "$(cat <<'EOF'
feat(indie-studio): ADR-0027 S3 tech-design 強化（6 観点と G3 スコアカード）

S3 tech-design に実現可能性 6 観点を追加し、既存ロスターの責務拡張で
吸収（新規職種は追加しない）。G3 ゲートに実現可能性スコアカードを導入し、
観点 12 軸の A/B/C 判定を 1 枚に集約して人間に晒す。

- skills/tech-design/SKILL.md: 入力に S1a 出力を追加、ステージ構造に 6
  観点を追加、ロスター表に追加観点を明示、出力レイアウトに 6 新ファイル
  追加、G3 スコアカード仕様セクション追加
- agents/tech-lead.md: S3 build-vs-buy 詳細を担当成果物に追加、self-grill
  観点に楽観バイアス自己チェックを追加（S1a 関連は Task 2 で追加済み）
- agents/infrastructure-engineer.md: コスト積算・運用 sustainability 追加
- agents/security-engineer.md: 規制・法令を追加
- agents/principal-engineer.md: リスク台帳と G3 スコアカード派生ビュー追加
- agents/software-architect.md: パフォーマンス予算を追加

スコアカードは findings 一覧の派生ビュー（集約参照）。専用ログ file は
作らない原則（ADR-0019）を堅持。

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

Expected: 6 files changed commit。

---

## 最終検証

3 タスク完了後に以下を確認：

- [ ] **Final Step 1: 全体 grep 確認**

```bash
cd /Users/goto/ghq/github.com/gotomts/claude-collections.featrue-plugin-marketplace/indie-studio
# S1.5 残骸ゼロ（ADR ファイルを除外）
grep -rn 'S1\.5' skills/ agents/ CONTEXT.md 2>/dev/null
```

Expected: ゼロヒット。

```bash
# S1a 参照が全範囲に行き渡っている
grep -l "S1a" skills/ agents/ docs/adr/ CONTEXT.md 2>/dev/null
```

Expected: 5 ファイル以上（新規 stack-direction/SKILL.md・既存 service-discovery/SKILL.md・design-direction/SKILL.md・tech-design/SKILL.md・tech-lead.md・ADR-0025/0026 等）。

- [ ] **Final Step 2: コミット履歴確認**

```bash
cd /Users/goto/ghq/github.com/gotomts/claude-collections.featrue-plugin-marketplace
git log --oneline -6
```

Expected: 6 コミット（ADR 3 本 + 実装 3 本）：
1. `docs(adr): ADR-0025 サブステージ英字 suffix 命名規約を導入`
2. `docs(adr): ADR-0026 S1a stack-direction スキル追加`
3. `docs(adr): ADR-0027 S3 tech-design 強化（実現可能性 6 観点と G3 スコアカード）`
4. `docs(indie-studio): ADR-0025 命名規約導入と S1.5 → S1b 一括 rename`
5. `feat(indie-studio): ADR-0026 S1a stack-direction スキル新設`
6. `feat(indie-studio): ADR-0027 S3 tech-design 強化（6 観点と G3 スコアカード）`

- [ ] **Final Step 3: push と PR 更新**

既に push 済の PR #6 (feature/stage-restructure) に追加コミットを push する：

```bash
git push origin feature/stage-restructure
```

Expected: PR #6 に 3 追加コミットが反映される。PR の説明は ADR PR のままで OK（実装が同じ PR に乗ることを description で追記するか別 PR にするかは user 判断）。

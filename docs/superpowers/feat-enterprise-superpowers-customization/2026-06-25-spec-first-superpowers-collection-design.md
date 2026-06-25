---
title: spec-first-superpowers コレクション新設 — 設計
date: 2026-06-25
branch: feat/enterprise-superpowers-customization
status: draft (brainstorming 段階、user 承認待ち)
---

# spec-first-superpowers コレクション新設 — 設計

## 概要

`claude-collections` リポジトリに、superpowers (公式) を base に拡張したコレクション **`spec-first-superpowers`** を新設する。`~/.claude/CLAUDE.local.md` に蓄積されてきた「コミット前提に直したローカル開発フローカスタマイズ」(5 成果物 / Spec 先行 / GWT テスト運用 / code-review 採用Skip / 指摘対応規律 / 設計思想 / コードコメント方針) を skill+agent コレクションとしてパッケージ化し、PC 以外の環境 (他 PC / 業務 repo) でも install して同じフローで開発できるようにする。

## 背景・動機

`~/.claude/CLAUDE.local.md` で運用してきた superpowers カスタマイズは PC ローカル設定として閉じており、他環境に持ち出せない。コミット前提の repo (業務 / 他 PC) でも同じフローを使いたいが、ローカルファイル参照 (`~/.claude/local-templates/` 等) や PC 固有規約 (worktree → main working tree 退避) が混ざっているため、そのまま持ち出すと壊れる。

本 ADR では、ローカル運用ルールのうち「コミット前提で他環境に持ち出せる部分」だけを抽出してコレクション化する。

### 採用するルール (コレクションが内包)

- 5 成果物 (design / plan / summary / gwt / pr-description) の作成と命名
- pr-description.md の Spec フェーズ先行作成
- 受け入れ条件 (GWT) のテスト運用 (agent-browser 優先、dev server を AI が起動・停止)
- code-review (CodeRabbit) 採用/Skip 2 値判定
- 指摘対応時の規律 (実装修正 → テストコード同期確認 → 不要時も 1 行根拠)
- 設計思想 (Clean Architecture + Modular Monolith、YAGNI/DRY/KISS/SOLID、SOLID 最優先、テスト DRY 一部許容)
- コードコメント方針 (WHY のみ、JSDoc 抑制)
- 4 種テンプレート (summary / gwt / pr-description / review-response)
- **セキュリティレビュー** (設計レベル: enhance-brainstorming Phase 3/4 で security-engineer を常時能動 dispatch / コードレベル: STOP POINT 2 で code-review skill 実行に加えて security-engineer による security-focused なコードレビューを 1 回実施)

### 除外するルール (本コレクションは持たない)

- PR 作成の流れ (gh pr create --web 目視 / CodeRabbit 自動サマリー前提 / Conventional Commits 厳守) → finish-stage-pr 共有 helper と棲み分け
- superpowers ドキュメント ID コメント禁止ルール → ID 焼き込みのトレードオフは個別判断

## スコープ

- **In**: spec-first-superpowers コレクションの新設、shared/skills/finish-stage-pr の後方互換改修、root の marketplace.json 登録、CONTEXT-MAP.md 索引追加、**セキュリティレビュー** (Spec フェーズの設計レベル + 実装後 STOP POINT 2 のコードレベル)
- **Out**: エンプラ特有要素 (監査ログ / コンプライアンス / 変更管理 / 承認フロー) は本コレクションには含めない。必要なら別コレクション / 別 ADR で後続検討
- **Out**: 既存 indie-studio コレクションへの変更 (finish-stage-pr 改修は後方互換、indie-studio 挙動は据え置き)

## アーキテクチャ

```
claude-collections/
├── spec-first-superpowers/                     ← 新規
│   ├── CONTEXT.md                              # ユビキタス言語 + scope + 設計思想
│   ├── docs/adr/                               # コレクション固有 ADR (0001-0006 初期セット)
│   ├── skills/                                 # 4 skill (enhance-brainstorming + 3 sub-skill)
│   ├── agents/                                 # make sync で生成 (手編集禁止)
│   ├── templates/                              # summary / gwt / pr-description / review-response
│   └── .claude-plugin/
│       ├── plugin.json                         # plugin manifest
│       └── dependencies.json                   # shared/ pick 宣言
├── shared/                                     # 既存、agents touch なし、skills は finish-stage-pr のみ改修
├── indie-studio/                               # 既存、touch なし
└── .claude-plugin/
    └── marketplace.json                        # spec-first-superpowers entry を追加
```

### 外部依存

- 上位の **superpowers plugin (公式 mattpocock/skills)** が install 済み前提 (`enhance-brainstorming` 内で `superpowers:brainstorming` / `superpowers:writing-plans` を invoke)
- `shared/agents/` → `make sync COLLECTION=spec-first-superpowers` で `agents/` に generated file として展開
- `shared/skills/finish-stage-pr` → 後方互換改修した上で取り込み (body-source-path 引数追加)

### 設計思想 (CONTEXT.md に明記)

- superpowers の brainstorming → writing-plans → executing-plans の **直線フローを尊重して上書きしない** (hard-gate / user approval gate も尊重)
- その上に「5 成果物の Spec フェーズ確定 (summary-first 順序)」「GWT による検証可能性」「採用/Skip の 2 値判定によるレビュー収束」「Clean Architecture + Modular Monolith + SOLID 最優先」を被せる
- agent vendoring (`shared/`) を再利用して職種境界を保つ (spec-first-superpowers 固有 agent は持たない、初期)

### indie-studio との棲み分け

| 観点 | indie-studio | spec-first-superpowers |
|---|---|---|
| 思想 | 5 ステージ × 5 ゲート × 自律導出 × 多職種 director モデル | superpowers 直線フロー × 5 成果物 × 採用Skip 規律 |
| ターゲット | 個人開発 (人間介入を anchor + gate に局所化) | 中規模開発 (Spec フェーズで認識齟齬を潰す) |
| 共通 | 同じ repo に同居、`shared/` を共有 | 同左 |
| 語彙の禁止 | (なし、自分の語彙体系) | indie-studio の `S1〜S5` / ゲート / 繰り越し決定 / アンカー / 大枠ゲート / Claude Design の語彙は使わない (CONTEXT.md に明示) |

CONTEXT-MAP.md に並列で索引する。

## コンポーネント

### 4 skills

| skill | 役割 | invoke 経路 |
|---|---|---|
| **`enhance-brainstorming`** | 起点。superpowers:brainstorming + writing-plans を内部 invoke、5 成果物を Spec フェーズで確定、後工程 sub-skill 連鎖を駆動 | **ユーザーが呼ぶ唯一の skill** |
| `gwt-test` | AC 検証 + チェックリスト更新 + dev server 起動/停止 | enhance-brainstorming からの連鎖 or user 直接 |
| `write-review-response` | 採用/Skip 2 値判定 + review-response.md 上書き | gwt-test からの連鎖 or user 直接 |
| `finish-spec-pr` | pr-description.md を body として finish-stage-pr に渡して PR 作成 | write-review-response からの連鎖 or user 直接 |

#### enhance-brainstorming 詳細

- **invoke trigger**: 機能開発開始時にユーザーが `spec-first-superpowers:enhance-brainstorming` を呼ぶ
- **動作**:
  1. ブランチ確認 → `docs/superpowers/{branch}/` 準備 (commit 前提、worktree 退避なし)
  2. Phase 1: 会話で問題理解 → 2-3 アプローチ提示 → **`software-architect` を dispatch してアプローチ案の Clean Architecture + SOLID 整合性レビュー**
  3. Phase 2: templates/summary.md から summary.md を生成 → **`software-architect` を dispatch して「方式の要点」「効いている設計判断」を SOLID/YAGNI 観点でレビュー** → user 承認 + commit (認識齟齬 検出ポイント①)
  4. Phase 3: 合意済み summary を context として `superpowers:brainstorming` に委譲 → design.md → **`software-architect` を dispatch して design 全体の SOLID / モジュール境界レビュー** → **続けて `security-engineer` を常時能動 dispatch して design のセキュリティレビュー (認証 / 認可 / データ取扱 / 外部入力 / シークレット / 通信 / コード実行 等の観点)** → user 承認 + commit
  5. Phase 4: `superpowers:writing-plans` invoke → plan.md → **`qa-engineer` を dispatch して plan のテスト戦略の段取り妥当性レビュー** → **続けて `security-engineer` を常時能動 dispatch して plan のセキュリティ観点 (セキュリティテスト / 脅威モデリングの段取り / 機微データ取扱の手順) レビュー** → user 承認 + commit
  6. Phase 5: templates/gwt.md から gwt.md を生成 → **`qa-engineer` を dispatch して AC の網羅性 (異常系 / 境界値 / 空状態) レビュー** → user 承認 + commit (認識齟齬 検出ポイント②)
  7. Phase 6: templates/pr-description.md から pr-description.md を生成 → user 承認 + commit (認識齟齬 検出ポイント③)
  8. **Phase 1 / 2 / 5 / 6 でもセキュリティ箇所が検出されたら**: `security-engineer` を任意 dispatch (Phase 3/4 の常時 dispatch とは別)
  9. STOP POINT 1 (実装フェーズ) を user に明示して終了。**実装中の推奨 agent 利用パターンを案内** (実装 AI / user が任意で `software-architect` / `code-reviewer` / `security-engineer` を dispatch)
- **規律明示 (SKILL.md に記載)**:
  - 5 成果物の命名 `{YYYY-MM-DD}-{slug}-{suffix}.md`
  - 設計思想 (Clean Architecture + Modular Monolith / YAGNI/DRY/KISS/SOLID / SOLID 最優先 / テスト DRY 一部許容)
  - コードコメント方針 (WHY のみ、JSDoc 抑制)
  - pr-description Spec フェーズ先行作成の意義
  - 各 Phase で agent を **能動 dispatch** する (silent failure 回避、取り込むだけで使わない pattern を作らない)

#### gwt-test 詳細

- **invoke trigger**: 実装完了後、ユーザーが `gwt-test` を呼ぶ or enhance-brainstorming からの再開連鎖
- **動作**:
  1. プロジェクトルートの README を Read (テストアカウント / 起動コマンド把握)
  2. dev server / docker を AI が起動 (`lsof -i :<port>` / `docker ps` で重複確認 → 重複あれば 1 問確認)
  3. agent-browser で各 AC 検証 (フォールバックで chrome-devtools-mcp、未導入なら install 是非を 1 問確認)
  4. AC 達成 → `gwt.md` チェックリストを `- [x]` に更新
  5. AC 未達 → **`qa-engineer` を dispatch して差し戻し findings の言語化 + テストコード同期確認** → `gwt.md` 変更履歴に逆時系列追記 → 実装差し戻し提案
  6. dev server / docker を必ず停止 (`lsof` / `docker ps` で残存確認)
  7. STOP POINT 2 (code-review skill 手動実行) を user に明示する際、**「`code-review` (CodeRabbit) の実行に加えて `security-engineer` を能動 dispatch して security-focused なコードレビューを 1 回実施する」** ことを案内に必ず含める (実装後の機械的レビュー = CodeRabbit、人格を持つ専門家レビュー = security-engineer、の両輪で実装フェーズのセキュリティを担保)
- **規律明示**:
  - agent-browser → chrome-devtools-mcp → 相談 の優先順序
  - 実装修正 → テストコード同期確認 (不要時も 1 行根拠)
  - AC 未達発覚時は qa-engineer 能動 dispatch (自己判断で済まさず職種境界に通す)
  - STOP POINT 2 案内に security-engineer によるコードセキュリティレビューを必ず含める

#### write-review-response 詳細

- **invoke trigger**: code-review skill 実行後、ユーザーが `write-review-response` を呼ぶ or gwt-test からの再開連鎖
- **動作**:
  1. templates/review-response.md を読み込み
  2. CodeRabbit 指摘 (ローカル + PR 上 unresolved) を 採用/Skip の 2 値判定 (保留禁止、全件判定必須)
     - 判定迷い時は **`code-reviewer` を dispatch して採用/Skip 補助** (特に false positive 疑い時)
     - セキュリティ系指摘は **`security-engineer` を dispatch して採用判定にセキュリティ観点を追加**
  3. ID を CodeRabbit 分類に揃える (`M1...` / `Mi1...` / `T1...`)
  4. **上書き運用** で `{date}-{slug}-review-response.md` を保存 (最新ラウンドのみ保持)
  5. 採用分を実装に反映 (← user 作業 or AI 作業) → **再 push 前に `code-reviewer` を dispatch して修正コードの差し戻しレビュー**
- **規律明示**:
  - CodeRabbit へのリプライは送らない (修正 push → 自動 resolve → 残 unresolved のみ判定)
  - 採用/Skip 2 値 (保留禁止)
  - 採用後の実装修正でテストコード同期不要時は 1 行根拠を残す
  - 判定迷い・セキュリティ系・採用後修正の 3 タイミングで agent を能動 dispatch (silent failure 回避)

#### finish-spec-pr 詳細

- **invoke trigger**: レビュー対応完了後、ユーザーが `finish-spec-pr` を呼ぶ or write-review-response からの再開連鎖
- **動作**:
  1. `docs/superpowers/{branch}/*-pr-description.md` を Read
  2. `## やったこと` を実装結果に整える、`## 補足` 内容なければ削除
  3. commit 差分一覧を確認 (`git log origin/main..HEAD --oneline`)
  4. PR title を user に 1 問確認 (Conventional Commits 形式または既存 repo 規約)
  5. `shared/skills/finish-stage-pr` を **`body-source-path={pr-description.md path}` 指定で**呼ぶ
  6. finish-stage-pr の Step 8 (PR 作成最終確認) でユーザー最終確認 → push + gh pr create

### 取り込み agent (4 体)

`spec-first-superpowers/.claude-plugin/dependencies.json`:

```json
{
  "shared": {
    "agents": [
      "code-reviewer",
      "qa-engineer",
      "software-architect",
      "security-engineer"
    ],
    "skills": [
      "finish-stage-pr"
    ]
  }
}
```

| agent | 使用 skill / フェーズ (能動 dispatch、詳細は後述「Agent dispatch matrix」) |
|---|---|
| `software-architect` | enhance-brainstorming Phase 1-3 (アプローチ案 / summary / design レビュー)、実装フェーズの任意 dispatch |
| `qa-engineer` | enhance-brainstorming Phase 4 (plan のテスト戦略) + Phase 5 (gwt の AC 網羅性) + gwt-test の AC 未達発覚時 |
| `code-reviewer` | write-review-response の判定迷い時 / 採用後修正の再 push 前 + 実装フェーズの任意 dispatch |
| `security-engineer` | enhance-brainstorming 全 Phase 横断 (セキュリティ箇所検出時) + write-review-response のセキュリティ系指摘 + 実装フェーズの任意 dispatch |

実装系 (backend / frontend / mobile / infrastructure / performance) は **初期は外す**、必要時に dependencies.json に追加して再 sync。reviewer / tech-lead / engineering-manager / principal-engineer は indie-studio 専用色が強く initial では取り込まない。

### 取り込み shared/skills (1 件)

- `finish-stage-pr` (後方互換改修。詳細は ADR-0004 / 「shared/skills/finish-stage-pr 改修」セクション)
- `start-stage-branch` は取り込まない (branch+worktree 自動化前提、ユーザー既存 `wt-start` 系と被る)

### templates (4 種、コレクション内に同梱)

`spec-first-superpowers/templates/`:

- `summary.md` — TL;DR (一言で / 方式の要点 / フロー図 / 効いている設計判断 / スコープ外 / 確認事項)
- `gwt.md` — Given-When-Then (AC-1, AC-2, AC-E1 + 検証チェックリスト + 変更履歴)
- `pr-description.md` — frontmatter なし、`## やったこと` / `## 補足` / `## 動作確認方法` の 3 セクション
- `review-response.md` — 採用 / Skip / 連動関係 (frontmatter + CodeRabbit ID 規則)

ローカル `~/.claude/local-templates/` の現テンプレを起点にコピー。CodeRabbit 前提の文言は残す (運用上 CodeRabbit を中核に据えているため、汎用化はしない)。テンプレは PC 以外でも使う前提なのでコレクション同梱。

### Agent dispatch matrix

各 skill の各ステップで **能動 dispatch** する agent を明示。「import するだけで使わない」silent failure pattern を回避するため、ドキュメントレビューと実装後コードレビューに専門家観点を入れる。

| skill / ステップ | 専門家 agent | dispatch 種別 | 目的 |
|---|---|---|---|
| enhance-brainstorming Phase 1 (アプローチ提示) | `software-architect` | 能動 | アプローチ案の Clean Architecture + SOLID 整合性レビュー |
| enhance-brainstorming Phase 2 (summary 生成後) | `software-architect` | 能動 | 「方式の要点」「効いている設計判断」を SOLID/YAGNI 観点でレビュー |
| enhance-brainstorming Phase 3 (design 生成後) | `software-architect` + **`security-engineer`** | 能動 (両方) | software-architect: SOLID / モジュール境界レビュー / **security-engineer: design のセキュリティレビュー (認証 / 認可 / データ取扱 / 外部入力 / シークレット / 通信 / コード実行 等)** |
| enhance-brainstorming Phase 4 (plan 生成後) | `qa-engineer` + **`security-engineer`** | 能動 (両方) | qa-engineer: テスト戦略の段取り妥当性 / **security-engineer: plan のセキュリティテスト / 脅威モデリングの段取り / 機微データ取扱の手順** |
| enhance-brainstorming Phase 5 (gwt 生成後) | `qa-engineer` | 能動 | AC の網羅性 (異常系 / 境界値 / 空状態) レビュー |
| enhance-brainstorming Phase 6 (pr-description 生成後) | (なし) | — | 動作確認方法は user が責任を持つ |
| enhance-brainstorming Phase 1 / 2 / 5 / 6 (セキュリティ箇所検出時) | `security-engineer` | 任意 | Phase 3/4 の常時 dispatch とは別、検出時のみ追加 dispatch |
| **STOP POINT 1 (実装フェーズ)** | (user / 実装 AI が任意で dispatch) | 案内 | enhance-brainstorming が **推奨 agent 利用パターンを案内** (`software-architect` / `code-reviewer` / `security-engineer`)。本コレクションは実装 skill を持たないので、`superpowers:executing-plans` / 人間実装 / その他実装 skill のいずれを使う場合でも、ここで案内したパターンを参照する |
| gwt-test (AC 達成時) | (なし) | — | チェックリスト更新のみ |
| gwt-test (AC 未達発覚時) | `qa-engineer` | 能動 | 差し戻し findings の言語化、テストコード同期確認 |
| **STOP POINT 2 (code-review skill 手動実行)** | **`security-engineer`** + (CodeRabbit) | **案内 + 能動 dispatch** | gwt-test の終端で「code-review (CodeRabbit) の実行に加えて security-engineer を能動 dispatch して security-focused なコードレビューを 1 回実施」を案内。機械的レビュー (CodeRabbit) と人格を持つ専門家レビュー (security-engineer) の両輪で実装フェーズのセキュリティを担保 |
| write-review-response (判定迷い時) | `code-reviewer` | 能動 | 採用/Skip 判定の補助 (特に false positive 疑い時) |
| write-review-response (セキュリティ系指摘) | `security-engineer` | 能動 | 採用判定にセキュリティ観点を追加 |
| write-review-response (採用後の修正、再 push 前) | `code-reviewer` | 能動 | 修正コードの差し戻しレビュー |
| finish-spec-pr (PR 作成全工程) | (なし) | — | mechanical な操作のみ |

統一原則: **「agent を取り込んだら、必ず使う場面を skill ステップに織り込む」**。任意 dispatch 表現は (a) STOP POINT のような skill 制御外、または (b) 検出条件付きの追加 dispatch (Phase 3/4 以外の Phase でのセキュリティ箇所検出時等) でのみ許容。

## データフロー

```
ユーザーが意識的に呼ぶのは spec-first-superpowers:enhance-brainstorming 1 つ

enhance-brainstorming
  ├─ Phase 1: 会話で問題理解 → 2-3 アプローチ提示
  ├─ Phase 2: templates/summary.md から summary.md 生成 → user 承認 + commit  [認識齟齬 検出 ①]
  ├─ Phase 3: 合意済み summary を context として superpowers:brainstorming へ → design.md → user 承認 + commit
  ├─ Phase 4: superpowers:writing-plans invoke → plan.md → user 承認 + commit
  ├─ Phase 5: templates/gwt.md から gwt.md 生成 → user 承認 + commit  [認識齟齬 検出 ②]
  ├─ Phase 6: templates/pr-description.md から pr-description.md 生成 → user 承認 + commit  [認識齟齬 検出 ③]
  │
  ├─ 🛑 STOP POINT 1: 実装フェーズ (人間 or AI が実装)
  │
  └─ user 完了報告 → 再 invoke or gwt-test 直接 invoke
       gwt-test
         ├─ README 確認 → dev server 起動 (重複確認) → agent-browser で AC 検証
         ├─ AC 全達成? No → gwt.md 変更履歴追記 → 実装差し戻し (loop)
         ├─ AC 全達成? Yes → gwt.md チェックリスト更新 → dev server 停止
         │
         ├─ 🛑 STOP POINT 2: セルフレビュー (ユーザーが code-review skill を実行)
         │
         └─ user 完了報告 → 再 invoke or write-review-response 直接 invoke
              write-review-response
                ├─ template から生成 → 採用/Skip 2 値判定 → 上書き保存
                ├─ 採用分を実装に反映 + テストコード同期確認
                │
                └─ finish-spec-pr
                     ├─ pr-description.md Read + title 1 問確認 + body-source-path 指定
                     └─ shared/skills/finish-stage-pr (改修済)
                          └─ Step 8 user 最終確認 → push + gh pr create → PR open
```

### 5 成果物の生成順と相互参照 (summary-first 順序)

| 順 | 成果物 | 出所 | 参照 (frontmatter リンク) |
|---|---|---|---|
| 1 | `{date}-{slug}-summary.md` | enhance-brainstorming (templates) | design (Phase 2 時点で slug は確定済みなので frontmatter は `design: ./{date}-{slug}-design.md` を先行記載、実ファイルは Phase 3 で同じ slug で生成される) |
| 2 | `{date}-{slug}-design.md` | superpowers:brainstorming (合意済み summary を context として渡す) | summary |
| 3 | `{date}-{slug}-plan.md` | superpowers:writing-plans | design |
| 4 | `{date}-{slug}-gwt.md` | enhance-brainstorming (templates) | design, summary |
| 5 | `{date}-{slug}-pr-description.md` | enhance-brainstorming (templates) | (frontmatter なし、3 セクションのみ) |
| (後) | `{date}-{slug}-review-response.md` | write-review-response (templates) | design, summary, gwt |

配置先: `docs/superpowers/{branch}/` (commit 前提、worktree 退避なし)

### 連鎖と stop point の根拠

- **STOP POINT 1 (実装)** — 実装は人間 or AI の判断で時間を要する。enhance-brainstorming が「実装してね、終わったら再 invoke or gwt-test を呼んでね」で停止
- **STOP POINT 2 (セルフレビュー)** — `code-review` skill (CodeRabbit) は user が手動 invoke、結果確認に時間を要する。gwt-test が「code-review を実行してね、終わったら再 invoke or write-review-response を呼んでね」で停止
- それ以外は連鎖。superpowers:brainstorming → user 承認 → superpowers:writing-plans → user 承認 → templates 生成は 1 セッションで連続実行

## エラーハンドリング

統一原則: **「失敗時は中断 + 状況提示 + 再 invoke 案内」**。silent failure / フォールバック禁止。

| 失敗ケース | 担当 skill | 挙動 |
|---|---|---|
| Phase 1 (会話・アプローチ提示) で情報不足 | enhance-brainstorming | 1 問ずつ追加質問 → 情報が揃ったら Phase 2 へ |
| Phase 2 (summary 合意) で大枠ズレが発覚 | enhance-brainstorming | Phase 1 に戻って再議論 → summary 書き直して再合意 |
| Phase 3: superpowers:brainstorming が summary context を無視して会話を再開 | enhance-brainstorming | 「合意済みです」を再伝達 → なお会話続行なら受け入れる (確認会話ならコスト小)。**dogfood で運用上の問題があれば Z 方式 (自前実装) に移行 — ADR-0006 で trial 結果を踏まえて update する想定** |
| brainstorming で user が design 承認しない | superpowers:brainstorming | brainstorming 内の revise → 提示ループ |
| writing-plans で plan が design と矛盾 | superpowers:writing-plans | writing-plans 内のループ |
| 5 成果物の整合性チェックで矛盾発覚 | enhance-brainstorming | 矛盾点 user 提示 → 修正対象 1 問確認 → 修正 → 再提示 |
| dev server 起動失敗 (port 占有) | gwt-test | `lsof -i :<port>` 提示 → 既存停止 or 別 port 1 問確認 |
| dev server 起動失敗 (README 不在 / 起動コマンド不明) | gwt-test | error + 中断、「手動起動してから再 invoke」 |
| AC 未達 | gwt-test | `gwt.md` 変更履歴に逆時系列追記 → 実装差し戻し提案 → 1 問確認 |
| agent-browser が対象機能を非対応 | gwt-test | chrome-devtools-mcp 使用是非を 1 問確認 → 未導入なら install 是非も 1 問確認 |
| 採用/Skip 判定で迷う指摘 | write-review-response | user に提示 → 判定 1 問確認 (保留禁止、必ず 2 値) |
| 採用後の修正でテストコード同期不要 | write-review-response | 「不要根拠 1 行」を user に要請 → review-response.md に記録 |
| pr-description.md 未生成 | finish-spec-pr | error + 中断、「Spec フェーズで pr-description.md 作成してから再 invoke」 |
| push / gh pr create 失敗 | finish-spec-pr → finish-stage-pr | finish-stage-pr の error handling に委譲 (`gh auth status` 案内等) |
| 異常終了で dev server / docker 停止漏れ | gwt-test | cleanup ロジックで停止試行、失敗時は PID + コマンドを user に通知 |
| skill が前提を満たさない (git 外 / docs 不在) | 各 skill | Step 1 で前提チェック → 失敗時 error + 中断 |

## テスト戦略

### コレクション自体の検証

| 検証対象 | 手段 | タイミング |
|---|---|---|
| shared/ の sync drift | `make verify` (既存) | CI + ローカル commit 前 |
| skill frontmatter / description の妥当性 | 手動 PR review | PR 作成時 |
| skill が前提条件をチェックできるか | 各 skill の Step 1 で前提検証 + 明示 error | skill 実行時 (毎回) |
| skill 連鎖の正常動作 (連鎖 invoke / stop point) | 実機 dogfood | 開発時 + 新 skill 追加時 |
| superpowers:brainstorming への summary context 委譲 | 実機 dogfood (Y 方式が成立するか、context を受けて design を直接書き出すか) | enhance-brainstorming 初回実装時 |
| templates のプレースホルダー網羅 | テンプレ内コメント (`{slug}` `{機能名}` 等のリスト) | テンプレ追加時 |
| ADR (コレクション固有) との整合 | 手動 PR review | ADR 追加 / skill 変更時 |
| indie-studio との語彙分離 | CONTEXT.md に明示禁止語彙 (S1〜S5 / ゲート / 繰り越し決定 / アンカー) | コレクション設計時 |
| finish-stage-pr 改修の後方互換 | indie-studio で実機 dogfood (改修後 PR 作成) | shared/skills 改修 PR レビュー時 |

## ADR 初期セット

`spec-first-superpowers/docs/adr/`:

| ADR | タイトル |
|---|---|
| 0001 | collection-scope-and-naming (= brainstorming 拡張 + 5 成果物 + 後工程連鎖、命名: spec-first-superpowers) |
| 0002 | five-deliverables-and-order (5 成果物の出所、summary-first 順序、templates 同梱) |
| 0003 | skill-chain-and-stop-points (skill 連鎖と 2 stop point の設計判断) |
| 0004 | shared-skills-finish-stage-pr-extension (body-source-path 引数追加の後方互換改修) |
| 0005 | agent-vendoring (4 agent 取り込みの選定理由) |
| 0006 | superpowers-brainstorming-context-delegation (Y 方式 = summary context を渡して design 委譲、Z fallback への移行条件) |

## shared/skills/finish-stage-pr 改修

### before (現状)

`finish-stage-pr` は Step 7 で body を内蔵テンプレで生成。テンプレは indie-studio 専用色 (`## ゲートレポート ✅<件数>` / `繰り越し論点` / `## 関連 stage: s1`) が強い。

### after (改修)

Step 7 を分岐:
- 呼び出し側から `body-source-path` が prose で渡されている場合: そのファイルを Read で読み込み、内容を body として使う
- 渡されていない場合 (既存挙動): 現状の内蔵テンプレで構築

argument-hint も拡張:
```
<title-suggestion> [body-source-path]
```

### 後方互換

- indie-studio は `body-source-path` を指定せず呼ぶので、Step 7 default 分岐 (内蔵テンプレ) が動作
- spec-first-superpowers の `finish-spec-pr` は `body-source-path={pr-description.md path}` を指定して呼ぶので、新分岐 (file 内容 = body) が動作

indie-studio の挙動互換は、改修後に indie-studio で 1 回 PR 作成して dogfood 検証する。

## 影響範囲

| 変更先 | 内容 | 影響度 |
|---|---|---|
| `spec-first-superpowers/` 配下 (新規) | コレクション一式 (CONTEXT.md / docs/adr / skills / templates / .claude-plugin) | 新規追加のみ |
| `spec-first-superpowers/agents/` | `make sync` で生成 (手編集禁止) | sync コマンドで生成 |
| `shared/skills/finish-stage-pr/SKILL.md` | Step 7 + argument-hint の改修 (後方互換) | 改修済み helper として両コレクションで再利用 |
| `indie-studio/` 配下 | 影響なし (body-source-path 未指定で default 動作) | 影響なし |
| root `.claude-plugin/marketplace.json` | spec-first-superpowers entry を追加 | 配布対象に追加 |
| root `CONTEXT-MAP.md` | spec-first-superpowers を索引に追加 | 索引追加のみ |
| root `docs/adr/` | finish-stage-pr 改修について root ADR を追加するかは要判断 (ADR-0005 を inline 補足で済む可能性) | inline で済む見込み |

## リスク / open questions

### リスク

1. **Y 方式 (summary context 委譲) が成立しない可能性** — superpowers:brainstorming が context を受けても会話を再開してしまう場合、enhance-brainstorming が初回実装時の dogfood で確認する。問題があれば ADR-0006 を update して Z 方式に移行
2. **finish-stage-pr 改修で indie-studio の挙動互換が壊れる可能性** — 改修後 indie-studio で 1 回 PR 作成して dogfood 検証
3. **agent 取り込みが少なすぎて実装フェーズで足りなくなる可能性** — initial で 4 agent、足りなければ dependencies.json に追加して再 sync (ADR-0005 で増減基準を明示する余地)
4. **CodeRabbit 前提の文言が PC 以外の環境で機能しない可能性** — 業務 repo で CodeRabbit を使ってない場合、write-review-response の挙動が宙に浮く。今回は CodeRabbit 必須前提で固定するが、将来汎用化の余地は残す

### open questions (writing-plans 段階で詰める)

- sub-skill (gwt-test / write-review-response / finish-spec-pr) の命名は確定でいいか (現状 placeholder)
- spec-first-superpowers/skills/ 内のディレクトリ構造 (SKILL.md 直下 / sub-files 配下)
- CONTEXT.md / ROADMAP.md の初期内容 (indie-studio の構造を参考に揃えるか、より簡潔にするか)
- ADR-0001 〜 0006 の本文の最終仕上げ (本 design doc を基に各 ADR に分解)
- root ADR-0005 (shared/skills/ vendoring) を update するか、新規 root ADR を発行するか
- marketplace.json への entry 追加時の category (`development-workflow` で indie-studio と揃える?)

## 完了の定義

- [ ] `spec-first-superpowers/` ディレクトリ作成 + CONTEXT.md / .claude-plugin / templates / 4 skill 配置
- [ ] `dependencies.json` 宣言 → `make sync COLLECTION=spec-first-superpowers` で agents/ + skills/finish-stage-pr 取り込み完了
- [ ] `shared/skills/finish-stage-pr` 後方互換改修 + indie-studio dogfood で挙動互換確認
- [ ] root `.claude-plugin/marketplace.json` に entry 追加
- [ ] root `CONTEXT-MAP.md` に索引追加
- [ ] ADR 0001 〜 0006 を起こす
- [ ] enhance-brainstorming の Y 方式 dogfood で superpowers:brainstorming の挙動確認
- [ ] `make verify` が CI でも通る

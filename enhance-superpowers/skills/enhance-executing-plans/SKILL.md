---
name: enhance-executing-plans
description: |
  enhance-superpowers コレクションの実装フェーズ skill (ADR-0012 で新設)。
  STOP POINT 1 (実装フェーズ) を skill 化し、実装前後で agent 能動 dispatch を強制。
  実装本体は superpowers:executing-plans を invoke (Y 方式、ADR-0006 と同型)。
  実装前 = software-architect (実装方針 review)、slice ごと = code-reviewer (コード review)、
  セキュリティ箇所 = security-engineer 常時 dispatch。dispatch log は plan.md のレビュー履歴に集約 (ADR-0007)。
  Step 0 で状態判定 (ADR-0012 D2)、Step 1 で .ai-restrictions.md を Read して AI 利用ポリシー案内 (ADR-0010)。
  完了後は gwt-test skill を chain invoke。
argument-hint: "[plan-file-path]  # plan.md のパス (省略時は docs/superpowers/{branch}/ から自動検出)"
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - Skill
maintainer: gotomts
---

# enhance-executing-plans

enhance-superpowers コレクションの実装フェーズ skill (ADR-0012 で新設)。ユーザーは通常 enhance-brainstorming の skill chain 経由で自動 invoke されるが、単独 invoke も可能。

## Phase 定義 (ADR-0012 D3)

| Phase | 前提 file | 出力 | 出力条件 |
|---|---|---|---|
| 0 | `docs/superpowers/{branch}/*-plan.md` 存在 | (判定) | 状態判定完了、Step 番号を確定 |
| 1 | plan.md | 実装前 review 記録 | software-architect dispatch 完了、plan.md レビュー履歴に追記 |
| 2 | plan.md | 実装コード | superpowers:executing-plans 経由で slice 実装 |
| 3 | 実装スライスごと | slice review 記録 | code-reviewer (+ 該当 slice で security-engineer) dispatch 完了、plan.md レビュー履歴に追記 |
| 4 | 実装済み全 slice | gwt-test skill chain 起動 | 全 slice review 完了 |

## 動作 (6 ステップ)

### Step 0: 状態判定 (ADR-0012 D2)

1. `git rev-parse --abbrev-ref HEAD` で現ブランチ取得、サニタイズ (`/` → `-`)
2. `docs/superpowers/{branch}/` の既存 file を Glob で列挙、`summary/design/gwt/pr-description/plan` の存在有無を確認
3. **前提**: `*-plan.md` が存在すること。無ければ error "plan.md がありません。enhance-brainstorming Phase 4 を完了させてください" + 中断
4. plan.md 末尾の「## レビュー履歴」を Read し、以下を判定:
   - 「実装前 software-architect dispatch」ログ有無 → 無ければ Step 1 から / あれば Step 3 (slice 単位 executor dispatch + review) から
   - 「gwt-test chain 完了」final marker 有 → 呼び出し元に返る (再 chain 不要)
   - 「gwt-test chain 起動 attempt」marker のみ有 (完了 marker なし) → user に「gwt-test を再 chain invoke しますか? (下流で失敗した可能性)」1 問確認 → yes なら Step 5 (再実行、marker は idempotent なので重複追記しない)、no なら終了
5. `handoff.md` が同ディレクトリにあれば Read して state summary を取得、上記判定と突き合わせ (handoff 情報が優先されるとは限らない、あくまで補助)
6. 判定結果を user に「現在 Phase = X、Step Y から再開します」と明示、user 1 問確認 (誤検出時の catch)

### Step 1: 前提確認 + AI 利用ポリシー案内 (ADR-0010)

1. `git rev-parse --show-toplevel` で git repo を確認、失敗なら error 中断
2. プロジェクトルートの `.ai-restrictions.md` を Read (存在すれば内容を user に案内、無ければ skip)
3. argument 経由 or `docs/superpowers/{branch}/*-plan.md` から plan.md を確定

### Step 2: 実装前 software-architect 能動 dispatch (ADR-0012 D1)

1. `software-architect` を能動 dispatch — plan.md の実装方針が Clean Architecture / SOLID / モジュール境界と整合しているかを pre-flight review
2. dispatch log を plan.md 末尾「## レビュー履歴」セクションに追記 (ADR-0007)
3. software-architect が方針修正を提案した場合、user に 1 問確認 → 承認されたら plan.md を Edit で更新 → commit

### Step 3: slice 単位で対象 executor agent を能動 dispatch (ADR-0012 D1、redesign 2026-07-04)

plan.md 内の各 slice について、以下を順次実行:

1. slice の対象領域を判定 (backend / frontend / mobile / infrastructure / mixed):
   - plan.md の slice 定義に metadata (対象領域) が明示されているならそれを採用
   - 明示無ければ、slice に含まれる file / モジュール / 技術要素 から自動推定
   - 判定が曖昧なら user に 1 問確認 ("この slice は backend / frontend / mobile / infrastructure / mixed どれ?")
2. 対象 executor agent を能動 dispatch (`Agent` tool):
   - backend slice → `backend-engineer`
   - frontend slice → `frontend-engineer`
   - mobile slice → `mobile-engineer`
   - infrastructure slice → `infrastructure-engineer`
   - mixed (backend + frontend 等の垂直スライス) → 該当 executor 複数を順次 dispatch (依存順、例: backend → frontend)
3. dispatch prompt に以下 context を含める (executor は中立語彙で書かれているので、context は skill 側から明示提供、ADR-0004 root):
   - **タスク定義**: 受入条件・スコープ範囲・該当 slice の詳細
   - **参照 docs**: design.md / plan.md / gwt.md / ユビキタス言語 の path
   - **担当範囲**: 該当 slice の対象部分のみ
   - **architecture 規約**: design.md / plan.md で指定される規約 (例: Clean Architecture + DDD 等)
   - **テスト戦略**: plan.md 指定、または design.md セクション参照
   - **進行 protocol**: 停止可否 / 仮定の記録方法 / 未決事項マーカー
4. executor が担当実装 (該当担当範囲、テスト含む)
5. dispatch log を plan.md 末尾「## レビュー履歴」セクションに追記 (ADR-0007)
6. slice 実装完了 → Step 4 (review) へ

**superpowers:executing-plans との関係**: 本 skill は superpowers:executing-plans に「丸投げ」しない (silent failure 回避)。enhance-superpowers 側で executor 能動 dispatch を保証。superpowers 直線フロー (brainstorming → writing-plans → executing-plans) の 3 段目相当を、enhance-superpowers 側で silent failure なく実装する形。

### Step 4: slice ごとの code-reviewer + security-engineer 能動 dispatch (ADR-0012 D1)

各 slice の実装完了時に以下を実行:

1. `code-reviewer` を能動 dispatch (`Agent` tool) — 実装コードの review (機能実装 / 命名 / SOLID 準拠 / テスト有無等)。呼び出し元 skill の指定として「差し戻し protocol を使用 (round1/2/3、最大 3 ラウンド)」を prompt で宣言
2. 実装対象 slice に auth / crypto / データ取扱 / 外部入力等の変更があれば、`security-engineer` を **常時能動 dispatch** (評価 mode、security-focused な実装 review)
3. 大規模 UI / 大量データ処理等で性能影響が想定される slice なら、`performance-engineer` を能動 dispatch (評価 mode)
4. dispatch log を plan.md 末尾「## レビュー履歴」セクションに追記 (ADR-0007)
5. review 指摘がある場合、user に 1 問確認 → 該当 executor に修正 dispatch (再実装) → 再度 review dispatch → 収束
6. slice 収束 → 次 slice へ (Step 3 に戻る)

### Step 5: 全 slice 完了判定 + gwt-test skill chain (M2 fix 2026-07-04: attempt-then-confirm marker + idempotent + user gate)

1. plan.md の全 slice が実装 + review 済であることを確認
2. **user に「実装フェーズ完了、gwt-test chain invoke に進みますか?」1 問確認** (user 承認 gate、marker を先に書かない)
3. yes → 続行 / no → 「後で `gwt-test` を直接 invoke してください」と案内して skill 終了 (attempt marker も書き込まない、再 invoke 時に Step 5 から素直に再開)
4. plan.md 末尾レビュー履歴に **「{timestamp} - gwt-test chain 起動 attempt」attempt marker** を追記 (idempotent: 既存の attempt marker があれば skip、多重追記を防止)
5. `Skill` tool で `gwt-test` skill を chain invoke
6. chain invoke **成功時のみ** plan.md 末尾レビュー履歴に **「{timestamp} - gwt-test chain 完了」final marker** を追記 (Step 0 の再開判定に使う hint)。失敗時は attempt marker のみ残る = 次回再 invoke で Step 0 が「attempt-only 状態」を検知して user 1 問確認 → 再 Step 5 実行の分岐に入る

## 規律明示

- 実装前後の agent 能動 dispatch を必ず実行 (silent failure 回避、ADR-0001 コンセプト、ADR-0012)
- dispatch log は plan.md の「## レビュー履歴」セクションに集約 (ADR-0007)
- 実装本体は superpowers:executing-plans に委譲 (自前の実装 loop は作らない、ADR-0006 の Y 方式と同型)
- Step 0 状態判定で再開可能な skill 設計 (ADR-0012 D2)、SKILL.md 冒頭の Phase 定義 table を再開判定の仕様源 (ADR-0012 D3) とする
- Step 1 で `.ai-restrictions.md` を Read して AI 利用ポリシーを案内 (ADR-0010、ファイル無ければスキップ)

## 失敗時の挙動

| 状況 | 挙動 |
|---|---|
| plan.md 未生成 | error 報告 + 中断 ("enhance-brainstorming Phase 4 を完了させてください") |
| Step 0 で判定結果が不明瞭 | user に「summary/design/gwt/plan の状態が想定と異なります、どこから再開しますか?」と 1 問確認 |
| software-architect が実装方針の重大 issue を検出 | plan.md 修正が必要 → user 承認 → plan.md Edit → 再 dispatch |
| superpowers:executing-plans が slice 境界で停止しない | 「slice 単位で停止するよう」を追加 prompt して retry。なお回避不可なら全 slice 完了後にまとめて code-reviewer / security-engineer dispatch (fallback) |
| code-reviewer / security-engineer が blocker 検出 | 実装修正 → 再 review dispatch。修正できなければ user に相談 |

## 関連

- ADR-0001 (collection-scope-and-naming): コンセプト = silent failure 回避
- ADR-0003 (skill-chain-and-stop-points — Superseded by ADR-0012): 本 skill で STOP POINT 1 を置き換え
- ADR-0005 (agent-vendoring): dispatch 対象 agent
- ADR-0006 (superpowers-brainstorming-context-delegation, Y 方式): 本 skill でも同型 (executing-plans 委譲)
- ADR-0007 (audit-trail-dispatch-log): dispatch log 集約先 = plan.md
- ADR-0010 (ai-utilization-policy-loading): Step 1 で Read
- ADR-0012 (implementation-phase-skill-and-state-detection): 本 skill を規定する ADR
- enhance-brainstorming SKILL.md: 前工程 skill、実装フェーズ chain 起動元
- gwt-test SKILL.md: 後工程 skill、Step 5 で chain invoke
- `superpowers:executing-plans` skill: Step 3 で invoke (実装本体を委譲)

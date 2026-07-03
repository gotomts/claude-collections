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
   - 「実装前 software-architect dispatch」ログ有無 → 無ければ Step 1 から / あれば Step 3 (slice 実装完了ごとの review) から
   - 「全 slice review 完了」記述有無 → あれば Step 5 (gwt-test chain) から
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

### Step 3: `superpowers:executing-plans` を invoke (Y 方式、ADR-0006 同型)

1. `Skill` tool で `superpowers:executing-plans` を invoke、context に plan.md path を渡す
2. superpowers:executing-plans が slice 単位でコード実装を進める
3. superpowers:executing-plans に「実装完了ごとに一度停止して」と伝達し、slice 境界で本 skill に制御を戻せるようにする (fallback は Step 4 参照)

### Step 4: slice ごとの code-reviewer + security-engineer 能動 dispatch (ADR-0012 D1)

各 slice の実装完了時に以下を実行:

1. `code-reviewer` を能動 dispatch — 実装コードの review (機能実装 / 命名 / SOLID 準拠 / テスト有無等)
2. 実装対象 slice に auth / crypto / データ取扱 / 外部入力等の変更があれば、`security-engineer` を **常時能動 dispatch** (security-focused な実装 review)
3. dispatch log を plan.md 末尾「## レビュー履歴」セクションに追記 (ADR-0007)
4. review 指摘がある場合、user に 1 問確認 → 実装修正 → 再度 review dispatch → 収束
5. slice 収束 → 次 slice へ (Step 3 に戻る)

### Step 5: 全 slice 完了判定 + gwt-test skill chain (ADR-0003 の skill chain 継続 = ADR-0012 で維持)

1. plan.md の全 slice が実装 + review 済であることを確認
2. plan.md 末尾レビュー履歴に「全 slice review 完了」を追記 (再開時の状態判定 hint)
3. user に「実装フェーズが完了しました。次はテストフェーズです」と明示
4. `Skill` tool で `gwt-test` skill を chain invoke

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

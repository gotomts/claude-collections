---
name: write-review-response
description: |
  code-review skill (CodeRabbit) の指摘と、GitHub PR 上の CodeRabbit インラインコメントのうち
  unresolved 分を採用/Skip の 2 値で判定し、review-response.md に上書き運用で記録する skill。
  ID は CodeRabbit 分類に揃える (M1.../Mi1.../T1...)。CodeRabbit へのリプライは送らない
  (修正 push → 自動 resolve、残った unresolved のみ判定)。
  判定迷い時 / セキュリティ系指摘 / 採用後修正の 3 タイミングで code-reviewer /
  security-engineer を能動 dispatch、dispatch log は review-response.md のレビュー履歴に追記。
  Step 1 で .ai-restrictions.md を Read (ADR-0010)。
argument-hint: "[review-source]  # ローカル code-review の出力 or PR URL"
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

# write-review-response

code-review (CodeRabbit) 指摘への対応方針を md ファイルとして記録する skill。gwt-test からの連鎖、または user が直接 invoke のどちらでも動作。

## Phase 定義 (ADR-0012 D3)

| Phase | 前提 file | 出力 | 出力条件 |
|---|---|---|---|
| 0 | gwt.md checklist 全 `- [x]` + code-review skill 出力 or PR unresolved comments | (判定) | 状態判定完了、Step 番号を確定 |
| 判定 | CodeRabbit 指摘一覧 (ローカル + PR unresolved) | `{date}-{slug}-review-response.md` | 全指摘を採用/Skip 判定完了 (保留禁止) |
| 反映 | review-response.md 採用分 | 修正コード + 再 push | code-reviewer 差し戻し review OK + user 承認 |

## 動作 (6 ステップ)

### Step 0: 状態判定 (ADR-0012 D2)

1. `git rev-parse --abbrev-ref HEAD` で現ブランチ取得、サニタイズ (`/` → `-`)
2. `docs/superpowers/{branch}/` を Glob で列挙、`*-gwt.md` / `*-review-response.md` の存在有無を確認
3. **前提**: gwt.md checklist が全 `- [x]` であること (gwt-test の Step 6 まで完了)。未達なら error "gwt-test を完了させてください" + 中断
4. review-response.md 状態を判定:
   - 未生成 → Step 1 (前提確認) から
   - 生成済み、採用分未反映 (git status / commit 履歴で確認) → Step 4 (反映) から
   - 生成済み、採用分反映済 (再 push 済み) → Step 5 (finish-spec-pr chain) から
5. `handoff.md` が同ディレクトリにあれば Read (補助情報)
6. 判定結果を user に「現在 Phase = X、Step Y から再開します」と明示、user 1 問確認

### Step 1: 前提確認 + テンプレ読み込み + AI 利用ポリシー案内 (ADR-0010)

1. `git rev-parse --show-toplevel` で git repo 確認
2. `enhance-superpowers/templates/review-response.md` を Read
3. プロジェクトルートの `.ai-restrictions.md` を Read (存在すれば user に案内)
4. review-source の確定 (argument 経由 or 直近の code-review skill 出力 or PR URL から CodeRabbit unresolved コメント取得)

### Step 2: 指摘の採用/Skip 判定 (2 値、保留禁止、全件判定必須)

1. CodeRabbit 指摘 (ローカル + PR 上 unresolved) を一覧化
2. ID を CodeRabbit 分類に揃える: Major `M1, M2, ...` / Minor `Mi1, Mi2, ...` / Trivial `T1, T2, ...`
3. 各指摘について 採用 / Skip を判定:
   - **判定迷い時**: `code-reviewer` を能動 dispatch (特に false positive 疑い時)、dispatch log を review-response.md レビュー履歴に追記 (ADR-0007)
   - **セキュリティ系指摘**: `security-engineer` を能動 dispatch して採用判定にセキュリティ観点を追加、dispatch log 追記
4. **保留は禁止**、全件を採用 / Skip のいずれかに判定する
5. Skip 判定時は理由を明記 (別 PR で対応 / プロジェクト規約で enforce されてない / 他の採用済み指摘で自動消化 等)

### Step 3: review-response.md を上書き保存

1. ファイル名: `{YYYY-MM-DD}-{slug}-review-response.md`、配置: `docs/superpowers/{branch}/`
2. **上書き運用** (最新ラウンドのみ保持、過去ラウンドの判定履歴は残さない)
3. テンプレの「採用」「Skip」「連動関係と効果」セクションを埋める
4. レビュー履歴セクションに dispatch log を追記:
   - Step 2 の code-reviewer / security-engineer dispatch 結果
   - **gwt-test の STOP POINT 2 で実施した security-engineer のコードセキュリティレビュー結果もここに集約** (ADR-0007)

### Step 4: 採用分を実装に反映 + 再 push 前の差し戻しレビュー

1. user 確認 → 採用分を実装に反映 (← user 作業 or AI 作業)
2. テストコード同期確認: 実装コード修正に伴うテストコード修正要否を確認、不要時も 1 行根拠を残す (review-response.md に記録)
3. **再 push 前に `code-reviewer` を能動 dispatch** — 修正コードの差し戻しレビュー
4. dispatch log を review-response.md レビュー履歴に追記 (ADR-0007)
5. 問題なければ user 承認 → push

### Step 5: 次工程 (finish-spec-pr) への chain (skill chain 継続)

1. user に「レビュー対応が完了しました。次は PR 作成です」と明示
2. `Skill` tool で `finish-spec-pr` skill を chain invoke
3. 中断時の再開方法を案内: 「(a) `enhance-brainstorming` を再 invoke (Step 0 で状態判定して続きから)、または (b) `finish-spec-pr` skill を直接 invoke」

## 規律明示

- CodeRabbit へのリプライは送らない (修正 push → 自動 resolve → 残 unresolved のみ判定)
- 採用/Skip 2 値 (保留禁止、全件判定必須)
- 採用後の実装修正でテストコード同期不要時は 1 行根拠を残す
- 判定迷い・セキュリティ系・採用後修正の 3 タイミングで agent を能動 dispatch (silent failure 回避)
- dispatch log を review-response.md のレビュー履歴セクションに追記 (ADR-0007、gwt-test の security-engineer コードレビュー結果もここに集約)
- 上書き運用 (最新ラウンドのみ保持、過去ラウンドは git log で追跡)
- Step 1 で AI 利用ポリシー (.ai-restrictions.md) を Read して案内 (ADR-0010)

## 失敗時の挙動

| 状況 | 挙動 |
|---|---|
| 判定迷う指摘 | user に提示 → code-reviewer dispatch → 判定 1 問確認 (保留禁止、必ず 2 値) |
| セキュリティ系指摘の採用判定 | security-engineer dispatch → 採用判定にセキュリティ観点追加 |
| 採用後の実装修正でテストコード同期不要 | 「不要根拠 1 行」を user に要請 → review-response.md に記録 |

## 関連

- ADR-0007 (audit-trail-dispatch-log)
- ADR-0010 (ai-utilization-policy-loading)
- ADR-0012 (implementation-phase-skill-and-state-detection) — Step 0 状態判定
- ADR-0013 (gwt-test-qa-engineer-always-dispatch-and-code-review-auto-invoke) — gwt-test Step 8 の code-review skill auto-invoke 結果を本 skill が引き継ぐ
- gwt-test SKILL.md (前工程 sub-skill、STOP POINT 2 で code-review auto-invoke + security-engineer コードレビューを実施)
- finish-spec-pr SKILL.md (次工程 sub-skill)

---
name: write-review-response
description: |
  ローカルの agent findings (implementation-reviewer / security-engineer / performance-engineer) と、
  GitHub PR 上の /review 指摘・CodeRabbit インラインコメントのうち unresolved 分を
  採用/Skip の 2 値で判定し、review-response.md に上書き運用で記録する skill (ADR-0015 D1・D2)。
  ID は CodeRabbit 分類に揃える (M1.../Mi1.../T1...)。CodeRabbit へのリプライは送らない
  (修正 push → 自動 resolve、残った unresolved のみ判定)。
  判定迷い時 / セキュリティ系指摘 / 採用後修正の 3 タイミングで implementation-reviewer /
  security-engineer を能動 dispatch、dispatch log は review-response.md のレビュー履歴に追記。
  Step 1 で .ai-restrictions.md を Read (ADR-0010)。
  引数 --output-dir / --gate-mode で出力先・gate 集約を制御 (省略時は従来挙動、ADR-0014)。
argument-hint: "[review-source] [--output-dir=<path>] [--gate-mode=per-phase|aggregate]  # ローカル agent findings or PR URL。引数は外部 collection 利用向け、省略時は従来挙動 (ADR-0014)"
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

レビュー指摘への対応方針を md ファイルとして記録する skill。gwt-test からの連鎖 (ローカル agent findings)、`finish-spec-pr` からの折り返し (PR 上の `/review` + CodeRabbit 指摘)、または user が直接 invoke のいずれでも動作する。

**指摘の出どころは 2 ラウンドある** (ADR-0015 D1・D2)。上書き運用のため、各ラウンドで review-response.md は最新の内容に置き換わる:

| ラウンド | 契機 | review-source |
|---|---|---|
| ローカル (PR 前) | `gwt-test` Step 8 から chain | `shared:implementation-reviewer` / `shared:security-engineer` / `/security-review` の findings |
| PR 後 | `finish-spec-pr` Step 6 から折り返し (user 1 問確認あり) | builtin `/review` の出力 + GitHub 上の CodeRabbit unresolved コメント |

## 引数 (ADR-0014)

いずれも任意。**省略時は従来挙動と完全に同一**。chain 元から引き継がれた場合はそのまま下流へも渡す。**伝播範囲**: `--output-dir` は `finish-spec-pr` まで、`--gate-mode` は本 skill まで。

| 引数 | 既定 | 効果 |
|---|---|---|
| `--output-dir=<path>` | `docs/superpowers/{branch}/` | 成果物の所在。Step 0 の状態判定と対象 file の自動検出先になる |
| `--gate-mode=aggregate` | `per-phase` | **本 skill では効果を持たない (受理のみ、下流の `finish-spec-pr` は受け取らない)**。唯一の効果だった code-review の課金前 1 問確認が ADR-0015 D1 で消滅したため。引数を落とさないのは indie-studio 側のアダプタ契約 (indie-studio ADR-0032) を壊さないため。削除条件は ADR-0015 D6 |

以降の `{出力先}` は「`--output-dir` 指定時はその値、省略時は `docs/superpowers/{branch}/`」を指す。

## Phase 定義 (ADR-0012 D3)

| Phase | 前提 file | 出力 | 出力条件 |
|---|---|---|---|
| 0 | gwt.md checklist 全 `- [x]` + ローカル agent findings or PR unresolved comments | (判定) | 状態判定完了、Step 番号を確定 |
| 判定 | 指摘一覧 (ローカル agent findings or PR 上の `/review` + CodeRabbit unresolved) | `{date}-{slug}-review-response.md` | 全指摘を採用/Skip 判定完了 (保留禁止) |
| 反映 | review-response.md 採用分 | 修正コード + 再 push | `shared:implementation-reviewer` の再 push 前レビュー完了 + user 承認 |

## 動作 (6 ステップ)

### Step 0: 状態判定 (ADR-0012 D2)

1. **`{出力先}` を確定**: `--output-dir` があればその値、無ければ `git rev-parse --abbrev-ref HEAD` → サニタイズ (`/` → `-`) → `docs/superpowers/{branch}/`
2. `{出力先}` を Glob で列挙、`*-gwt.md` / `*-review-response.md` の存在有無を確認
3. **前提**: gwt.md checklist が全 `- [x]` であること (gwt-test の Step 6 まで完了)。未達なら error "gwt-test を完了させてください" + 中断
4. review-response.md 状態を判定 (M5 fix 2026-07-04: remote 状態確認を追加、rev-list 方向を正しく):
   - 未生成 → Step 1 (前提確認) から
   - 生成済み、採用分未反映 (git status / commit 履歴で確認) → Step 4 (反映) から
   - 生成済み、採用分反映済 → 以下 3 面確認 (いずれか false なら Step 4 に戻す):
     a. review-response.md の「## 採用」節に採用項目が記録されている
     b. `git fetch origin && git rev-list origin/{raw-branch}..HEAD` が **0** (`origin..HEAD` の方向、unpushed commit が無いこと)
        - fetch 失敗時 (offline / remote 未設定 等): user に 1 問確認「オフラインで push 判定不能、Step 5 に進みますか?」
     c. `gh pr view --json state,number --head {raw-branch}` で PR 存在確認
        - PR あり: review-response.md 保存 timestamp 以降の commit が PR HEAD 側にあることを `gh pr view --json commits` で確認
        - PR なし: 「PR 未作成、Step 5 (finish-spec-pr chain) で作成します」と user 明示
     → 全 pass → Step 5 (finish-spec-pr chain)
     → 判定失敗時は user に「原因: {a/b/c} が {理由}」と明示して Step 4 に戻す
5. `handoff.md` が同ディレクトリにあれば Read (補助情報)
6. 判定結果を user に「現在 Phase = X、Step Y から再開します」と明示、user 1 問確認

### Step 1: 前提確認 + テンプレ読み込み + AI 利用ポリシー案内 (ADR-0010)

1. `git rev-parse --show-toplevel` で git repo 確認
2. `enhance-superpowers/templates/review-response.md` を Read
3. プロジェクトルートの `.ai-restrictions.md` を Read (存在すれば user に案内)
4. review-source の確定 (ADR-0015 D1・D2)。argument で明示されていればそれを使い、無ければ以下の順で解決する:
   - **ローカルラウンド** (`gwt-test` から chain されたとき): chain 元が渡した `shared:implementation-reviewer` / `shared:security-engineer` / `/security-review` の findings
   - **PR 後ラウンド** (`finish-spec-pr` から折り返されたとき、または PR URL が渡されたとき): builtin `/review` の出力 + `gh` で取得した PR 上の CodeRabbit unresolved コメント
   - どちらも取れなければ error 報告 + 中断 (「review-source を特定できません。gwt-test を完了させるか、PR URL を引数で渡してください」)

### Step 2: 指摘の採用/Skip 判定 (2 値、保留禁止、全件判定必須)

1. 指摘 (ローカル agent findings、または PR 上の `/review` 出力 + CodeRabbit unresolved) を一覧化
2. ID を CodeRabbit 分類に揃える: Major `M1, M2, ...` / Minor `Mi1, Mi2, ...` / Trivial `T1, T2, ...`
3. 各指摘について 採用 / Skip を判定:
   - **判定迷い時**: `shared:implementation-reviewer` を能動 dispatch (判定 aid 専用、false positive 疑い時等)、dispatch log を review-response.md レビュー履歴に追記 (ADR-0007)
   - **セキュリティ系指摘**: `shared:security-engineer` を能動 dispatch (評価 mode) して採用判定にセキュリティ観点を追加、dispatch log 追記
   - **大規模 refactor 系指摘 or 設計妥当性の疑い**: `shared:reviewer` を能動 dispatch (独立観点評価、真実源整合 / 内部一貫性)、dispatch log 追記
4. **保留は禁止**、全件を採用 / Skip のいずれかに判定する
5. Skip 判定時は理由を明記 (別 PR で対応 / プロジェクト規約で enforce されてない / 他の採用済み指摘で自動消化 等)

### Step 3: review-response.md を上書き保存

1. ファイル名: `{YYYY-MM-DD}-{slug}-review-response.md`、配置: `{出力先}`
2. **上書き運用** (最新ラウンドのみ保持、過去ラウンドの判定履歴は残さない)
3. テンプレの「採用」「Skip」「連動関係と効果」セクションを埋める
4. レビュー履歴セクションに dispatch log を追記:
   - Step 2 の implementation-reviewer / security-engineer dispatch 結果
   - **gwt-test の STOP POINT 2 で実施した security-engineer のコードセキュリティレビュー結果もここに集約** (ADR-0007)

### Step 4: 採用分を実装に反映 + 再 push 前レビュー (宛先は ADR-0015 D1)

1. user 確認 → 採用分を実装に反映 (← user 作業 or AI 作業)
2. テストコード同期確認: 実装コード修正に伴うテストコード修正要否を確認、不要時も 1 行根拠を残す (review-response.md に記録)
3. **再 push 前に `shared:implementation-reviewer` を能動 dispatch** (評価 mode、常時、課金なし)。反映した修正が採用した findings を実際に解消しているかを検証する。invocation prompt に以下を渡す:
   - **評価対象**: 今回の反映で生じた差分 / 評価ラウンド番号
   - **答え合わせ材料**: review-response.md の「## 採用」節 (解消すべき findings) / gwt.md の該当 AC / リポジトリの `AGENTS.md` (無ければ `CLAUDE.md`)
   - **評価観点**: 採用した findings が解消されているか + 修正による回帰 (silent failure / テスト未同期) が無いか
   - **進行 protocol**: **差し戻し protocol を use 宣言する** — round1 = fresh、round2-3 = continuation でスコープ凍結、**最大 3 ラウンド**、3R 未達は decide-record-proceed で理由を review-response.md に記録
4. dispatch log (implementation-reviewer の合否とラウンド数、結果要約) を review-response.md レビュー履歴に追記 (ADR-0007)
5. 問題なければ user 承認 → push

### Step 5: 次工程 (finish-spec-pr) への chain (skill chain 継続)

1. user に「レビュー対応が完了しました。次は PR 作成です」と明示
2. `Skill` tool で `enhance-superpowers:finish-spec-pr` skill を chain invoke (`--output-dir` を受け取っていれば**そのまま引き継いで渡す**)
3. 中断時の再開方法を案内: 「(a) `enhance-brainstorming` を再 invoke (Step 0 で状態判定して続きから)、または (b) `enhance-superpowers:finish-spec-pr` skill を直接 invoke」(**`--output-dir` を同じ値で渡すこと**)

## 規律明示

- **agent の `subagent_type` は `plugin:agent` 形式の修飾名を使う** (例: `shared:software-architect`)。bare name は解決されない。engineering 系 13 職種は `shared` plugin が提供する (root ADR-0010)
- CodeRabbit へのリプライは送らない (修正 push → 自動 resolve → 残 unresolved のみ判定)
- 採用/Skip 2 値 (保留禁止、全件判定必須)
- 採用後の実装修正でテストコード同期不要時は 1 行根拠を残す
- 判定迷い・セキュリティ系・採用後修正の 3 タイミングで agent を能動 dispatch (silent failure 回避)
- **ローカルで CodeRabbit / `code-review` 系 skill を呼ばない** (ADR-0015 D1)。CodeRabbit の指摘を扱うのは PR 後ラウンド (GitHub App の unresolved コメント) だけ
- dispatch log を review-response.md のレビュー履歴セクションに追記 (ADR-0007、gwt-test の security-engineer コードレビュー結果もここに集約)
- 上書き運用 (最新ラウンドのみ保持、過去ラウンドは git log で追跡)
- Step 1 で AI 利用ポリシー (.ai-restrictions.md) を Read して案内 (ADR-0010)

## 失敗時の挙動

| 状況 | 挙動 |
|---|---|
| 判定迷う指摘 | user に提示 → shared:implementation-reviewer dispatch → 判定 1 問確認 (保留禁止、必ず 2 値) |
| セキュリティ系指摘の採用判定 | shared:security-engineer dispatch → 採用判定にセキュリティ観点追加 |
| 採用後の実装修正でテストコード同期不要 | 「不要根拠 1 行」を user に要請 → review-response.md に記録 |

## 関連

- ADR-0007 (audit-trail-dispatch-log)
- ADR-0010 (ai-utilization-policy-loading)
- ADR-0012 (implementation-phase-skill-and-state-detection) — Step 0 状態判定
- ADR-0013 (gwt-test-qa-engineer-always-dispatch-and-code-review-auto-invoke) — gwt-test Step 8 のセルフレビュー結果を本 skill が引き継ぐ
- ADR-0015 (local-review-to-implementation-reviewer-and-builtin-review-after-pr) — review-source が 2 ラウンド化 (D1・D2)、Step 4 の宛先変更 (D1)、`--gate-mode` の効果消滅 (D6)
- gwt-test SKILL.md (前工程 sub-skill、STOP POINT 2 で implementation-reviewer + security-engineer + /security-review を実施)
- finish-spec-pr SKILL.md (次工程 sub-skill。Step 6 で `/review` を回し、指摘があれば user 1 問確認のうえ本 skill に折り返す)

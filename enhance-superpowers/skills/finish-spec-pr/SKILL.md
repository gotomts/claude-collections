---
name: finish-spec-pr
description: |
  Spec フェーズで作成済みの pr-description.md を body として、shared/skills/finish-stage-pr を
  body-source-path 指定で呼んで PR 作成する skill。enhance-brainstorming Phase 6 で生成された
  pr-description.md (`## やったこと` / `## 補足` / `## 動作確認方法` の 3 セクション) を整え、
  title を user に 1 問確認、finish-stage-pr の Step 8 でユーザー最終確認 → push + gh pr create。
  Step 1 で .ai-restrictions.md を Read (ADR-0010)。
argument-hint: "[pr-description-path]  # pr-description.md のパス (省略時は docs/superpowers/{branch}/ から自動検出)"
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Skill
maintainer: gotomts
---

# finish-spec-pr

レビュー対応完了後に呼び出し、Spec フェーズの pr-description.md を body として PR を作成する skill。write-review-response からの連鎖、または user が直接 invoke のどちらでも動作。

## 動作 (6 ステップ)

### Step 1: 前提確認 + pr-description.md 読み込み + AI 利用ポリシー案内 (ADR-0010)

1. `git rev-parse --show-toplevel` で git repo 確認
2. `git branch --show-current` で現ブランチ取得、main 直作業を拒否 ("main 直作業では PR を出せません")
3. argument 経由 or `docs/superpowers/{branch}/*-pr-description.md` から自動検出
4. プロジェクトルートの `.ai-restrictions.md` を Read (存在すれば user に案内)
5. pr-description.md が見つからなければ error 報告 + 中断 ("Spec フェーズで pr-description.md を作成してから再 invoke")

### Step 2: pr-description.md の整え

1. `## やったこと` を実装結果に合わせて user 確認しながら整える (Spec フェーズの下書きから実装結果へ揃える)
2. `## 補足` 内容がなければセクションごと削除 (雛形をそのまま残さない)
3. `## 動作確認方法` は Spec で確定済みのため流用 (AC が実装中に変わった場合のみ gwt.md の変更履歴と整合する形で更新)
4. 必要なら Edit で pr-description.md を更新

### Step 3: commit 差分の確認 (空 PR 防止)

1. `git status --porcelain` で未 commit 変更がないことを確認 (あれば中断 "未 commit 変更があります、commit してから再度 invoke")
2. base 解決: `git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||'`
3. `git log <base>..HEAD --oneline` で commit 差分一覧を表示

### Step 4: PR title を user に 1 問確認

1. Conventional Commits 形式の title 案を提示 (`feat:` / `fix:` / `refactor:` / `docs:` 等から judgement)、リポジトリ既存規約があればそちら優先
2. user に「この title で進めて良いですか? (yes / 別案を提示)」と 1 問確認
3. `yes` → Step 5 へ / `別案` → user 入力を待って title を差し替えて再確認

### Step 5: `shared/skills/finish-stage-pr` を body-source-path 指定で invoke

1. `Skill` tool で `finish-stage-pr` を invoke、argument に title + body-source-path を渡す:
   ```
   <title-confirmed> {absolute path to pr-description.md}
   ```
2. finish-stage-pr の Step 1-7 が実行される (環境チェック / 未 commit 確認 / base 解決 / 既存 PR チェック / draft/ready 判定 / body 読み込み)
3. finish-stage-pr の Step 8 (PR 作成最終確認) で user に title / base / state / labels を提示 → ユーザー最終確認 → yes なら Step 9-11 (label 確認 / push / gh pr create)

### Step 6: 完了報告

1. 作成された PR URL を user に表示 (finish-stage-pr の Step 11 出力)
2. 「Spec フェーズから PR 作成までの全工程が完了しました。お疲れさまでした」と user に通知

## 規律明示

- Step 1 で AI 利用ポリシー (`.ai-restrictions.md`) を Read して案内 (ADR-0010)
- finish-spec-pr 自体は agent dispatch しない (mechanical な操作のみ)、dispatch log 追記もなし (Agent dispatch matrix で「(なし)」)
- main 直作業を拒否、未 commit のまま PR を作らない
- title は Conventional Commits 形式 (リポジトリ既存規約があればそちら優先)、 user 1 問確認は必須
- body は pr-description.md を **そのまま**渡す (新規生成しない、Spec フェーズの先行作成物を再利用)、`.github/PULL_REQUEST_TEMPLATE.md` は使わない (pr-description.md を SSOT とする)

## 失敗時の挙動

| 状況 | 挙動 |
|---|---|
| 現在 `main` ブランチ | "main 直作業では PR を出せません" + 中断 |
| pr-description.md 未生成 | error 報告 + 中断 ("Spec フェーズで pr-description.md を作成してから再 invoke") |
| dirty working tree | "未 commit 変更があります、commit してから再度 invoke" + 中断 |
| commit が 0 件 (空 PR) | finish-stage-pr の Step 4 で "差分がないので PR を作りません" + 中断 |
| push / gh pr create 失敗 | finish-stage-pr の error handling に委譲 (`gh auth status` 案内等) |

## 関連

- ADR-0004 (shared-skills-finish-stage-pr-extension)
- ADR-0010 (ai-utilization-policy-loading)
- write-review-response SKILL.md (前工程 sub-skill)
- shared/skills/finish-stage-pr SKILL.md (本 skill が body-source-path 指定で invoke)

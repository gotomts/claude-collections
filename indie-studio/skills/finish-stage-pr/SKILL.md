---
name: finish-stage-pr
description: |
  service repo 内で、skill 完了時に push + PR open を担当する共有 helper。
  呼び出し側 (各 stage skill) が PR title 候補・stage・label・⚠️ 残数・
  ゲートレポート要約を args で渡し、本 skill が draft/ready 判定・
  user 最終確認・gh pr create を担当する。汎用なので indie-studio
  以外の collection からも利用可。
argument-hint: "<title-suggestion>  # body 用情報は呼び出し側 SKILL.md の prose で渡す"
allowed-tools:
  - Bash
  - Read
maintainer: gotomts
x-source: shared/skills/finish-stage-pr/SKILL.md
x-source-hash: sha256:6c1177780d43ae18dafd57428f3d00b567e3c05b462fe4fb0ea9142aa17a8393
x-body-hash: sha256:ea37531dba0d5e99a36c15d169a5200bdf2ade2a9f14d4cd86263d8d8dd0ccf3
x-synced-at: 2026-06-23T11:13:43Z
---

# finish-stage-pr

呼び出し側 skill から PR title 候補・stage キー・label・⚠️ 残数・ゲートレポート要約を受け取り、現 branch を push して PR を open する共有 helper。⚠️ 残数で draft / ready を自動判定する。

## 使うべきとき

各 stage skill が完全性ガード（期待マニフェスト ✅/➖/⚠️ 決着）を提示した直後に invoke する。呼び出し側が PR title 候補と body 構成要素を prose で渡す前提。

## 使わないとき

- 完全性ガードが未完了の場合（呼び出し側が判定し、未完了なら invoke しない）。
- 単独 commit でローカルに留めたい場合（`commit-commands:commit` を使う）。
- merge / 自動レビュアー割り当てをしたい場合（本 helper の責務外）。

## 入力（呼び出し側 SKILL.md の prose で渡す）

| 項目 | 内容 | 例 |
|---|---|---|
| title 候補 | conventional commits 風 1 行 | `feat(s1): service-discovery 完了 (socialcoffeenote)` |
| ⚠️ 残数 | 完全性ガードで未解消の項目数 | 0 / 2 |
| ゲートレポート要約 | ✅/➖/⚠️ 件数と要点 | `✅ 12 / ➖ 3 / ⚠️ 0` |
| label 候補 | indie-studio + stage 名 | `indie-studio`, `s1` |
| stage キー | branch 名と整合 | `s1` |

## 実行ステップ

### Step 1: 環境チェック

`git rev-parse --show-toplevel` で git repo を確認。`git branch --show-current` で現 branch を取得し、`main` 直作業を拒否（"main 直作業では PR を出せません" + 中断）。

### Step 2: 未 commit 確認

```sh
git status --porcelain
```

出力が空でなければ "未 commit 変更があります。commit してから再度 invoke してください" で中断（自動 commit はしない）。

### Step 3: base 解決

```sh
git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||'
```

取得できれば `origin/<default>`、失敗なら `origin/main` を default として提示。

### Step 4: commit 差分の確認（空 PR 防止）

```sh
git log origin/main..HEAD --oneline
```

出力が空なら "差分がないので PR を作りません" + 中断。

### Step 5: 既存 PR チェック

```sh
gh pr list --head <current-branch> --json number,title
```

ヒットしたら "branch X には既に PR #N があります" を見せ、`gh pr edit` で更新か新規かを 1 問確認。

### Step 6: draft / ready 判定

呼び出し側から受けた ⚠️ 残数で判定：

- `⚠️ 残数 > 0` → **draft**
- `⚠️ 残数 == 0` → **ready**

### Step 7: PR body を組み立て

テンプレ：

```markdown
## 概要
<呼び出し側からの 1 行説明>

## ゲートレポート
✅ <件数> / ➖ <件数> / ⚠️ <件数>

<⚠️ がある場合のみ>
### 繰り越し論点
- <item 1>
- <item 2>

## 関連
- stage: <s1 / s1a / s1b / s3 / s4 / s5>
- skill: <service-discovery / ...>

🤖 Generated via indie-studio harness (`finish-stage-pr` helper)
```

### Step 8: ユーザー最終確認（1 問）

提示形式：

```
PR を作成します:
  title: <title>
  base: origin/main
  state: draft (⚠️ 2 件残り) | ready (⚠️ 0)
  labels: indie-studio, s1
進めて良いですか? (yes / title 修正 / no)
```

- `yes` → Step 9 へ。
- `title 修正` → user 入力を待って title を差し替え、Step 8 から再確認。
- `no` → PR を作らず終了、branch は残す（再 invoke 可能）。

### Step 9: label 存在確認

```sh
gh label list --json name | jq -r '.[].name'
```

提示 label が無ければ "label '<name>' が無いので作成しますか? (yes/no)" 1 問確認。yes なら：

```sh
gh label create <name> --color <default-color>
```

`default-color` は label 名に応じて選ぶ（例: `indie-studio` → `8B5CF6`、`s1` → `0E8A16`）。

### Step 10: push と PR open

```sh
git push -u origin <current-branch>
gh pr create --base <base-branch> --head <current-branch> --title "<title>" --body "<body>" [--draft]
gh pr edit <new-pr-number> --add-label "<label1>" --add-label "<label2>"
```

`--draft` は ⚠️ 残数 > 0 の場合のみ付ける。

### Step 11: 完了報告

作成された PR URL を user に表示。呼び出し元 skill に制御を返す。

## 失敗時の挙動

| 状況 | 挙動 |
|---|---|
| 現在 `main` | "main 直作業では PR を出せません" + 中断 |
| dirty working tree | "未 commit 変更があります。commit してから再度 invoke してください" + 中断 |
| 既存 PR が同 head | "branch X には既に PR #N があります" を見せ、`gh pr edit` で更新か新規かを 1 問確認 |
| commit が 0 件（空 PR） | "差分がないので PR を作りません" + 中断 |
| push 失敗（認証等） | エラー出力を見せて中断、`gh auth status` を案内 |
| ユーザーが "no" を返した | PR を作らず終了、branch は残す |
| label が未存在 | `gh label create` を 1 問確認して自動作成 |

## やらないこと

- 自動 merge（G3/G4/G5 ゲートの責務、reviewer 判断）。
- reviewer 自動割り当て（個人開発前提）。
- amend / force-push（危険操作禁止規律）。
- 自動 commit（呼び出し側に責任を持たせる）。

## 関連

- root ADR-0005（shared/skills/ vendoring）
- 呼び出し側の規約は collection 側の ADR で定める（例: indie-studio ADR-0031）

---
name: start-stage-branch
description: |
  service repo 内で、skill 起動時に branch + worktree を切る共有 helper。
  呼び出し側 (各 stage skill) が推奨 branch 名を args で渡し、本 skill が
  重複検出・suffix 付与・ユーザー承認・wt switch --create を担当する。
  汎用なので indie-studio 以外の collection からも利用可。
argument-hint: "<branch-suggestion>  # 例: s1/service-discovery"
allowed-tools:
  - Bash
  - Read
maintainer: gotomts
---

# start-stage-branch

呼び出し側 skill から推奨 branch 名を受け取り、service repo に branch + worktree を 1 アクションで用意する共有 helper。`wt switch --create` で worktree とブランチを同時に作る。

## 使うべきとき

各 stage skill（例: `service-discovery` / `tech-design` / `decomposition` 等）が冒頭で「自分の実行を独立 branch で隔離する」ために invoke する。呼び出し側が args 1 行で推奨 branch 名（`<stage>/<skill-name>` 形式）を渡す前提。

## 使わないとき

- 呼び出し側に branch suggestion 引数が無い場合（argument-hint 必須）。
- Linear / GitHub URL から命名したい場合（user 直接の `wt-start` を使う）。
- 単独タスクで main 直作業を尊重する場合（呼び出し側 skill が判断）。

## 実行ステップ

### Step 1: 環境チェック

`git rev-parse --show-toplevel` が成功することを確認。失敗（git repo 外）なら error 報告して中断（呼び出し元 skill に「進める」と誤判定させない）。

### Step 2: base ブランチを解決

```sh
git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||'
```

取得できれば `origin/<default>` を base に。失敗（remote 未設定）なら `origin/main` を default として提示し、user に確認。

### Step 3: 重複検出

引数 `<branch-suggestion>` を受けて、以下を順にチェック：

```sh
git rev-parse --verify <branch-suggestion> 2>/dev/null
git ls-remote --heads origin <branch-suggestion> 2>/dev/null
```

どちらかにヒットしたら、`<branch-suggestion>-2` → `-3` → ... と suffix を増やして空きを取る。

### Step 4: ユーザー承認（1 問）

提示形式：

```
推奨: <候補 branch 名>
base: origin/main
この名前で進めて良いですか? (yes / 別名)
```

- `yes` → Step 5 へ。
- `別名` → 提示された名前で Step 3 から再開（重複検出やり直し）。

### Step 5: 実行

```sh
wt switch --create <approved-branch> --base <base>
```

`-y` (skip approval) は付けない。実行前に最終コマンドを user に見せる。

### Step 6: 完了報告

worktree のパスと「呼び出し元 skill に制御を返します」を 1〜2 行で返す。

## 失敗時の挙動

| 状況 | 挙動 |
|---|---|
| git repo 外 | error 報告 + 中断（skill 本体に進まない） |
| 既存 worktree 内 | "既に worktree 内ですが新規追加で進めますか?" 1 問確認 |
| `wt` コマンド不在 | error 報告 + 中断（依存性チェック） |
| `wt switch --create` 失敗 | エラー出力を見せて中断、リカバリは呼び出し側ユーザー判断 |
| user が "別名" を返した | その名前で再度重複検出してやり直し |

## やらないこと

- Linear / GitHub からの命名（`wt-start` の責務、必要なら別 helper に分離）。
- branch 名規約の strict validation（呼び出し側が責任を持つ）。
- editor / claude 起動の連鎖。
- merge / PR 作成（PR は `finish-stage-pr` の責務）。

## 関連

- root ADR-0005（shared/skills/ vendoring）
- 呼び出し側の規約は collection 側の ADR で定める（例: indie-studio ADR-0031）

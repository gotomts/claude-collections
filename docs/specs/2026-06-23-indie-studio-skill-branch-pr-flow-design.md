# indie-studio skill branch + PR フロー 実装 design

ADR-0005（root・新規）と ADR-0031（indie-studio・新規）で採択する方針を実装レベルに翻訳した design spec。本 spec は **architectural 決定の繰り返しではなく**、ADR で定まる方針を前提に「ファイル配置・スキーマ・スクリプト I/F・helper skill 仕様・既存 skill 改修パターン・エラーハンドリング・移行手順・リリース順序」を具体化する。

> **未起稿 ADR への前方参照について**: 本 spec の commit 時点で root ADR-0005 / indie-studio ADR-0031 はまだ起稿されていない。本 spec はそれらの ADR を**この spec の合意内容に基づいて後続で起稿する**前提で書かれている。ADR 起稿時に本 spec の決定との齟齬が出たら、spec 側を訂正する（spec は ADR の実装翻訳であり、ADR が真実源）。

> **ADR 参照規約**: 本 spec で「root ADR-XXXX」と書いたものは `docs/adr/` 配下、注記無しの「ADR-XXXX」は `indie-studio/docs/adr/` 配下を指す。番号空間が衝突するため明示する。

## 0. 前提

- root ADR-0001（複数コレクション構造）・root ADR-0003（plugin marketplace 配布）・root ADR-0004（shared/agents/ vendoring）の決定を前提とする
- 共有対象として新規追加する skill は **2 つ**：`start-stage-branch`・`finish-stage-pr`
- 適用先 collection は **`indie-studio` のみ**（本 spec のスコープ）。他 collection への展開は YAGNI
- 既存 indie-studio skill **6 つ**を改修対象とする：`service-discovery` / `stack-direction` / `design-direction` / `tech-design` / `decomposition` / `implementation`
- 改修は service repo（例：socialcoffeenote）側での skill 起動時挙動を変える。`claude-collections` 自身の workflow には影響しない
- ADR-0004（自走設計）・ADR-0007（5 大枠ゲート）・ADR-0008（適応 PR ゲート）の規律と整合する形で、既存 SKILL.md の「破壊的操作の禁止」セクションを部分緩和する

## 1. 全体像（2 layer）

変更スコープは independent な 2 layer に分割し、**2 段リリース**で出す。

```
Layer A: vendoring system 拡張（claude-collections 改修・PR1）
  - docs/adr/0005-shared-skills-vendoring.md         # 新規
  - scripts/sync-shared.sh                            # 拡張
  - shared/skills/start-stage-branch/SKILL.md         # 新規（真実源）
  - shared/skills/finish-stage-pr/SKILL.md            # 新規（真実源）
  - AGENTS.md (root) shared/ 規約 skills 追記

Layer B: indie-studio 適用（同 repo・PR2、PR1 マージ後 rebase）
  - indie-studio/docs/adr/0031-skill-branch-pr-flow.md   # 新規
  - indie-studio/.claude-plugin/dependencies.json       # shared.skills[] 追加
  - indie-studio/skills/{start-stage-branch,finish-stage-pr}/SKILL.md  # generated
  - indie-studio/skills/{6 skill}/SKILL.md              # 改修
  - indie-studio/AGENTS.md                              # stage マップ追記
```

**実行フロー**（service repo 側でユーザーが skill 起動した時）:

```
User: /service-discovery (in service repo, e.g. ~/socialcoffeenote)
  └─ SKILL.md 冒頭が start-stage-branch を invoke
       └─ branch 名候補 `s1/service-discovery` を提案
       └─ ユーザー yes/no/別名 で確認
       └─ wt switch --create s1/service-discovery --base origin/main
  └─ SKILL 本体実行（既存ロジック・S1 自律導出）
       └─ commit を都度作る（既存規律）
  └─ 完全性ガード（期待マニフェスト ✅/➖/⚠️ 決着）
  └─ ゲートレポート提示（既存）
  └─ SKILL.md 末尾が finish-stage-pr を invoke
       └─ ⚠️ 残数で draft/ready 判定
       └─ PR title / body 自動生成（commit log + ゲートレポート要約）
       └─ ユーザー最終確認
       └─ git push + gh pr create
  └─ skill 終了
```

## 2. shared/skills/ vendoring 拡張（Layer A / PR1）

### 2.1 ディレクトリ構造の変化

```
claude-collections/
  shared/
    agents/        # 既存
    skills/        # NEW
      start-stage-branch/
        SKILL.md
      finish-stage-pr/
        SKILL.md
  scripts/
    sync-shared.sh  # 拡張
  docs/
    adr/
      0005-shared-skills-vendoring.md  # NEW（ADR-0004 を extends）
```

### 2.2 `<collection>/.claude-plugin/dependencies.json` schema 拡張

```json
{
  "shared": {
    "agents": ["backend-engineer", "..."],
    "skills": ["start-stage-branch", "finish-stage-pr"]
  }
}
```

- `shared.skills` は **任意フィールド**。既存 collection の dependencies.json を変更不要にする
- 空配列 or キー無しは no-op
- 配列要素の重複は sync 時 error（agents と同規律）
- shared/agents/ と shared/skills/ の `name` 衝突は禁止（top-level で別 namespace なので構造的に分離）

### 2.3 `scripts/sync-shared.sh` 改修

既存ロジックを最大限再利用し、skill 用の path 解決と loop だけ追加する。

```
追加: read_picked_skills()       <- jq -r '.shared.skills[]'
追加: sync_one_skill()            <- src=shared/skills/<name>/SKILL.md
                                     dst=<col>/skills/<name>/SKILL.md
追加: skill 用 sync/verify/status のループ
変更なし: file_hash / body_hash / is_generated / read_source_hash / read_body_hash
変更なし: frontmatter awk ロジック（x-source, x-source-hash, x-body-hash, x-synced-at の埋め込み）
変更なし: discover_collections / duplicate check の構造
```

**cmd_sync / cmd_verify / cmd_status の各 collection ループ内:**
1. agents セクション処理（既存）
2. skills セクション処理（追加・agents と同型）

**スコープ制限（YAGNI）:**
- 当面 `shared/skills/<name>/SKILL.md` の **1 ファイルのみ** sync 対象
- `<name>/references/*.md` 等の補助ファイルは対象外。要望が出た時点で別 ADR で拡張

### 2.4 generated file の見た目（`<collection>/skills/start-stage-branch/SKILL.md`）

```yaml
---
name: start-stage-branch
description: ...
x-source: shared/skills/start-stage-branch/SKILL.md
x-source-hash: sha256:<src全体>
x-body-hash: sha256:<src body>
x-synced-at: 2026-06-23T12:34:56Z
---

# start-stage-branch
...本文...
```

agents と完全同型なので CI verify も流用。

### 2.5 root `AGENTS.md` 追記

既存「## shared/ の共有エージェント」セクション直後に新セクション。

```markdown
## shared/ の共有スキル

- helper 系（例：start-stage-branch / finish-stage-pr）の共通スキルは `shared/skills/` を真実源とする（ADR-0005）。
- 各コレクションは `<collection>/.claude-plugin/dependencies.json` の `shared.skills[]` で取り込み宣言する。
- 取り込みの実体化は `make sync` で。`<collection>/skills/<name>/SKILL.md` に generated file が書き出される（frontmatter に `x-source` / `x-source-hash` / `x-body-hash` / `x-synced-at` を持つ）。
- generated file は **手編集禁止**。shared 側を編集して `make sync` で反映。
- `make verify` の drift 検知は agents と同型（source-hash mismatch / body modified）。
- 当面 1 skill = 1 SKILL.md（補助ファイルは sync 対象外）。複雑な skill 構成が必要になった時点で本 ADR を拡張。
```

## 3. helper skill 仕様

### 3.1 設計原則

両 helper とも **collection 横断で使える**ことが前提。indie-studio 専有のロジック（stage マップなど）は **呼び出し側の SKILL.md から引数で渡す**ことで helper を pure に保つ。

```
indie-studio/skills/service-discovery/SKILL.md  (呼び出し側)
   └─ "start-stage-branch を args='s1/service-discovery' で invoke"

shared/skills/start-stage-branch/SKILL.md  (汎用 helper)
   └─ 引数を受けて branch 名候補化・重複サフィックス・wt switch --create
```

### 3.2 `start-stage-branch` 仕様

```yaml
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
```

**実行ステップ:**

1. **環境チェック**: `git rev-parse --show-toplevel` で git repo を確認（失敗→中断）
2. **base 解決**: `git symbolic-ref refs/remotes/origin/HEAD` で default branch、`origin/<default>` を base
3. **重複検出**: `git rev-parse --verify <branch-suggestion>` と `git ls-remote --heads origin <branch-suggestion>` で local/remote 存在チェック。存在 → `-2`, `-3`, ... を順に試して空きを取る
4. **ユーザー承認（1 問）**:
   ```
   推奨: <候補 branch 名>
   base: origin/main
   この名前で進めて良いですか? (yes / 別名)
   ```
5. **承認後実行**: `wt switch --create <approved-branch> --base <base>`
6. **完了報告（1〜2 行）**: worktree path と「呼び出し元 skill に制御を返します」

**失敗系挙動:**

| 状況 | 挙動 |
|---|---|
| git repo 外 | error 報告 + 中断（skill 本体に進まない） |
| 既存 worktree 内 | "既に worktree 内ですが新規追加で進めますか?" 1 問確認 |
| `wt` コマンド不在 | error 報告 + 中断（依存性チェック） |
| `wt switch --create` 失敗 | エラー出力を見せて中断、リカバリは呼び出し側ユーザー判断 |
| user が "別名" を返した | その名前で再度重複検出してやり直し |

**やらないこと:**
- Linear/GitHub からの命名（wt-start の責務、必要なら別 helper に分離）
- branch 名規約の strict validation（呼び出し側が責任を持つ）
- editor / claude 起動の連鎖

### 3.3 `finish-stage-pr` 仕様

```yaml
---
name: finish-stage-pr
description: |
  service repo 内で、skill 完了時に commit + push + PR open を担当する共有 helper。
  呼び出し側 (各 stage skill) が PR title 候補・body 用 gate report・⚠️ 残数を args で
  渡し、本 skill が draft/ready 判定・user 最終確認・gh pr create を担当する。
  汎用なので indie-studio 以外の collection からも利用可。
argument-hint: "<title-suggestion>  # body は stdin or follow-up で受ける"
allowed-tools:
  - Bash
  - Read
maintainer: gotomts
---
```

**入力（呼び出し側 SKILL.md からの prose で受ける）:**

| 項目 | 内容 | 例 |
|---|---|---|
| title 候補 | conventional commits 風 1 行 | `feat(s1): service-discovery 完了 (socialcoffeenote)` |
| ⚠️ 残数 | 完全性ガードで未解消の項目数 | 0 / 2 |
| ゲートレポート要約 | ✅/➖/⚠️ 件数と要点 | `✅ 12 / ➖ 3 / ⚠️ 0` |
| label 候補 | indie-studio + stage 名 | `indie-studio`, `s1` |
| stage キー | branch 名と整合 | `s1` |

**実行ステップ:**

1. **環境チェック**: git repo & 現 branch 取得（`git branch --show-current`）、`main` 直作業を拒否
2. **未 commit 確認**: `git status --porcelain` で working tree clean、dirty なら "commit してから再 invoke" で中断（自動 commit はしない）
3. **base 解決**: `git symbolic-ref refs/remotes/origin/HEAD` で default branch、`origin/main` を base
4. **draft/ready 判定**:
   - `⚠️ 残数 > 0` → **draft**
   - `⚠️ 残数 == 0` → **ready**
5. **PR title 候補生成**: 呼び出し側から受けた title をそのまま提示、調整可
6. **PR body 自動生成（テンプレ）**:

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

7. **ユーザー最終確認（1 問）**:
   ```
   PR を作成します:
     title: <title>
     base: origin/main
     state: draft (⚠️ 2 件残り) | ready (⚠️ 0)
     labels: indie-studio, s1
   進めて良いですか? (yes / title 修正 / no)
   ```
8. **承認後実行**: `git push -u origin <branch>` → `gh pr create --base main --head <branch> --title ... --body ... [--draft]` → `gh pr edit --add-label ...`
9. **完了報告**: PR URL を表示

**失敗系挙動:**

| 状況 | 挙動 |
|---|---|
| 現在 `main` | "main 直作業では PR を出せません" + 中断 |
| dirty working tree | "未 commit 変更があります。commit してから再度 invoke してください" + 中断 |
| 既存 PR が同 head | "branch X には既に PR #N があります" を見せ、`gh pr edit` で更新か新規かを 1 問確認 |
| commit が 0 件（空 PR） | "差分がないので PR を作りません" + 中断 |
| push 失敗（認証等） | エラー出力を見せて中断、`gh auth status` を案内 |
| ユーザーが "no" を返した | PR を作らず終了、branch は残す（再 invoke 可能） |
| label が未存在 | `gh label create` を 1 問確認して自動作成（デフォルト color） |

**やらないこと:**
- 自動 merge（G3/G4/G5 ゲートの責務、reviewer 判断）
- reviewer 自動割り当て（個人開発前提）
- amend / force-push（危険操作禁止規律）

### 3.4 共通の安全弁

両 helper とも:
- destructive op 前にユーザー承認を必ず取る（`wt switch --create` / `git push` / `gh pr create`）
- `--no-verify` / `--force` などのフラグは付けない
- stdout/stderr は呼び出し元の skill 本体に見えるよう抑制しない
- 失敗時は明示 error で中断、呼び出し側 skill 本体に「進める」と誤判定させない

## 4. indie-studio 適用（Layer B / PR2）

### 4.1 既存 6 SKILL.md の改修パターン

各 SKILL.md の以下 3 箇所を変更する。

**A. 冒頭「ステージ構造」セクションの直前に新セクション追加:**

```markdown
## ブランチ作成（skill 開始時）

本 skill の各実行は **独立した branch + worktree** で隔離する。
冒頭で `start-stage-branch` skill を args=`<stage>/<skill-name>` で invoke する。

- `service-discovery` の場合: `start-stage-branch s1/service-discovery`
- helper が推奨 branch 名・base (`origin/main`)・重複 suffix を解決し、ユーザー承認を取って `wt switch --create` する。
- 詳細は shared/skills/start-stage-branch/SKILL.md（ADR-0005）参照。
```

**B. 末尾「完了時の PR 作成」セクションを「破壊的操作の禁止」直後に追加:**

```markdown
## PR 作成（skill 完了時）

完全性ガードで全項目を ✅/➖/⚠️ に決着させ、ゲートレポートを提示した直後に、
`finish-stage-pr` skill を以下の args で invoke する:

- title: `<conv-commit-prefix>(<stage>): <skill-name> 完了 (<service-slug>)`
  - 例: `feat(s1): service-discovery 完了 (socialcoffeenote)`
- stage: `<stage>` (例: `s1`)
- label: `indie-studio`, `<stage>`
- ⚠️ 残数: ゲートレポートから引用
- gate report 要約: ✅/➖/⚠️ 件数と繰り越し論点

⚠️ が残れば draft PR、⚠️=0 なら ready PR。
詳細は shared/skills/finish-stage-pr/SKILL.md（ADR-0005）参照。
```

**C. 「破壊的操作の禁止」セクションを書き換え:**

旧:
```
- push / PR / merge / 課金 / 外部送信はしない。repo へのファイル書き込みと commit に留める。
```

新:
```
- 本 skill 末尾の `finish-stage-pr` 経由でのみ push + PR open を行う（ADR-0031）。
- merge / 課金 / 外部送信はしない。
- アンカー / 上流成果物は決め直さない（既存規律）。
```

**skill 固有の調整:**

- **design-direction (S1b)**: 視覚確認ゲートで「戻る」を選んだ場合は `finish-stage-pr` を呼ばず、token 修正 + mock 再生成ループへ。OK 後にのみ PR 作成
- **decomposition (S4)**: G4 起票承認後の Linear 起票完了をもって「完全性ガード合格」とし、index.md commit + PR 作成
- **tech-design (S3)**: G3 スコアカードに B/C が残れば ⚠️ としてカウント → draft PR
- **implementation (S5)**: §4.2 で別扱い

### 4.2 stage マップ表

`indie-studio/AGENTS.md` に追記する（各 SKILL.md からは指さない）。

| skill | stage | branch 名 |
|---|---|---|
| service-discovery | s1 | `s1/service-discovery` |
| stack-direction | s1a | `s1a/stack-direction` |
| design-direction | s1b | `s1b/design-direction` |
| tech-design | s3 | `s3/tech-design` |
| decomposition | s4 | `s4/decomposition` |
| implementation | s5 | `s5/implementation`（親） |

### 4.3 implementation (S5) の親子 PR 構造

**判断: Flat tracking pattern**（stacked PR は不採用）

```
親 branch:  s5/implementation                  <- start-stage-branch で作成
├─ 子 branch: s5/implementation/S-01             <- 1 スライス開始時に作成
│   └─ 子 PR: S-01 -> main                       <- ready / 自動 or 人間 merge (ADR-0008)
├─ 子 branch: s5/implementation/S-02
│   └─ 子 PR: S-02 -> main
└─ 子 branch: s5/implementation/S-03
    └─ 子 PR: S-03 -> main

親 PR:  s5/implementation -> main (draft, tracking)
  body: 子 PR のチェックリスト
  state: 全子 PR マージ後に手動 close（または GitHub Action で自動）
```

**stacked PR を不採用とする根拠:**

| 観点 | stacked (子→親→main) | **flat (子→main, 親=tracking)** |
|---|---|---|
| ADR-0008 適応 PR ゲート整合 | 子 PR の自動 merge 判断が親経由で複雑化 | **子 PR 単位で自動/人間 merge 判断（既存通り）** |
| 中間 branch 状態管理 | 親 branch を rebase する場面が頻発 | **親 branch は変化せず、tracking 表示用** |
| 既存 implementation 動作 | 子 PR の base を親 branch に変える破壊変更 | **base は main のまま（既存維持）** |
| 親 PR の存在意義 | 全 epic を一括 merge | **進捗 dashboard 兼 close 単位** |

**implementation skill の改修詳細:**

```markdown
## ブランチ作成（skill 開始時）

冒頭で `start-stage-branch s5/implementation` を invoke し親 branch を作成。
親 PR は「最初の子 PR 作成直後」に draft で作成する。

## 子 branch / 子 PR（既存維持）

束ね親 (capability) 単位で起動した開発職種が、各スライスごとに:
- `git switch -c s5/implementation/S-<nn>` (親 branch から派生)
- 実装 + テスト + 評価3観点（既存）
- ディレクター (= skill 本体) が子 PR を `gh pr create --base main --head s5/implementation/S-<nn>`

## 親 PR（新規・draft tracking）

最初の子 PR 作成直後に親 PR を draft で作成:
- title: `feat(s5): implementation epic (<service-slug>)`
- body: 子 PR のチェックリスト (`- [ ] S-01 #123` / `- [x] S-02 #124 merged`)
- state: 常時 draft

子 PR 状態が変わるたびに親 PR body を `gh pr edit --body ...` で更新。
全子 PR マージ後、skill 終了時に親 PR を手動 close（ユーザー 1 問確認）。
```

`finish-stage-pr` invoke は「skill 終了時」= 全スライス完了時。親 PR を ready にせず close する選択肢を提示する。

### 4.4 失敗系・例外系（collection レベル）

| 状況 | 挙動 |
|---|---|
| 同一 stage を 2 回目に走らせる | `start-stage-branch` が `s1/service-discovery` 既存検出 → `s1/service-discovery-2` を提案。既存 branch は残す（人間が `wt remove` か git で消す判断） |
| skill 途中で中断 (Ctrl-C / セッション終了) | branch は残ったまま、PR は作成されない。再開時は `wt-start` で同 branch を再 attach、または skill 再 invoke で `-2` 新規作成 |
| 完了前に PR を出したくない | 完全性ガードが ⚠️ 残数 > 0 → 自動で draft PR、人間レビューで「進める or 戻る」判断。明示 `--no-pr` フラグ追加は次回拡張 |
| commit が 0 件で完了（空 PR） | `finish-stage-pr` が `git log origin/main..HEAD --oneline` 0 件で中断、PR 作らず branch も残さない |
| dirty working tree のまま finish 到達 | helper が拒否、呼び出し側 SKILL.md に「最後の commit 漏れ確認」を明記 |

## 5. テスト戦略

### PR1（vendoring 拡張）

- **ローカル sync**: `make sync COLLECTION=indie-studio` を実行し、`indie-studio/skills/{start-stage-branch,finish-stage-pr}/SKILL.md` が generated されること、`x-*` frontmatter が埋まることを確認
- **drift 検知**:
  - shared/ 側を一字変更 → `make verify` が `Drifted: ...` を報告
  - dst 側を手編集 → `make verify` が `Edited: ...` を報告
- **CI**: 既存 verify ワークフローが skills も検知するか確認（agents と同型のロジックなのでパスする想定）

### PR2（indie-studio 適用）

- **scripted check**: `grep -L "start-stage-branch" indie-studio/skills/*/SKILL.md` が空（全 skill が helper invoke を含む）ことを確認
- **目視確認**: 改修パターン（冒頭 + 末尾 + 禁止セクション）が全 6 に同型適用されているか PR diff で確認
- **シナリオテスト**（任意・別 PR でも可）: テスト用 service repo (`/tmp/test-service`) で `service-discovery` を起動し、`s1/service-discovery` が切られ、終了時に draft PR が作成されることを手動確認
- **CI**: `make verify` がパスする（generated SKILL.md の drift 検知）

## 6. リリース順序

```
PR1 (claude-collections): shared/skills/ vendoring 拡張
  - docs/adr/0005-shared-skills-vendoring.md (新規)
  - scripts/sync-shared.sh (修正)
  - shared/skills/start-stage-branch/SKILL.md (新規)
  - shared/skills/finish-stage-pr/SKILL.md (新規)
  - AGENTS.md (root) shared/ 規約に skills 追記
  - 動作確認: ローカルで sync/verify/status
  → main へ merge

PR2 (claude-collections): indie-studio 適用
  - PR1 マージ後に rebase
  - indie-studio/docs/adr/0031-skill-branch-pr-flow.md (新規)
  - indie-studio/.claude-plugin/dependencies.json に shared.skills 追加
  - make sync COLLECTION=indie-studio で generated 2 SKILL.md
  - indie-studio/skills/{service-discovery,stack-direction,design-direction,tech-design,decomposition,implementation}/SKILL.md (改修)
  - indie-studio/AGENTS.md に stage マップ表追記
  → main へ merge
```

## 7. migration

本 spec の改修対象は indie-studio skill の起動時挙動。現時点で indie-studio skill を service repo で運用しているユーザーは想定上ほぼいないため、専用の migration ステップは設けない。改修後の skill を起動した時点で `start-stage-branch` が新規 branch を提案する流れに自然遷移する。

## 8. 関連 ADR

**root の ADR (`docs/adr/`)**:
- ADR-0001（複数コレクション）・ADR-0003（plugin marketplace 配布）・ADR-0004（shared/agents/ vendoring）— 前提
- ADR-0005（**本 spec が起稿前提**）— shared/skills/ vendoring

**indie-studio の ADR (`indie-studio/docs/adr/`)**:
- ADR-0004（自走設計）・ADR-0007（5 大枠ゲート）・ADR-0008（適応 PR ゲート）— 整合対象（特に「破壊的操作の禁止」緩和の根拠）
- ADR-0011〜0030（harness 各種：stage 構成・ロスター・評価ループ・出力レイアウト等）— 既存 SKILL.md 改修時に整合確認
- ADR-0031（**本 spec が起稿前提**）— indie-studio skill branch + PR ライフサイクル

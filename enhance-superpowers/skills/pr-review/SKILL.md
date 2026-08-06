---
name: pr-review
description: |
  **レビュワー側**の起点 skill (ADR-0017)。他人の PR を受け取る側の作業を扱う
  (既存 5 skill は全て implementer 側 = 自分が書いたコードの Spec を起こす方向で、向きが逆)。
  PR 番号を引数に取り、差分を読んで summary.md (レビュー対象の把握) と
  gwt.md (レビュワー自身の理解で動作確認する土台) を生成する。
  2 file を crit で人間レビュー (行単位コメント) にかけ、承認後に herdr の子セッション 2 本を
  同一 worktree・タブ 2 枚で並走起動する — 3-1 gwt.md による agent-browser 動作確認 /
  3-2 AI コードレビュー。親は両者を巡回して join し review-report.md に統合する。
  成果物は**発動元リポジトリ**に置き、レビュー対象 worktree にはコミットしない
  (他人の PR ブランチを汚さないため、ADR-0017 D4)。
  Step 0 で状態判定 (ADR-0012)、Step 1 で .ai-restrictions.md を Read (ADR-0010)。
argument-hint: "<pr-number> [--output-dir=<path>]  # PR 番号は必須 (例: 123 / PR URL)。--output-dir は成果物の配置先 (省略時は発動元リポジトリの docs/superpowers/pr-{N}/)"
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

# pr-review

**自分がレビュワーのとき**に呼ぶ skill。レビュー対象コードを把握し (summary)、自分の理解で動作確認する土台を作り (gwt)、人間レビューを挟んでから、動作確認とコードレビューを子セッション 2 本で並走させる。

既存 5 skill との向きの違いを最初に押さえること — `enhance-brainstorming` 以下は「自分が書くコードの Spec を先に決める」implementer 側。本 skill は「他人が書いたコードを後から理解する」レビュワー側で、gwt.md の出所が逆になる (Spec から導出するのでなく、実装差分から逆算する)。

## 引数

| 引数 | 必須 | 既定 | 効果 |
|---|---|---|---|
| `<pr-number>` | **必須** | — | レビュー対象 PR。番号 (`123`) または PR URL。省略時は error 中断 |
| `--output-dir=<path>` | 任意 | 発動元リポジトリの `docs/superpowers/pr-{N}/` | 成果物 (summary / gwt / review-report) の配置先。**Step 0 の状態判定もこのディレクトリを走査する** |

以降 `{出力先}` は「`--output-dir` 指定時はその値、省略時は発動元リポジトリの `docs/superpowers/pr-{N}/`」を指す。命名規約は `{YYYY-MM-DD}-pr{N}-{suffix}.md`。

**`{出力先}` はレビュー対象 worktree ではなく発動元リポジトリに置く** (ADR-0017 D4)。理由は 2 つ — レビュー用 worktree は使い捨てなので成果物を置くと片付けと同時に消える、他人の PR ブランチにレビューメモをコミットする事故を構造的に防ぐ。**生成物は commit しない** (untracked のまま残す)。

## Phase 定義 (ADR-0012 D3)

| Phase | 前提 | 出力 | 出力条件 |
|---|---|---|---|
| 0 | `{出力先}` (作成 or 既存) | (判定) | 状態判定完了、Step 番号を確定 |
| 1 | PR 番号 | レビュー worktree + workspace | `herdr worktree create` 成功 |
| 2 | PR 差分 | `{date}-pr{N}-summary.md` | shared:software-architect dispatch 完了 |
| 3 | summary.md | `{date}-pr{N}-gwt.md` | shared:qa-engineer dispatch 完了 |
| 4 | summary + gwt | 2 file の human 反映版 | crit の unresolved コメントが 0 + user 承認 |
| 5 | 承認済み gwt + worktree | 子セッション 2 本 (verify / review) | 両 agent の `agent start` 成功 |
| 6 | 子 2 本の結果 | `{date}-pr{N}-review-report.md` | 両者 join 完了 |

## 動作 (7 ステップ)

### Step 0: 状態判定 (ADR-0012 D2)

1. **`{出力先}` を確定**: `--output-dir` があればその値、無ければ発動元リポジトリの `git rev-parse --show-toplevel` + `docs/superpowers/pr-{N}/`
2. `{出力先}` を Glob で列挙し、存在する file から Phase を判定:
   - 何も無い → Step 1 (worktree 作成) から
   - `*-summary.md` のみ → Step 3 (gwt 生成) から
   - `*-summary.md` + `*-gwt.md` あり、crit 未実施 → Step 4 (crit) から
   - 上記 + gwt.md の checklist に `- [x]` が 1 つ以上 → 子セッション起動済みの可能性。Step 5 の重複起動チェックへ
   - `*-review-report.md` あり → Step 6 (join / 再 join) から
3. **子セッションの生存確認**: `herdr agent list` で `pr{N}-verify` / `pr{N}-review` の有無を確認。存在すれば Step 6 (巡回 join) に直行し、**重複起動しない**
4. 判定結果を user に「現在 Phase = X、Step Y から再開します」と明示、user 1 問確認

### Step 1: 前提確認 + レビュー worktree 作成

1. **herdr 前提チェック**: `test "${HERDR_ENV:-}" = 1`。false なら error 中断 ("herdr の外では子セッションを起動できません")
2. `git rev-parse --show-toplevel` で発動元リポジトリを確定 (以降 `{repo-root}`)
3. 発動元リポジトリの `.ai-restrictions.md` を Read (存在すれば user に案内、ADR-0010)
4. PR メタ情報を取得:
   ```sh
   gh pr view <N> --json number,title,body,author,headRefName,baseRefName,files,url
   ```
   失敗 (auth 切れ / PR 不在) なら **そこで中断**。推測した PR 内容で worktree を作ると後から全部やり直しになる
5. PR head を fetch してレビュー用ブランチを起こす (**fork PR でも動く形にする**):
   ```sh
   git -C {repo-root} fetch origin pull/<N>/head
   ```
6. herdr で worktree + workspace を作る (**PR 作者のブランチ名は使わず `review/pr-<N>` を切る** — 作者側ブランチを直接 checkout すると、レビュー中の実験的コミットが混ざる事故が起きる):
   ```sh
   herdr worktree create \
     --cwd {repo-root} \
     --branch review/pr-<N> \
     --base FETCH_HEAD \
     --label pr<N> \
     --no-focus --json
   ```
7. JSON から `.result.workspace.workspace_id` と `.result.root_pane.pane_id` を取得し控える。**ID は不透明文字列なので必ず JSON から読む** (自分で組み立てない)
8. 以降 worktree の checkout path を `{review-worktree}` とする

### Step 2: summary.md 生成 (レビュー対象の把握)

1. PR 差分を読む:
   ```sh
   git -C {review-worktree} diff origin/{baseRefName}...HEAD
   ```
   差分が大きい場合は `--stat` で全体像を掴んでからファイル単位で読む
2. `enhance-superpowers/templates/summary.md` を下敷きに `{出力先}/{date}-pr{N}-summary.md` を生成。**レビュワー視点で埋める** — 「この PR が何を実現しようとしているか」「どの方式を採ったか」「効いている設計判断」「レビューで確認すべき点」
   - **frontmatter を差し替える**: テンプレの `spec: ./...-spec.md` はレビュワー側に存在しないので**削除**し、代わりに `pr: {pr-url}` / `author: {PR 作者}` を置く。`issue:` は PR 本文が参照する issue があればその URL、無ければ削除する (dangling 参照を残さない)
3. **`shared:software-architect` を能動 dispatch** — 差分から読み取った設計意図が妥当か、見落とした構造変更が無いかを review
4. dispatch log を summary.md の「## レビュー履歴」に追記 (ADR-0007)

### Step 3: gwt.md 生成 (動作確認の土台)

1. summary.md を元に、**レビュワー自身が実物で確かめたいこと**を AC (Given-When-Then) に落とす。`enhance-superpowers/templates/gwt.md` が下敷き。frontmatter は summary.md と同じ要領で `spec:` を削り `pr:` に差し替える
2. AC は PR の受入条件のコピーではなく、**レビュワーの理解が正しいかを反証する形**で書く (「作者の主張どおり動くか」でなく「自分の理解どおり動くか」)
3. **`shared:qa-engineer` を能動 dispatch** — AC 網羅性 (異常系 / 境界値 / 空状態 / 既存機能への回帰) の review
4. dispatch log を gwt.md の「## レビュー履歴」に追記 (ADR-0007)

### Step 4: crit で人間レビュー (承認ゲート)

**ここが本 skill 唯一の承認ゲート。** summary の理解がズレたまま子セッションを走らせると、2 本分の作業がまるごと無駄になる。

1. crit を起動して 2 file を人間レビューにかける:
   ```sh
   crit {出力先}/{date}-pr{N}-summary.md {出力先}/{date}-pr{N}-gwt.md
   ```
2. user に「summary と gwt を crit で確認してください。行単位でコメントを付けられます」と案内し、**完了の合図を待つ**
3. コメントを読み戻す:
   ```sh
   crit comments --json
   ```
4. 各コメントを summary.md / gwt.md に反映する。**採用/Skip の 2 値で判定し、Skip は理由を 1 行残す** (`write-review-response` の判定様式に揃える)
5. 反映後に再度 `crit comments --json` で unresolved が 0 になったことを確認
6. user に最終承認を 1 問確認 → yes で Step 5、no なら 3 に戻る

### Step 5: 子セッション 2 本を並走起動

Step 1 で作った workspace に**タブ 2 枚**を追加し、それぞれに Claude を立てる (ADR-0017 D3: 同一 worktree 共有)。

**5-1. タブを 2 枚作る**

```sh
herdr tab create --workspace <workspace_id> --cwd {review-worktree} --label "pr<N>-verify" --no-focus --json
herdr tab create --workspace <workspace_id> --cwd {review-worktree} --label "pr<N>-review" --no-focus --json
```

各 JSON から `pane_id` を取得する。

**5-2. agent を起動する**

```sh
herdr agent start pr<N>-verify --kind claude --pane <verify_pane_id>
herdr agent start pr<N>-review --kind claude --pane <review_pane_id>
```

agent 名は **小文字始まり・`[a-z0-9_-]` のみ・1〜32 文字**。`invalid_agent_name` で落ちたら大文字か記号が混じっている。

**5-3. セッション名を固定する** (本命プロンプトより先に送る)

```sh
herdr agent prompt pr<N>-verify "/rename pr<N>-verify"
herdr agent prompt pr<N>-review "/rename pr<N>-review"
```

Claude Code はセッション名未設定だと直近の作業を要約したタイトルを出し続け、サイドバー上で 2 本の区別が付かなくなる。

**5-4. 初回プロンプトを投入する** (`--wait` は付けない — 親が直列化して並走が成立しなくなる)

子は PR の文脈を一切持っていないので、**プロンプトだけで作業を始められる自己完結な形にする**。`based on your findings` のような理解責任の再委譲は書かない。

`pr<N>-verify` へ:
```
PR #<N> (<title>) の動作確認を担当してください。

レビュー対象: {review-worktree} (branch review/pr-<N>、base は <baseRefName>)
検証手順書:   {出力先}/{date}-pr{N}-gwt.md (絶対パス)

1. gwt.md の AC を読む
2. README から dev server / docker の起動コマンドを把握して**あなたが起動する**
   (起動前に lsof -i :<port> / docker ps で重複確認。重複時は停止せず私に確認を出す)
3. agent-browser skill で各 AC を実機検証する
   agent-browser のスコープ外 (Network 計測 / Lighthouse 等) は chrome-devtools-mcp を私に 1 問確認
   独自の headless browser (playwright / puppeteer) は立てない
4. 満たした AC は gwt.md のチェックリストを - [ ] → - [x] に書き換える
5. 未達 AC は gwt.md の「## 変更履歴」に {日付}: {対象AC} — {観測した挙動} を追記する
6. 終わったら**必ず** dev server / docker を停止する (放置禁止)

コードは修正しないこと。観測結果だけを残してください。
全 AC の検証が終わったら、達成/未達の件数と未達の内訳を 5 行以内で報告して停止してください。
```

`pr<N>-review` へ:
```
PR #<N> (<title>) のコードレビューを担当してください。

レビュー対象: {review-worktree} (branch review/pr-<N>)
差分:         git -C {review-worktree} diff origin/<baseRefName>...HEAD
背景の把握:   {出力先}/{date}-pr{N}-summary.md (絶対パス、レビュワーが書いた理解メモ)

1. summary.md を読んで PR の狙いを掴む
2. 差分をレビューする。観点は 受入条件充足 / テスト網羅 / 可読性 / 既存規約との整合 / 設計の一貫性
3. shared:implementation-reviewer を能動 dispatch してコードレビュー本体を受ける
   (ローカル diff のレビュー宛先。この agent は Bash を持つのでテスト / 型 / lint を再実行できる)
4. shared:security-engineer を能動 dispatch してセキュリティ観点のレビューを 1 回受ける
5. 所見を {出力先}/{date}-pr{N}-review-report.md に書く
   各所見は 重要度 (must / should / nit) / 該当 file:line / 何が問題か / なぜ問題か の 4 点を揃える

CodeRabbit / code-review 系 skill はローカルでは呼ばないこと。

ファイルは一切修正しないこと (このセッションはレビュー専任です)。
git のコミット・push もしないこと (同じ worktree をもう 1 セッションが使っています)。
書き終えたら所見の件数を重要度別に 3 行以内で報告して停止してください。
```

**5-5. 制御を返す**

起動したものを報告して、親は待たない。

### Step 6: 巡回して join

1. `herdr agent list` で `pr<N>-verify` / `pr<N>-review` の `agent_status` を確認。**発動元リポジトリの workspace に絞る** (`herdr worktree list --cwd {repo-root} --json` の `open_workspace_id` 集合)
2. `blocked` / `done` のものだけ `herdr agent read <name> --source recent-unwrapped --lines 120` で読む。`working` は読まない (途中出力は意味を成さずトークンだけ食う)
3. `blocked` への回答:
   - リポジトリの規約や既存コードを見れば決まること → 親が調べて `herdr agent prompt` で回答
   - 仕様・優先度・破壊的変更の可否 → user に 1 問ずつ確認してから回答
   - 2 本同時に blocked なら **1 件ずつ順に**片付ける (まとめて聞くと回答の取り違えが起きる)
4. 両方 `done` になったら join:
   - `{出力先}/{date}-pr{N}-review-report.md` に、コードレビュー所見 (子 3-2 が記載済み) と**動作確認結果 (子 3-1 の gwt.md checklist)** を統合
   - 動作確認で未達だった AC は「コードレビュー所見と突き合わせて原因が説明できるか」を親が判断し、説明できない未達は `must` 所見として追記する
5. user に統合報告を提示 (重要度別の所見件数 / AC 達成率 / 未達の内訳)
6. 子セッションと worktree の片付けは **user に 1 問確認してから** 行う (`herdr workspace close` / `herdr worktree remove`)。未コミット変更の有無を数えてから聞くこと

## 規律明示

- **agent の `subagent_type` は `plugin:agent` 形式の修飾名を使う** (例: `shared:qa-engineer`)。bare name は解決されない (root ADR-0010)
- Step 0 状態判定で再開可能な skill 設計 (ADR-0012 D2)、Phase 定義 table を再開判定の仕様源 (ADR-0012 D3)
- **子セッション起動前に必ず `herdr agent list` で重複確認**。二重起動すると同じ worktree で dev server が競合する
- **成果物は発動元リポジトリに置き commit しない** (他人の PR ブランチを汚さない、ADR-0017 D4)
- **子 2 本は同一 worktree を共有する** (ADR-0017 D3)。成立条件は「両者ともコードを書かない」こと — verify は gwt.md のみ、review は review-report.md のみを書く。この分離が崩れると index.lock 競合が起きるので、子プロンプトで明示的に禁じている
- crit の人間レビューは**唯一の承認ゲート**。ここを飛ばして子を起動しない (2 本分の作業が無駄になる)
- 子への初回プロンプトは自己完結にする。理解責任を子へ再委譲しない
- `--wait` を使わない。完了は Step 6 の巡回で拾う
- dev server / docker の起動・停止責任は `pr<N>-verify` 側に閉じる (親も review 側も触らない)
- Step 1 で AI 利用ポリシー (`.ai-restrictions.md`) を Read して案内 (ADR-0010)
- dispatch log を summary.md / gwt.md / review-report.md のレビュー履歴セクションに追記 (ADR-0007)
- **ローカル diff のコードレビュー宛先は `shared:implementation-reviewer`** (ADR-0016 D1 / ADR-0017 D6)。**ローカルで CodeRabbit / `code-review` 系 skill は呼ばない**

## 失敗時の挙動

| 状況 | 挙動 |
|---|---|
| `HERDR_ENV` が 1 でない | error 報告 + 中断 ("herdr の外では子セッションを起動できません") |
| PR 番号が未指定 | error 報告 + 中断 (引数必須) |
| `gh pr view` が失敗 (auth 切れ / PR 不在) | error 報告 + 中断。推測した PR 内容で進めない |
| `review/pr-<N>` が既存 | 既にレビュー中の可能性。`herdr worktree list` / `herdr agent list` で既存セッションを探し、合流するか作り直すかを 1 問確認 |
| `herdr agent start` が `invalid_agent_name` | 大文字 / 記号混入。小文字化して再実行 |
| `herdr agent start` がタイムアウト | pane はできている。`herdr agent explain` で検出状態を提示し、手動で claude 起動する選択肢を出す |
| crit にコメントが 0 件 | 「指摘なしで承認」とみなしてよいか 1 問確認 (crit を開かずに閉じた事故と区別できないため) |
| 子が `blocked` のまま進まない | Step 6 の巡回で読んで回答。仕様判断は user に 1 問確認 |
| 片方の子だけ `done` | 片方だけで join しない。残りを巡回で待つ。待てない事情があれば user に 1 問確認して部分 join |
| 動作確認で AC 未達 | review-report.md に `must` 所見として記載。**実装への差し戻しは行わない** (レビュワー側 skill なので修正は PR 作者の責務) |

## 関連

- ADR-0017 (reviewer-side-skill-and-parallel-sessions) — 本 skill の決定
- ADR-0016 (local-review-to-implementation-reviewer-and-builtin-review-after-pr) — レビュー宛先の phase routing。子 `pr<N>-review` の dispatch 先はこれに従う
- ADR-0007 (audit-trail-dispatch-log) — レビュー履歴セクション
- ADR-0010 (ai-utilization-policy-loading) — Step 1 の `.ai-restrictions.md`
- ADR-0012 (implementation-phase-skill-and-state-detection) — Step 0 状態判定 / Phase 定義 table
- ADR-0014 (output-dir-arg-chain-suppression-gate-aggregation) — `--output-dir` の語彙
- gwt-test SKILL.md (implementer 側の AC 検証 skill。gwt.md の出所が逆になる点で対になる)
- write-review-response SKILL.md (レビューを**受ける**側。本 skill と向きが逆なので混同しないこと)

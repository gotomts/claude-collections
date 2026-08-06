---
name: finish-spec-pr
description: |
  Spec フェーズで作成済みの pr-description.md を body として、`shared:finish-stage-pr` を
  body-source-path 指定で呼んで PR 作成する skill。enhance-brainstorming Phase 6 で生成された
  pr-description.md (`## やったこと` / `## 補足` / `## 動作確認方法` の 3 セクション) を整え、
  title を user に 1 問確認、finish-stage-pr の Step 8 でユーザー最終確認 → push + gh pr create。
  PR 作成後に Step 6 で builtin /review を invoke し、指摘があれば user 1 問確認のうえ
  write-review-response へ折り返す (ADR-0016 D2)。
  Step 1 で .ai-restrictions.md を Read (ADR-0010)。
  引数 --output-dir で出力先を制御 (省略時は従来挙動、ADR-0014)。
argument-hint: "[pr-description-path] [--output-dir=<path>]  # pr-description.md のパス (省略時は出力先から自動検出)。引数は外部 collection 利用向け、省略時は従来挙動 (ADR-0014)"
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

## 引数 (ADR-0014)

任意。**省略時は従来挙動と完全に同一**。

| 引数 | 既定 | 効果 |
|---|---|---|
| `--output-dir=<path>` | `docs/superpowers/{branch}/` | 成果物の所在。Step 0 の状態判定と pr-description.md の自動検出先になる |

以降の `{出力先}` は「`--output-dir` 指定時はその値、省略時は `docs/superpowers/{branch}/`」を指す。

## Phase 定義 (ADR-0012 D3)

| Phase | 前提 file | 出力 | 出力条件 |
|---|---|---|---|
| 0 | `{出力先}/*-pr-description.md` 存在 + `review-response.md` 存在 (優先) | (判定) | 状態判定完了、Step 番号を確定 |
| 整え | pr-description.md | 実装結果に整えた pr-description.md | `## やったこと` が実装 diff と揃う (user 確認済) |
| 作成 | pr-description.md + 未 push commit | GitHub PR | `shared:finish-stage-pr` で作成完了 |
| PR レビュー | 作成済み PR | `/review` 出力 + user 判断 | `/review` invoke 完了、指摘があれば折り返し要否を user が決定 (ADR-0016 D2) |

## 動作 (8 ステップ)

### Step 0: 状態判定 (ADR-0012 D2)

1. **`{出力先}` を確定**: `--output-dir` があればその値、無ければ `git rev-parse --abbrev-ref HEAD` → サニタイズ (`/` → `-`) → `docs/superpowers/{branch}/`
2. `{出力先}` を Glob で列挙、`*-pr-description.md` / `*-review-response.md` の存在有無を確認
3. **明示引数を優先**: `pr-description-path` が渡されていればそれを採用し、glob 探索より優先する。
4. **前提**: (明示引数が無い場合) pr-description.md が存在すること (Spec フェーズ完了)。無ければ error "pr-description.md がありません。enhance-brainstorming Phase 3 を完了させてください" + 中断
5. **前提**: `git branch --show-current` が `main` でないこと。main なら error "main 直作業では PR を出せません" + 中断
6. review-response.md 存在 = レビュー対応まで完了、pr-description.md「## やったこと」が実装 diff と齟齬ないかを判定に含める
7. 既存 PR check: `gh pr list --head <current-branch>` で同 branch の open PR が既にあるか確認 (あれば「既存 PR に上書き push だけで良いか、新規 PR 作成か」を user に 1 問確認)
8. `handoff.md` が同ディレクトリにあれば Read (補助情報)
9. 判定結果を user に「現在 Phase = X、Step Y から再開します」と明示、user 1 問確認

### Step 1: 前提確認 + pr-description.md 読み込み + AI 利用ポリシー案内 (ADR-0010)

1. `git rev-parse --show-toplevel` で git repo 確認
2. `git branch --show-current` で現ブランチ取得、main 直作業を拒否 ("main 直作業では PR を出せません")
3. argument 経由 or `{出力先}/*-pr-description.md` から自動検出
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

### Step 5: `shared:finish-stage-pr` を body-source-path 指定で invoke

1. `Skill` tool で `shared:finish-stage-pr` を invoke、argument に title + body-source-path を渡す:
   ```
   <title-confirmed> {absolute path to pr-description.md}
   ```
2. finish-stage-pr の Step 1-7 が実行される (環境チェック / 未 commit 確認 / base 解決 / 既存 PR チェック / draft/ready 判定 / body 読み込み)
3. finish-stage-pr の Step 8 (PR 作成最終確認) で user に title / base / state / labels を提示 → ユーザー最終確認 → yes なら Step 9-11 (label 確認 / push / gh pr create)

### Step 6: PR レビュー = builtin `/review` を invoke (ADR-0016 D2)

PR が存在するのはこのフェーズだけなので、PR を対象にするレビューはここで回す。

> **前提: `/review` は cwd のリポジトリで PR 番号を解決する。** 別リポジトリの checkout から invoke すると同じ番号の別 PR を読む。本 skill は PR を作った worktree で走るため条件を満たすが、Step 6-1 で明示的に検証する。

1. Step 5 の出力から PR 番号 / URL を取得する。**`gh repo view --json nameWithOwner` が PR URL の `owner/repo` と一致することを確認する**。不一致なら `/review` を skip し、user に「cwd が対象 PR と別リポジトリです」と明示して 6 へ
2. **`Skill` tool で `/review` を invoke**、引数に PR 番号を渡す。`/review` は read-only で、**PR へのコメント post はしない**
3. **CodeRabbit はここでは扱わない** (ADR-0016 D2)。CodeRabbit の PR レビューは作成から数分〜十数分かかるため、Step 5 の直後に走る本 Step では**ほぼ常に未到着**で、「付いていれば読む」は機能しない。CodeRabbit ラウンドは時間が経ってから `write-review-response` を直接 invoke して扱う (同 skill の「PR 後」ラウンド)
4. **`/review` の実行記録を必ず残す** (ADR-0016 D2、指摘 0 件でも user が 5 で no でも省略しない)。`{出力先}/{date}-{slug}-review-response.md` の「## レビュー履歴」に追記する。**file が無ければ「## レビュー履歴」セクションだけを持つ file を新規作成する**:
   - 形式: `- {YYYY-MM-DD HH:MM} - `/review` を finish-spec-pr Step 6 で invoke (対象: PR #N) → 「指摘 {件数} 件{、内訳}」`
   - 「回していない」と「回して 0 件だった」を区別できるようにするのが目的。0 件のときも必ず 1 行書く
   - `/review` を skip した場合 (1 の不一致 / invoke 失敗) も、理由付きで 1 行書く
5. 指摘が 0 件 → Step 7 へ
6. 指摘がある場合、一覧を user に提示して **1 問確認**: 「`/review` で N 件の指摘があります。`write-review-response` で採用 / Skip 判定しますか?」
   - yes → `Skill` tool で `enhance-superpowers:write-review-response` を invoke、review-source として PR URL を渡す (`--output-dir` を受け取っていれば**そのまま引き継いで渡す**)
   - no → 指摘一覧を user に残し、4 の記録に「user 判断で折り返さず終了」を追記して Step 7 へ
7. **自動 chain しない** (ADR-0016 D2)。`write-review-response` → `finish-spec-pr` → `write-review-response` は循環するため、この 1 問確認をループ上限として使う

> **`/review` は人間レビューの代替ではない** (ADR-0016 D4)。AI の自己レビューなので、根幹の変更 (セキュリティ・課金・PII・秘密情報・不可逆マイグレーション・公開 API・インフラ) に対する人間レビューと人間 merge は、`/review` の結果にかかわらず従来どおり必要 (indie-studio ADR-0008)。

### Step 7: 完了報告

1. 作成された PR URL を user に表示 (finish-stage-pr の Step 11 出力)
2. Step 6 の結果 (`/review` 指摘件数、折り返しの有無) を 1 行で添える
3. 「Spec フェーズから PR 作成までの全工程が完了しました。お疲れさまでした」と user に通知

## 規律明示

- Step 1 で AI 利用ポリシー (`.ai-restrictions.md`) を Read して案内 (ADR-0010)
- finish-spec-pr 自体は **agent を dispatch しない**が、Step 6 で builtin `/review` を invoke する (ADR-0016 D2)。**実行記録は本 skill が review-response.md のレビュー履歴に直接書く** (指摘 0 件 / user が折り返さない場合も省略しない)。`pr-description.md` には書かない (ADR-0007 の B 例外 = PR body にそのまま投稿されるため)
- Step 6 の `/review` は read-only。**PR へのコメント post はしない**、`write-review-response` への chain は user 1 問確認を挟む (循環のループ上限)
- Step 6 は **CodeRabbit を扱わない**。PR 作成直後は未到着のため、CodeRabbit ラウンドは `write-review-response` の直接 invoke に委ねる (ADR-0016 D2)
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
| Step 6 で `/review` が invoke できない (未提供 / 失敗) | skip して user に「`/review` を実行できませんでした (理由)。PR 上で手動レビューしてください」と明示し、**skip した事実と理由を review-response.md のレビュー履歴に記録**して Step 7 へ進む (PR 作成自体は成功しているため中断しない) |
| Step 6 で PR 番号を取得できない | `gh pr list --head <current-branch> --json number` で再取得。それでも取れなければ `/review` を skip して (記録は残して) Step 7 へ |
| Step 6-1 で cwd と PR のリポジトリが不一致 | `/review` を skip。同じ番号の別リポ PR を読む事故を防ぐ。理由を記録して Step 7 へ |
| Step 6-4 で review-response.md が存在しない | 「## レビュー履歴」セクションのみを持つ file を新規作成して追記する (実行記録を落とさない) |

## 関連

- ADR-0004 (shared-skills-finish-stage-pr-extension)
- ADR-0010 (ai-utilization-policy-loading)
- ADR-0012 (implementation-phase-skill-and-state-detection) — Step 0 状態判定
- ADR-0016 (local-review-to-implementation-reviewer-and-builtin-review-after-pr) — Step 6 で `/review` を invoke (D2)、人間レビューの代替にしない線引き (D4)
- indie-studio ADR-0008 (adaptive-pr-review-gate) — 根幹 PR の人間レビュー / 人間 merge は `/review` の結果によらず必要
- write-review-response SKILL.md (前工程 sub-skill。Step 6 の折り返し先でもある)
- `shared:finish-stage-pr` SKILL.md (本 skill が body-source-path 指定で invoke)

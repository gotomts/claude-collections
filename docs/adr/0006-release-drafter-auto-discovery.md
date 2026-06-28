# 0006. release-drafter の auto-discovery + テンプレ config 化

## Status

Accepted (2026-06-28). ADR-0004 (release-notes-workflow) を extends し、per-collection の drafter 設定を unified 構造に置換する。Revised (2026-06-29): release-drafter@v6 が config を default branch (main) から API 経由で読む制約があるため、当初の「runtime sed render」アプローチは機能せず PR #18 merge 後の workflow が `Invalid config file` で fail。**per-collection config を commit する形に方針転換**: template + 自動再生成スクリプト (`scripts/regen-drafter-configs.sh`) + Makefile target (`regen-drafter-configs` / `verify-drafter-configs`) + CI guard で「再生成忘れ」を構造的に塞ぐ。

## Context

ADR-0004 で導入した release-drafter は **collection ごとに config + workflow を分離** する設計 (`.github/release-drafter-<collection>.yml` + `.github/workflows/release-drafter-<collection>.yml`)。enhance-superpowers コレクション新設時 (PR #15 → #16) に release 判断のタイミングで以下の問題が顕在化:

1. enhance-superpowers の drafter config / workflow を作り忘れていた → enhance-superpowers/v0.0.1 の draft が自動生成されないままだった
2. 既存 indie-studio drafter が `paths:` filter のみで `include-paths:` (drafter 側の PR 内容フィルタ) を持たなかったため、enhance-superpowers 専用 PR (#13/#14/#15) を `indie-studio/v0.0.3` Draft に巻き込んでいた
3. その場対応 (PR #17) で per-collection ファイルを複製しつつ include-paths を両方に追加したが、**コレクション追加時に複製を忘れて同じ事故を繰り返す** リスクが残る

恒久的に「コレクション追加時に drafter 設定の手作業ゼロ」を実現する仕組みが必要。

## Decision

per-collection の drafter ファイルを全廃し、**単一の workflow + 単一のテンプレ config** に統一する。さらに同 workflow で autolabeler も実行する (旧 indie-studio workflow は `push` trigger のみで autolabeler が dead code だった既存バグも併せて修正):

- `.github/workflows/release-drafter.yml` (新規・単一): 2 つの起点を持つ
  - **drafter** (push to main / workflow_dispatch 起点):
    1. `discover` ジョブが top-level dir を走査して `<dir>/.claude-plugin/plugin.json` を持つ dir をコレクションと判定
    2. `draft` ジョブが matrix でコレクション数だけ並列起動
    3. 各 draft ジョブは commit 済み `.github/release-drafter-<collection>.yml` を release-drafter に渡す
  - **autolabeler** (pull_request_target 起点):
    - autolabeler ルールは collection 非依存なので discover 不要
    - 既存の per-collection config (アルファベット順で最初のもの) を `disable-releaser: true` で release-drafter に渡す → drafter 抑制、autolabeler のみ実行
    - pull_request_target は base (main) のコードで実行されるため、PR の HEAD を checkout せず main の commit 済み config を使う (security)
- `scripts/regen-drafter-configs.sh` (新規): top-level の collection 一覧を検出して template の `{{COLLECTION}}` を sed 置換した per-collection config (`.github/release-drafter-<collection>.yml`) を生成。古い collection の config は自動削除。`--check` モードで「再生成後に diff があれば exit 1」(CI 用)
- `Makefile` target: `make regen-drafter-configs` (再生成) / `make verify-drafter-configs` (drift 検証、CI 用)
- 生成済み config の先頭には「GENERATED FILE — DO NOT EDIT」コメントを差し込み、手編集を抑止
- `.github/release-drafter-template.yml` (新規・単一): `name-template` / `tag-template` / `include-paths` / `template` (Full Changelog URL) に `{{COLLECTION}}` を埋め込んだテンプレ
- 既存の per-collection ファイル (`release-drafter-indie-studio.yml` + `release-drafter-enhance-superpowers.yml` + 対応 workflow) を全部削除

`include-paths` には:
- `{{COLLECTION}}/` (collection 配下に触れた PR)
- `shared/skills/finish-stage-pr/` (vendoring 元: collection の動作に影響する shared 変更を捕捉)

を含める (現状は全コレクションが finish-stage-pr を vendoring している前提)。collection 固有の vendoring 構成が分岐したら、本 ADR を extends する形で per-collection override 機構を検討する。

## Consequences

- 新コレクション (`<new>/.claude-plugin/plugin.json` を持つ dir) が main に landed すれば、次の push trigger で drafter が **自動的に** 認識して draft を作る。**drafter 設定の手作業ゼロ**
- per-collection の drafter ファイルが消えるので、PR review で見るファイル数が減る、設定漏れによる release 事故が構造的に発生しない
- テンプレ config の変更は全コレクションに即時波及する → 1 コレクション固有の挙動を変えたい時は本 ADR の override 機構を起こす必要あり (現状不要)
- discover ジョブが repo top-level の dir scan を行うため、誤って `.claude-plugin/plugin.json` を非コレクション dir (例: テンプレ用 fixture) に置くと drafter が動いてしまう → 実害は少ない (誤った dir で draft tag が作られるだけ、削除可) が、将来 sample/skeleton dir を導入する時は notes:
  - top-level に置かない or
  - skeleton 用 plugin.json は別名にする等

## Alternatives Considered

- **per-collection ファイル維持 + CI ガード**: `make verify-collection-coverage` で「コレクション dir に対応する drafter config 無し」を CI で落とす。設定漏れ検知はできるが、落ちた時に手で追加する手間は残る。**今回の問題 (手作業を忘れる) は半分しか解決しない**ため却下
- **scaffold script** (`scripts/add-collection.sh`): 1 コマンドで drafter config を生成。**script を使うこと自体を忘れる** リスクが残るため、上の問題と同じ性質。却下 (補助的に組み合わせる選択はあるが initial で必要なし)
- **release-drafter を捨てて自前ツール**: 過剰投資。release-drafter v6 の include-paths + matrix workflow で十分

## 関連

- ADR-0004 (release-notes-workflow): 本 ADR の親。tag 命名 / publish 判断 / bootstrap の規律は ADR-0004 を継承
- PR #17 (drafter setup): 本 ADR で superseded されるため close 予定
- enhance-superpowers/v0.0.1 (PR #15 + #16) の release 判断時に発覚した問題系列

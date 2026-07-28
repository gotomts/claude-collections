# AGENTS.md（claude-collections リポジトリ・正本）

このリポジトリは**複数のスキル+エージェント集（コレクション）**をホストする（root `docs/adr/0001`）。エージェントが本リポジトリで作業するときの規約を定める。`CLAUDE.md` は本ファイルを参照する薄いポインタ。

## 構成規約

- 各コレクションは `<collection>/` 配下に**自己完結**する：`skills/`・`agents/`・`docs/adr/`・`CONTEXT.md`・`ROADMAP.md`・`.claude-plugin/plugin.json`。
- **例外：`shared/`** は plugin だがコレクションではない（agents/skills の共有基盤・ADR-0009）。`CONTEXT.md` / `ROADMAP.md` / `docs/adr/` は持たず、設計判断は root `docs/adr/` に置く。ただし `.claude-plugin/plugin.json` を持つため release-drafter の auto-discovery には collection として載り、`shared/v0.0.x` の draft/tag を持つ。
- root には repo 横断の `AGENTS.md`（本ファイル）・`CLAUDE.md`（ポインタ）・`CONTEXT-MAP.md`（コレクション索引）・`docs/adr/`（横断決定）・`.claude-plugin/marketplace.json`（plugin marketplace 宣言）。
- コレクション一覧と所在は `CONTEXT-MAP.md`。
- 配布構造（marketplace + 各 plugin）の決定は [`docs/adr/0003`](docs/adr/0003-plugin-marketplace-distribution.md)。

## スキル/エージェントを足す・直すとき

- 該当コレクションの `<collection>/skills/<skill>/SKILL.md` ／ `<collection>/agents/<name>.md` に置く（root 直下に置かない）。
- **エージェントは実在職種名で**設計する（成果物名・概念で割らない）。
- **エージェントの起動は `plugin:agent` 形式の修飾名で行う**（例：`shared:software-architect` / `indie-studio:ux-researcher`）。**bare name は解決されない**。同名 agent を持つ plugin が共存すると片方の agent セットが registry から丸ごと落ちるため、**コレクション間で agent 名を重複させないこと**（ADR-0009）。skill は名前空間が効くのでこの制約を受けない。
- 設計判断は該当コレクションの `docs/adr/` を読む。決定は inline／git／ADR に残す（専用の決定ログ file は作らない）。
- ADR は原則 immutable（決定の根拠を保存するため直接書き換え・削除しない。方針変更は新 ADR で supersede／extends する）。**例外**：decision を伴わない誤記録（非-decision を誤って ADR 化した bug／void な記録）は、痕跡を残さず削除してよい（immutable が守るのは「判断の根拠」であって、判断でないものは保存対象外）。末尾番号を削除した場合は後続 ADR を詰めて連番を保つ。
- **ADR 番号は名前空間ごとに独立している**（root `docs/adr/` と各 `<collection>/docs/adr/` で同じ番号が別物を指す。例：root ADR-0009 = shared plugin 化／enhance-superpowers ADR-0009 = ライセンスチェック／indie-studio ADR-0009 = agents がハーネスのホーム）。したがって**裸の `ADR-000N` は「そのファイルが属する名前空間の ADR」を指す**規約とし、他名前空間を参照するときは必ず修飾する — collection のファイルから root を指すなら `root ADR-000N`、root のファイルから collection を指すなら `indie-studio ADR-000N` のように書く。修飾を怠ると同一ファイル内で同じ番号が 2 つの意味に解決されうる。

## shared plugin（共有エージェント／スキル）

- engineering 系（executor / quality / leadership）の共通エージェント 13 体と helper 系スキル 2 本（start-stage-branch / finish-stage-pr）は、**`shared` plugin が単一の実体として提供する**（ADR-0009）。vendoring（`make sync` による複製）は **廃止**した。
- 各コレクションは `shared` を **install 前提の依存**として扱い、skill 内から `shared:<agent>` / `shared:<skill>` を修飾名で参照する（agent は修飾必須、skill は表記統一のため）。`dependencies.json` は不要（削除済み）。
- `shared/agents/` は **collection 非依存の中立語彙で書く**（ADR-0004 から継承した原則）。collection 固有 context（ステージ番号 / 参照 docs パス / 進行 protocol 等）は呼び出し元 skill が invocation 時に prompt で渡す。
- shared/ を編集すれば全 consumer へ即座に反映される（複製が無いため sync 忘れという失敗モードが存在しない）。
- コレクション固有のエージェント（例：indie-studio の business-strategist 等）は従来通り `<collection>/agents/` に手書きで置く。**shared/ および他コレクションと同名にしないこと**（同名衝突は agent セットの消失を招く・ADR-0009）。

## 既存コレクション

- **`indie-studio`**：個人開発のサービス設計〜デザイン〜開発を自律で回すハーネス。設計の真実源は `indie-studio/CONTEXT.md` と `indie-studio/docs/adr/`。
- **`enhance-superpowers`**：公式 superpowers plugin の直線フロー (brainstorming → writing-plans → executing-plans) に、5 成果物 Spec フェーズ確定 / agent 能動 dispatch / 監査ログ / コンプライアンス trigger を被せた強化版。設計の真実源は `enhance-superpowers/CONTEXT.md` と `enhance-superpowers/docs/adr/`。
- **`shared`**（コレクションではなく共有基盤 plugin）：上記 2 つが依存する中立 agent 13 体 + helper skill 2 本。設計の真実源は root `docs/adr/0009`。リリースノート運用は他と同じく GitHub Releases（tag prefix `shared/v`）に従う。

## リリースノート運用

各コレクションの変更履歴は GitHub Releases に集約する (リポジトリ内 `CHANGELOG.md` ファイルは持たない)。ツールは [release-drafter@v6](https://github.com/release-drafter/release-drafter)、**単一の workflow + テンプレ config** (`.github/workflows/release-drafter.yml` + `.github/release-drafter-template.yml`) で repo top-level を auto-discover して各コレクション専用の draft を作成する。コレクション追加時に drafter 設定の手作業は不要 (`<new>/.claude-plugin/plugin.json` が main に乗れば次の push trigger で drafter が自動認識)。設計判断は [`docs/adr/0004`](docs/adr/0004-release-notes-workflow.md) (ノート運用全体) と [`docs/adr/0006`](docs/adr/0006-release-drafter-auto-discovery.md) (auto-discovery + テンプレ化)。

### tag 命名

- format: `<collection>/v<semver>` (slash 区切り、例: `indie-studio/v0.0.1`)
- テスト期: `v0.0.x` 系で publish、version-resolver は全 patch 固定 (`0.1.0` 自動突入を抑制)
- 安定化フェーズ: `v0.1.0` 以降 semver (ADR-0004 を extends する新 ADR で切り替え)
- **⚠️ 新規コレクションの初回 draft は `v0.1.0` になる。publish 前に `v0.0.1` へ付け替えること。** version-resolver の patch 固定は「**直前のリリースから +1**」する仕組みなので、リリースがまだ 1 つも無い新規コレクションには効かず、release-drafter 組み込みの初期値 `0.1.0` が出る。放置して publish すると以後 `0.1.x` 系に固定され、他コレクションの `0.0.x` と体系がズレる。修正は `gh release edit --repo gotomts/claude-collections <collection>/v0.1.0 --tag <collection>/v0.0.1 --title <collection>/v0.0.1`（draft のうちに直せば git tag は作られていないので副作用なし）。2 回目以降は patch 固定が正しく効く。

### publish 判断 (PR merge 後 trigger)

PR を main に merge した直後の Claude Code セッションで、publish 判断を **必ず実行する**:

1. `gh release list --repo gotomts/claude-collections` で対象 collection の draft を確認
2. `gh release view --repo gotomts/claude-collections <tag-name>` で draft 内容を確認
3. 内容のまとまり (機能完成 / 数 PR 蓄積 / リファクタ完了 / docs まとめ等) を評価し publish 推奨 or 待機を提案
4. ユーザー承認後、`gh release edit --repo gotomts/claude-collections <tag-name> --draft=false` で publish 実行

### Backup 1: セッション開始時の未 publish draft 確認

Claude Code セッション開始時に未 publish draft の有無を確認し、溜まっている場合は publish 判断を proactively 提案する。`gh release list --repo gotomts/claude-collections` で状態確認。

### Backup 2: 月次 draft レビュー

月次で draft 状態を人間がレビューする。詳細は各コレクションの `ROADMAP.md` (例: `indie-studio/docs/ROADMAP.md` の「リリース運用」セクション)。

### 導入 PR の bootstrap

release-drafter は config をデフォルトブランチ (main) から読むため、本ワークフローを導入する PR / 設定追加の PR では autolabeler が動かない。導入 PR は手動で label を付与する (例: `docs` / `chore`)。

## git push の repo-local 例外 (Claude Code)

本リポジトリ内では PreToolUse hook が `git push` の挙動を **authoritative に決定**する:

- 非 force / 非 protected branch (`main` / `master` / `*/main` / `*/master`) の push → `permissionDecision: allow` で auto-run
- `--force` / `--force-with-lease` / `-f` / `--force=…` / refspec 先頭 `+` の force shorthand → `permissionDecision: deny` で **prompt 無しで hard block**
- `main` / `master` / `refs/heads/main` 等の protected branch を target にする push → `permissionDecision: deny` で **prompt 無しで hard block**

deny を選んだのは「prompt を出すと誤クリックで通過する事故が起きうる」ため。意図的に push したいときは hook を一時編集するか、Claude Code 外 (terminal) から実行する。

実装:
- hook logic: `.claude/hooks/allow-safe-push.sh` (committed)
- hook 起動: `.claude/settings.json` (committed) — clone / pull / 新 worktree 作成直後から **自動で有効**
- 他の repo は触らない: user-scope の `~/.claude/settings.local.json` の `Bash(git push *)` deny がそちらの safety net として残る
- `.claude/settings.local.json` は gitignored 設定なので、個人別の override を入れたい場合のみ使う (基本不要)

設計判断: markdown 注意書きだけに頼った時期に事故った経緯から、enforcement は settings/hook で行い AGENTS.md は背景説明に留める。さらに hook を authoritative にして `permissionDecision` を明示することで、user-scope 設定差異 (deny 有無 / syntax 差) に依存しない可搬性を確保する。trust 宣言は `.claude/settings.local.json` でなく `.claude/settings.json` に置いて committed にしたため、clone / 新 worktree で個別 setup 不要 (hook が safety-only な構成—force / protected branch は deny、それ以外は allow—なので他人 clone でも安全側に倒れる)。

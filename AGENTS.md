# AGENTS.md（claude-collections リポジトリ・正本）

このリポジトリは**複数のスキル+エージェント集（コレクション）**をホストする（root `docs/adr/0001`）。エージェントが本リポジトリで作業するときの規約を定める。`CLAUDE.md` は本ファイルを参照する薄いポインタ。

## 構成規約

- 各コレクションは `<collection>/` 配下に**自己完結**する：`skills/`・`agents/`・`docs/adr/`・`CONTEXT.md`・`ROADMAP.md`・`.claude-plugin/plugin.json`。
- root には repo 横断の `AGENTS.md`（本ファイル）・`CLAUDE.md`（ポインタ）・`CONTEXT-MAP.md`（コレクション索引）・`docs/adr/`（横断決定）・`.claude-plugin/marketplace.json`（plugin marketplace 宣言）。
- コレクション一覧と所在は `CONTEXT-MAP.md`。
- 配布構造（marketplace + 各 plugin）の決定は [`docs/adr/0003`](docs/adr/0003-plugin-marketplace-distribution.md)。

## スキル/エージェントを足す・直すとき

- 該当コレクションの `<collection>/skills/<skill>/SKILL.md` ／ `<collection>/agents/<name>.md` に置く（root 直下に置かない）。
- **エージェントは実在職種名で**設計する（成果物名・概念で割らない）。
- スキル/エージェントは frontmatter の `name` で識別・起動される（`subagent_type` も `name` 参照・path 非依存）。ディレクトリを深くしても呼び出しは壊れない。
- 設計判断は該当コレクションの `docs/adr/` を読む。決定は inline／git／ADR に残す（専用の決定ログ file は作らない）。

## shared/ の共有エージェント

- engineering 系（executor / quality / leadership）の共通エージェントは `shared/agents/` を真実源とする（ADR-0004）。
- 各コレクションは `<collection>/.claude-plugin/dependencies.json` の `shared.agents[]` で取り込み宣言する。
- 取り込みの実体化は `make sync COLLECTION=<name>` で指定 collection を sync。`make sync` 単独実行時は TTY なら interactive picker（`fzf` インストール時は矢印キー + fuzzy search、未インストール時は番号入力 fallback）、非 TTY（CI/pipe）なら全 collection を一括 sync。`<collection>/agents/<name>.md` に generated file が書き出される（frontmatter に `x-source` / `x-source-hash` / `x-synced-at` を持つ）。
- generated file は **手編集禁止**。shared 側を編集して `make sync` で反映させる。手編集してしまった場合は `make verify` が `Edited: ...` で検知する（`x-body-hash` で footprint を保持）。
- `make verify` は 2 種類の drift を検知（CI も実行）：(a) shared/ が更新されたが make sync 忘れ → `Drifted: ... (source-hash mismatch)`、(b) dst の body が手編集された → `Edited: ... (body modified)`。手元での確認は `make status`。
- 手編集を取り消す場合は `git checkout <dst>` または `make sync` で master 上書き（master always wins）。残したい変更があれば shared/ 側に移してから `make sync`。
- shared/agents/ の編集 PR では、影響を受ける全 collection の generated を `make sync` で更新してから commit する。CI verify が忘れを構造的に防ぐ。
- コレクション固有のエージェント（例：indie-studio の business-strategist 等）は従来通り `<collection>/agents/` に手書きで置く。shared/ と同名にしないこと。

## shared/ の共有スキル

- helper 系（例：start-stage-branch / finish-stage-pr）の共通スキルは `shared/skills/` を真実源とする（ADR-0005）。
- 各コレクションは `<collection>/.claude-plugin/dependencies.json` の `shared.skills[]` で取り込み宣言する（`shared.agents[]` と同階層・任意フィールド）。
- 取り込みの実体化は `make sync COLLECTION=<name>` で。`<collection>/skills/<name>/SKILL.md` に generated file が書き出される（frontmatter に `x-source` / `x-source-hash` / `x-body-hash` / `x-synced-at` を持つ）。
- generated file は **手編集禁止**。shared 側を編集して `make sync` で反映。
- `make verify` の drift 検知は agents と同型（source-hash mismatch / body modified）。
- 当面 1 skill = 1 SKILL.md（補助ファイルは sync 対象外）。複雑な skill 構成が必要になった時点で本 ADR を拡張。
- コレクション固有のスキルは従来通り `<collection>/skills/` に手書きで置く。shared/ と同名にしないこと（agents と同規律）。

## 既存コレクション

- **`indie-studio`**：個人開発のサービス設計〜デザイン〜開発を自律で回すハーネス。設計の真実源は `indie-studio/CONTEXT.md` と `indie-studio/docs/adr/`。

## リリースノート運用

各コレクションの変更履歴は GitHub Releases に集約する (リポジトリ内 `CHANGELOG.md` ファイルは持たない)。ツールは [release-drafter@v6](https://github.com/release-drafter/release-drafter)、collection 単位に config + workflow を分離 (`.github/release-drafter-<collection>.yml` / `.github/workflows/release-drafter-<collection>.yml`)。設計判断は [`docs/adr/0004`](docs/adr/0004-release-notes-workflow.md)。

### tag 命名

- format: `<collection>/v<semver>` (slash 区切り、例: `indie-studio/v0.0.1`)
- テスト期: `v0.0.x` 系で publish、version-resolver は全 patch 固定 (`0.1.0` 自動突入を抑制)
- 安定化フェーズ: `v0.1.0` 以降 semver (ADR-0004 を extends する新 ADR で切り替え)

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
- `--force` / `--force-with-lease` / `-f` / `--force=…` / refspec 先頭 `+` の force shorthand → `permissionDecision: ask` で都度承認
- `main` / `master` / `refs/heads/main` 等の protected branch を target にする push → `permissionDecision: ask` で都度承認

実装:
- hook logic: `.claude/hooks/allow-safe-push.sh` (committed)
- hook 起動: `.claude/settings.local.json` (gitignored)
- 他の repo は触らない: user-scope の `~/.claude/settings.local.json` の `Bash(git push *)` deny がそちらの safety net として残る

worktree / 別 checkout で有効化したいとき: `.claude/settings.local.json` を以下の内容で作成 (hook script は git 同期されるためコピー不要)

```json
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "hooks": {
    "PreToolUse": [{
      "matcher": "Bash",
      "hooks": [{
        "type": "command",
        "if": "Bash(git push *)",
        "command": "${CLAUDE_PROJECT_DIR}/.claude/hooks/allow-safe-push.sh"
      }]
    }]
  }
}
```

設計判断: markdown 注意書きだけに頼った時期に事故った経緯から、enforcement は settings/hook で行い AGENTS.md は背景説明に留める。さらに hook を authoritative にして `permissionDecision` を明示することで、user-scope 設定差異 (deny 有無 / syntax 差) に依存しない可搬性を確保する。

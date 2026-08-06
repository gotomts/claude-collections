# AGENTS.md（claude-collections リポジトリ・正本）

このリポジトリは**複数のスキル+エージェント集（コレクション）**をホストする（root `docs/adr/0001`）。エージェントが本リポジトリで作業するときの規約を定める。`CLAUDE.md` は本ファイルを参照する薄いポインタ。

## 構成規約

- 各コレクションは `<collection>/` 配下に**自己完結**する：`skills/`・`agents/`・`docs/adr/`・`CONTEXT.md`・`ROADMAP.md`・`.claude-plugin/plugin.json`。
- **例外：`shared/`** は plugin だがコレクションではない（agents/skills の共有基盤・ADR-0010）。`CONTEXT.md` / `ROADMAP.md` / `docs/adr/` は持たず、設計判断は root `docs/adr/` に置く。ただし `.claude-plugin/plugin.json` を持つため release-drafter の auto-discovery には collection として載り、`shared/v0.0.x` の draft/tag を持つ。
- root には repo 横断の `AGENTS.md`（本ファイル）・`CLAUDE.md`（ポインタ）・`CONTEXT-MAP.md`（コレクション索引）・`docs/adr/`（横断決定）・`.claude-plugin/marketplace.json`（plugin marketplace 宣言）。
- コレクション一覧と所在は `CONTEXT-MAP.md`。
- 配布構造（marketplace + 各 plugin）の決定は [`docs/adr/0003`](docs/adr/0003-plugin-marketplace-distribution.md)。
- **配布は作者が自分の環境へインストールするための手段**であり、他の利用者は想定しない（[`docs/adr/0012`](docs/adr/0012-author-only-distribution-premise.md)）。したがって設計判断で **「consumer 環境に依存するから」を単独の却下理由に使わない**。既にこの理由で却下された案が root ADR-0011 / enhance-superpowers ADR-0016 D3 にあるが、いずれも**別理由で結論は維持される**（詳細は ADR-0012）。

## スキル/エージェントを足す・直すとき

- 該当コレクションの `<collection>/skills/<skill>/SKILL.md` ／ `<collection>/agents/<name>.md` に置く（root 直下に置かない）。
- **エージェントは実在職種名で**設計する（成果物名・概念で割らない）。
- **エージェントの起動は `plugin:agent` 形式の修飾名で行う**（例：`shared:software-architect` / `indie-studio:ux-researcher`）。**bare name は解決されない**。同名 agent を持つ plugin が共存すると片方の agent セットが registry から丸ごと落ちるため、**agent 名を重複させないこと**（ADR-0010）。skill は名前空間が効くのでこの制約を受けない。
- **重複禁止の対象はコレクション間に閉じない。外部 marketplace の plugin も含む**（ADR-0011）。実例：`shared:code-reviewer` は Anthropic 公式 `feature-dev` plugin の `code-reviewer` と同名だったため `implementation-reviewer` に改名した。**中立語彙であることと、ありふれた名前でないことは別**で、衝突を招くのは後者。agent を足す前に install 済み plugin の agent 名と突き合わせる：

  ```bash
  find ~/.claude/plugins/cache -path "*/agents/*.md" -exec grep -l "^name: <新 agent 名>$" {} +
  ```
- 設計判断は該当コレクションの `docs/adr/` を読む。決定は inline／git／ADR に残す（専用の決定ログ file は作らない）。
- ADR は原則 immutable（決定の根拠を保存するため直接書き換え・削除しない。方針変更は新 ADR で supersede／extends する）。
- **例外：ナビゲーション注記の追加・更新は immutable に反しない。** immutable が守るのは**決定の根拠**であって、後から辿れるようにする道標ではない。既存 ADR に次を書き足す／直すのは**推奨される運用**（indie-studio ADR-0028 が「ADR-0016 / 0021 本文は immutable・inline 注記で本 ADR を指す」と明示的に採用した先例に従う）：
  - `Status` 行の `Superseded by ADR-000N` / `Updated (日付)`
  - 本文冒頭や該当箇所への `> ※ ADR-000N で再定義／更新` 形式の inline 注記
  - **禁止されるのは決定そのもの（Decision / Considered Options / 却下理由）の書き換え。** 注記で決定の適用範囲を変えるのも禁止（それは新 ADR で supersede／extends する）。
  - **注記に陳腐化する値を書かない**（スキル数・ファイル数など）。書くと構成変更のたびに更新が必要になり、immutable な doc に churn を生む。「現行は最新の ADR を参照」と書いて数は最新側に持たせる。
- **ADR の削除**（immutable のもう 1 つの例外。上記の注記と違い、こちらは決定の記録そのものを消すため条件が厳しい）。**位置（末尾か中間か）は問わず**、次の 2 条件を**両方**満たすときのみ削除してよい：
  1. **decision を伴わない誤記録**であること（非-decision を誤って ADR 化した bug／void な記録。immutable が守るのは「判断の根拠」であって、判断でないものは保存対象外）。
  2. **参照ゼロ**であること。**確認先は 2 系統あり、両方を見る**：
     - **repo 内**：`grep -rn "ADR-000N" .`（他 ADR・SKILL.md・CONTEXT.md・README 等）
     - **公開済みリリースノート**：`gh api repos/gotomts/claude-collections/releases --paginate --jq '.[]|select(.draft==false)|"\(.tag_name)\t\(.body)"' | grep "ADR-000N"`
     - ⚠️ **リリースノートは repo 内に無いので `grep -rn` では絶対に検出できない**。実際 `shared/v0.0.1` の本文は `root ADR-0010` / `ADR-0004` / `ADR-0005` を参照しており、repo 内 grep には現れない。**publish 済みのノートは事後変更が難しい**ため、ここを見落とすと恒久的な dangling 参照になる。
  - **参照が 1 つでもあれば削除しない。** 代わりに Status を `Void（理由）` にして本文を残す（参照側を全て直すより安全）。
  - 削除後は**その番号を参照する記述を新たに書かない**。実例：旧 root ADR-0008 は削除時点で無参照だったが、後から書かれた ADR-0010 が参照して dangling 化した。
- **ADR 番号の採番規約**（連番を保つことが目的）：
  - **削除で空いた番号は、次に作られる ADR が継ぐ**（末尾・中間いずれの gap も同じ扱い）。よって**作成順と番号順は必ずしも一致しない**（例：root ADR-0009 `repository-visibility-public` は ADR-0010 より後に書かれている。当初は旧 ADR-0008 の削除で空いた `0008` を継いだが、後に `0004` の重複を解消した際のスライドで `0009` になった）。番号は識別子であって時系列の保証ではない。
  - **既に存在する ADR の renumber は行わない。** 番号は SKILL.md・CONTEXT.md・他 ADR・**公開済みリリースノート**（repo 外・事後変更が難しい）から参照される識別子であり、付け替えは参照を壊す。空き番号を次の ADR が埋めれば連番は保たれるので、renumber の必要がない。
  - **例外：未 merge の ADR（main に入っていないもの）は改番してよい。** 番号が衝突したら改番するしかない（先に merge された PR が番号を確定させるため）。上記の禁止が守るのは SKILL.md・CONTEXT.md・他 ADR・公開済みリリースノートなど**branch の外に出た参照**（main に merge されて他 branch・他 worktree からも見える状態）であり、未 merge の ADR は参照が branch 内に閉じているので該当しない。
    - 改番時は**一括置換を使わない**。同じ番号が別名前空間（root / enhance-superpowers / indie-studio）に存在するため、機械的な置換は他名前空間を巻き込む。行指定で置換する。
    - 改番の経緯は改番した ADR の `Status` に 1 行残す（`enhance-superpowers/docs/adr/0017-reviewer-side-skill-and-parallel-sessions.md` が先例）。
  - **改番が必要になる前に防ぐ方が本質的な解決。** 「書き始めた時点の最大値 + 1」は他 PR の merge で古くなりうるので、push 直前に origin の最新状態で採番済み最大値を確認する：
    ```bash
    git fetch origin && git ls-tree origin/main --name-only <namespace>/docs/adr/
    ```
  - 番号は名前空間ごとに独立（下記）。
- **ADR 番号は名前空間ごとに独立している**（root `docs/adr/` と各 `<collection>/docs/adr/` で同じ番号が別物を指す。例：root ADR-0010 = shared plugin 化／enhance-superpowers ADR-0009 = ライセンスチェック／indie-studio ADR-0009 = agents がハーネスのホーム）。したがって**裸の `ADR-000N` は「そのファイルが属する名前空間の ADR」を指す**規約とし、他名前空間を参照するときは必ず修飾する — collection のファイルから root を指すなら `root ADR-000N`、root のファイルから collection を指すなら `indie-studio ADR-000N` のように書く。修飾を怠ると同一ファイル内で同じ番号が 2 つの意味に解決されうる。

## shared plugin（共有エージェント／スキル）

- engineering 系（executor / quality / leadership）の共通エージェント 13 体と helper 系スキル 2 本（start-stage-branch / finish-stage-pr）は、**`shared` plugin が単一の実体として提供する**（ADR-0010）。vendoring（`make sync` による複製）は **廃止**した。
- 各コレクションは `shared` を **install 前提の依存**として扱い、skill 内から `shared:<agent>` / `shared:<skill>` を修飾名で参照する（agent は修飾必須、skill は表記統一のため）。`dependencies.json` は不要（削除済み）。
- `shared/agents/` は **collection 非依存の中立語彙で書く**（ADR-0004 から継承した原則）。collection 固有 context（ステージ番号 / 参照 docs パス / 進行 protocol 等）は呼び出し元 skill が invocation 時に prompt で渡す。
- shared/ を編集すれば全 consumer へ即座に反映される（複製が無いため sync 忘れという失敗モードが存在しない）。
- コレクション固有のエージェント（例：indie-studio の business-strategist 等）は従来通り `<collection>/agents/` に手書きで置く。**shared/・他コレクション・install 済みの外部 plugin と同名にしないこと**（同名衝突は agent セットの消失を招く・ADR-0010 / ADR-0011）。

## 既存コレクション

- **`indie-studio`**：個人開発のサービス設計〜デザイン〜開発を自律で回すハーネス。設計の真実源は `indie-studio/CONTEXT.md` と `indie-studio/docs/adr/`。
- **`enhance-superpowers`**：公式 superpowers plugin の直線フロー (brainstorming → writing-plans → executing-plans) に、5 成果物 Spec フェーズ確定 / agent 能動 dispatch / 監査ログ / コンプライアンス trigger を被せた強化版。設計の真実源は `enhance-superpowers/CONTEXT.md` と `enhance-superpowers/docs/adr/`。
- **`shared`**（コレクションではなく共有基盤 plugin）：上記 2 つが依存する中立 agent 13 体 + helper skill 2 本。設計の真実源は root `docs/adr/0010`。リリースノート運用は他と同じく GitHub Releases（tag prefix `shared/v`）に従う。

## リリースノート運用

各コレクションの変更履歴は GitHub Releases に集約する (リポジトリ内 `CHANGELOG.md` ファイルは持たない)。ツールは [release-drafter@v6](https://github.com/release-drafter/release-drafter)、**単一の workflow + テンプレ config** (`.github/workflows/release-drafter.yml` + `.github/release-drafter-template.yml`) で repo top-level を auto-discover して各コレクション専用の draft を作成する。コレクション追加時に drafter 設定の手作業は不要 (`<new>/.claude-plugin/plugin.json` が main に乗れば次の push trigger で drafter が自動認識)。設計判断は [`docs/adr/0006`](docs/adr/0006-release-notes-workflow.md) (ノート運用全体) と [`docs/adr/0007`](docs/adr/0007-release-drafter-auto-discovery.md) (auto-discovery + テンプレ化)。

### tag 命名

- format: `<collection>/v<semver>` (slash 区切り、例: `indie-studio/v0.0.1`)
- テスト期: `v0.0.x` 系で publish、version-resolver は全 patch 固定 (`0.1.0` 自動突入を抑制)
- 安定化フェーズ: `v0.1.0` 以降 semver (ADR-0006 を extends する新 ADR で切り替え)
- **⚠️ 新規コレクションの初回 draft は `v0.1.0` になる。** version-resolver の patch 固定は「**直前のリリースから +1**」する仕組みなので、リリースがまだ 1 つも無い新規コレクションには効かず、release-drafter 組み込みの初期値 `0.1.0` が出る。放置して publish すると以後 `0.1.x` 系に固定され、他コレクションの `0.0.x` と体系がズレる。
- **⚠️ draft への tag 付け替えは「publish と同時」に行うこと。** draft の状態で `--tag` だけ直しても、**次に main へ push された時点で release-drafter が draft を再生成し、tag が `v0.1.0` に戻る**（実測：2026-07-28 に `shared` で発生）。正しい手順は retag と publish を **1 コマンドで同時実行**する:

  ```bash
  gh release edit --repo gotomts/claude-collections <collection>/v0.1.0 \
    --tag <collection>/v0.0.1 --title <collection>/v0.0.1 --draft=false
  ```

  publish 済みリリースは drafter に上書きされないため、以後は patch 固定が正しく効き `v0.0.1 → v0.0.2` と進む。**`gh release list` の表示はキャッシュで古い tag を返すことがある**ので、確認は `gh api repos/gotomts/claude-collections/releases --jq '.[]|"\(.tag_name) draft=\(.draft)"'` で行う。

### publish 判断 (PR merge 後 trigger)

PR を main に merge した直後の Claude Code セッションで、publish 判断を **必ず実行する**:

1. `gh release list --repo gotomts/claude-collections` で対象 collection の draft を確認（**表示はキャッシュで古い tag を返しうる**。tag と draft 状態の authoritative な確認は `gh api repos/gotomts/claude-collections/releases --jq '.[]|"\(.tag_name) draft=\(.draft)"'`）
2. `gh release view --repo gotomts/claude-collections <tag-name>` で draft 内容を確認
3. 内容のまとまり (機能完成 / 数 PR 蓄積 / リファクタ完了 / docs まとめ等) を評価し publish 推奨 or 待機を提案
4. ユーザー承認後、`gh release edit --repo gotomts/claude-collections <tag-name> --draft=false` で publish 実行（**そのコレクションの初回リリースなら `--tag` / `--title` を同時指定して `v0.0.1` に直す**。上記「tag 命名」参照）
5. publish 後、`gh api repos/gotomts/claude-collections/releases --jq '.[]|select(.draft==false)|"\(.tag_name) published=\(.published_at)"'` で tag と publish 状態を確認する（`gh release list` の表示はキャッシュを含むため最終確認には使わない）

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

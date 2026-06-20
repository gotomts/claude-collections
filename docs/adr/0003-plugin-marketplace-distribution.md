# コレクションは Claude Code plugin marketplace として配布する

`claude-collections` リポジトリは Claude Code の **plugin marketplace** として配布する。リポジトリ root の `.claude-plugin/marketplace.json` で marketplace を宣言し、各コレクション（`indie-studio/` 等）を独立した plugin として列挙する（`<collection>/.claude-plugin/plugin.json`）。配布経路は **local path marketplace と private repo marketplace を併用**する。version 戦略はテスト期 main 追従（git SHA pin）→ 安定化で semver に切り替える 2 段階とする。

## Status

accepted

## Considered Options

### 配布構造

- **却下：手動コピー継続** — 既存運用（各プロジェクトに `skills/` `agents/` をコピペ）。コレクションが増えるたび配送差分が手作業になり、main 追従が崩れる。`indie-studio` の自走規律（ADR-0004/0005）と整合しない。
- **却下：単一 plugin として束ねる**（リポジトリ全体を 1 plugin、root `.claude-plugin/plugin.json`）。将来コレクションが増えた時に「コレクション単位で install したい」要求と矛盾する。`docs/adr/`・`CONTEXT.md` 等のコレクション固有ドキュメントを plugin システムから隠せず、install 先に余計なファイルが流れ込む懸念も残る（実際には plugin システムが未知ディレクトリを無視するので副作用はないが、責務の分離としては不適）。
- **採用：リポジトリ = 1 marketplace、各コレクション = 1 plugin**。phuryn/pm-skills と同型。コレクションごとに `<collection>/.claude-plugin/plugin.json` を持ち、root の `marketplace.json` で `source: "./indie-studio"` のように相対パス参照する。`indie-studio/docs/adr/`・`CONTEXT.md`・`ROADMAP.md`・root の `AGENTS.md` 等は plugin システムから無視されるため、ハーネス本体の運用（リポジトリ内ドキュメント駆動）と plugin 配布（install 先には `skills/` `agents/` のみ）が綺麗に分離する。

### 配布経路

- **却下：public repo として公開**（marketplace add で誰でも install 可）。`indie-studio` は現状テスト段階で、外部利用を想定したドキュメント整備（README install 手順・ライセンス・破壊的変更通知）が未成熟。
- **却下：private repo のみ**。同 Mac の複数プロジェクト間で反復するときに、commit → push → marketplace update のラウンドトリップが入ってフィードバックループが遅い。
- **採用：local path + private repo の併用**。
  - **local path marketplace**：同 Mac 内の別プロジェクトには絶対パスで marketplace 登録（`/plugin marketplace add /Users/<you>/ghq/.../claude-collections`）。git push を介さず即反映でき、反復開発に最適。
  - **private repo marketplace**：別マシン・別環境からは GitHub 経由（`/plugin marketplace add gotomts/claude-collections`）。手動 install/update は gh CLI の credential helper で OK、auto-update は `GITHUB_TOKEN` 設定で有効化できる。

### version 戦略

- **却下：初手から semver 明示**（`plugin.json` に `version: "0.1.0"` を入れ、変更ごとに bump）。テスト期は変更が頻繁で、bump 忘れで `/plugin marketplace update` が走らないリスクが高い。
- **却下：永続的に git SHA pin**（version を一切入れない）。将来 public 化したとき consumer 視点で「いつ何が変わったか」「下位互換性は」を追跡する手段がない。安定化フェーズに必要な意識が育たない。
- **採用：2 段階移行**。
  - **テスト期（現在）**：`plugin.json` の `version` を省略 → Claude Code は git commit SHA を暗黙の pin として扱う。main にコミットすれば即座に新バージョン扱いになり、`/plugin marketplace update` で全 consumer に反映される。handoff の「テスト段階は main 追従で反復」と完全整合。
  - **安定化フェーズ**：`plugin.json` に semver を明示。breaking change は major bump、追加機能は minor、修正は patch。public 化や外部配布を始める前に切り替える。切り替え判断は本 ADR を **extends する新 ADR** で記録する（`indie-studio` の immutable + extends 規律と同型）。

## Consequences

- `marketplace.json` と `plugin.json` の最小構成だけで配布可能（skills/ agents/ は規約配置で自動発見されるため列挙不要）。コレクション追加時の手数は「`<collection>/.claude-plugin/plugin.json` 追加」「root の `marketplace.json` に 1 entry 追加」のみ。
- リポジトリ内ドキュメント（`docs/adr/`・`CONTEXT.md`・`ROADMAP.md`・`AGENTS.md`）は plugin システムから無視され、install 先には流れない。**リポジトリ作業者専用ドキュメント**として安全に残せる。
- 反対に、install 先プロジェクトには `skills/` `agents/` だけが見える。ハーネスの運用知識（5 ステージ × 5 ゲート、自走規律、ユビキタス言語）は install 先からは見えないため、利用者向けドキュメントは別途 README に集約する必要がある。
- version 戦略の 2 段階移行は、現時点では「省略」という一行で表現される消極的決定。安定化への切り替えタイミングを見落とさないよう、`indie-studio/ROADMAP.md` 等で再認識ポイントを設けることが望ましい。
- marketplace name `claude-collections` は Anthropic 公式予約名（`anthropic-*`, `claude-plugins-*` 等）と衝突せず使用可。
- 本 ADR は repo 横断の決定（複数コレクション共通の配布機構）であるため、`indie-studio/docs/adr/` ではなく root の `docs/adr/` に置く（ADR-0001 の「横断決定は root」原則に従う）。

# claude-collections

Claude Code 用の**スキル+エージェント集（コレクション）**を複数ホストするリポジトリ。各コレクションは1つの自己完結ユニットとして、自分の skills・agents・設計ドキュメント（ADR/CONTEXT）を持つ（モノレポ的）。

## 構成

```
claude-collections/
├── README.md                       # 本ファイル
├── AGENTS.md                       # エージェント向け規約(正本)
├── CLAUDE.md                       # @AGENTS.md ポインタ
├── CONTEXT-MAP.md                  # コレクション索引
├── docs/adr/                       # repo 横断の決定
├── .claude-plugin/marketplace.json # Claude Code plugin marketplace 宣言
└── <collection>/                   # コレクション(自己完結)
    ├── CONTEXT.md
    ├── docs/{adr,ROADMAP.md}
    ├── .claude-plugin/plugin.json  # Claude Code plugin metadata
    ├── skills/
    └── agents/
```

## ルール

- **コレクション優先**：スキル/エージェントは root 直下でなく `<collection>/` 配下に置く。各コレクションは自己完結（`docs/adr/0001`）。
- **実在職種**：エージェントは現実の職種名で設計する（成果物名で割らない）。
- **name で識別**：スキル/エージェントは frontmatter の `name` で識別・起動される（path 非依存）。ディレクトリを深くしても呼び出しは壊れない。
- 詳細な規約は [`AGENTS.md`](AGENTS.md)、コレクション一覧は [`CONTEXT-MAP.md`](CONTEXT-MAP.md)。

## コレクション

- **[`indie-studio`](indie-studio/)** — 個人開発のサービス設計〜デザイン〜開発をオールインで回す AI 自律開発ハーネス。アンカー（人間が握る土台）から企画・デザイン・技術設計・分解・実装までを、人間の数ゲートだけで自律的に進める。
- **[`enhance-superpowers`](enhance-superpowers/)** — 公式 superpowers plugin の直線フロー（brainstorming → writing-plans → executing-plans）に、5 成果物 Spec フェーズ確定・agent 能動 dispatch・監査ログ・コンプライアンス trigger を被せた強化版。

## Plugin として install して使う

本リポジトリは Claude Code の **plugin marketplace** として機能する（`.claude-plugin/marketplace.json`）。各コレクションは独立した plugin として配布され、`/plugin install <name>@claude-collections` で他プロジェクトに取り込める。

### 同じ Mac の別プロジェクトから使う（local path）

ローカルチェックアウトを直接 marketplace として登録する。反復開発に最適。

```
/plugin marketplace add /Users/<you>/ghq/github.com/gotomts/claude-collections
/plugin install indie-studio@claude-collections
```

### 別マシン・別環境から使う（GitHub repo）

GitHub 経由で marketplace を登録する。public リポジトリなので事前の認証は不要（手動 install/update・auto-update いずれも認証なしで動く）。

```
/plugin marketplace add gotomts/claude-collections
/plugin install indie-studio@claude-collections
```

`GITHUB_TOKEN`（または `GH_TOKEN`）の設定は必須ではない。GitHub API の未認証レート制限を避けたい場合の任意設定。

### バージョニング方針

- **現状（テスト期）**：`plugin.json` の `version` を省略し、git commit SHA を暗黙の pin として扱う。main にコミットすると `/plugin marketplace update` で即反映される
- **安定化後**：semver を `plugin.json` に明示し、breaking change には major bump を伴う。切り替え判断は [`docs/adr/0003`](docs/adr/0003-plugin-marketplace-distribution.md) を extends する新 ADR で記録する

## 新しいコレクションを追加するとき

1. `<collection>/` 配下に `skills/` / `agents/` / `docs/adr/` / `CONTEXT.md` / `ROADMAP.md` / `.claude-plugin/plugin.json` を作る（ADR-0001 の構造）
2. shared/agents/ のエージェントを使う場合は `<collection>/.claude-plugin/dependencies.json` を作り、`shared.agents[]` に basename を列挙する
3. `make sync COLLECTION=<collection>` を実行して generated file を反映
4. `make verify` で drift がないことを確認
5. root の `marketplace.json` に新 plugin を 1 entry 追加
6. `CONTEXT-MAP.md` にコレクションの所在と概要を追記

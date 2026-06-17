# agents

複数の**スキル+エージェント集（コレクション）**をホストするリポジトリ。各コレクションは1つの自己完結ユニットとして、自分の skills・agents・設計ドキュメント（ADR/CONTEXT）を持つ（モノレポ的）。

## 構成

```
agents/
├── README.md         # 本ファイル
├── AGENTS.md         # エージェント向け規約(正本)
├── CLAUDE.md         # @AGENTS.md ポインタ
├── CONTEXT-MAP.md    # コレクション索引
├── docs/adr/         # repo 横断の決定
└── <collection>/     # コレクション(自己完結)
    ├── CONTEXT.md
    ├── docs/{adr,ROADMAP.md}
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

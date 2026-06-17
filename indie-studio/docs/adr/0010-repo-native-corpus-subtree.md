# 導出 corpus は repo-native（サービス repo の docs/ サブツリーに隔離）

各サービスの corpus of record（CONTEXT/ADR・導出 corpus・Claude Design ハンドオフバンドル）を、そのサービス repo の `docs/` サブツリーに repo-native の Markdown で置く。アンカーは Obsidian で執筆してよいが、corpus of record は repo 側。コードとの原子的バージョン管理・PR 同梱・ツール非依存・ドキュメント横断性を優先する。

## Status

accepted

## Considered Options

- **却下: Obsidian を corpus of record にする**。自作 MCP でアクセスは可能（local CLI / remote 双方で実証済み）だが、コードと原子的にバージョン管理できず、挙動を変える PR に対応 docs 変更を同梱できない（ADR-0006 の並列デュアル訂正と相性が悪い）。
- **却下: サービスごとに別の design 専用リポジトリ**。コードを完全に汚さないが、コードとの原子性とドキュメント横断性が切れる。

## Consequences

- **コミット履歴はコードと docs が混在する**（サブツリーでもログは混ざる）。受容し、commit scope（例: `docs(design):`）で分離可能にする（`git log -- docs/` 等でフィルタ）。
- Obsidian＝人間のアンカー執筆面（任意）、repo `docs/`＝機械可読な corpus of record。derivation は anchors を読み `docs/design/` に書き出す。
- feature-team は `docs/` を self-grill し、ゲートで Claude Code が `docs/` を直接編集できる（ADR-0006 を脆い MCP 依存なしで満たす）。
- 構成例：`<service-repo>/{src/, docs/{CONTEXT.md, adr/, design/}}`。この `agents` リポジトリ自身が同型。

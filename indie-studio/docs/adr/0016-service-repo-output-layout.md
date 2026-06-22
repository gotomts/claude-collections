# サービス repo の repo-native 出力構成（全ステージ）と AGENTS.md / DESIGN.md

ハーネスの各ステージが書き出す repo-native 成果物の配置を確定する。エージェント横断の指示は **`AGENTS.md` を正本**にし、`CLAUDE.md` は `@AGENTS.md` を参照する薄いポインタにする（Claude 以外のエージェントに切り替えても正本を変えずに済む）。Claude Design がデザインシステムを生成した場合の実体は **`DESIGN.md`** として S3 が repo に配置する。

## Status

accepted（ADR-0010 の repo-native を全ステージの出力に具体化。ADR-0014/0015 の S3「CLAUDE.md 生成」を「AGENTS.md＋CLAUDE.md ポインタ＋DESIGN.md 配置」に更新。**ADR-0028 で `discovery/` ・ `tech/` ・ `decomposition/` を `docs/indie-studio/` 配下に namespace 化**）

## レイアウト

> **⚠️ ADR-0028 で再定義済**：下記の `docs/discovery/` ・ `docs/tech/` ・ `docs/decomposition/` は **`docs/indie-studio/` 配下に namespace 化された**（root の `*.md` と `docs/adr/` は維持）。最新レイアウトは [ADR-0028](0028-namespace-indie-studio-outputs-under-docs.md) 参照。本図は決定経緯の歴史として残す。

```
<service-repo>/
├── AGENTS.md               # エージェント横断の指示(S3 生成・正本)
├── CLAUDE.md               # @AGENTS.md を参照する薄いポインタ(S3 生成)
├── DESIGN.md               # 具体のデザイン憲法(統一プロトの入力・living・ADR-0020 で再定義)
├── CONTEXT.md              # ユビキタス言語(S3 種まき → S5 が育てる)
├── docs/
│   ├── adr/                # 設計判断(S3 種まき → S5 追記)
│   ├── discovery/          # S1 企画→ブリーフ ※ADR-0028 で docs/indie-studio/discovery/ に移動
│   │   ├── anchors/        #   prfaq / design-principles / provider / monetization-binary
│   │   ├── planning/       #   01,02,05-14,99 (feature-details は ADR-0021 で廃止)
│   │   ├── design/         #   screens.md・screen-specs/<area>/ (視覚デザインは DESIGN.md・ADR-0020)
│   │   └── brief.md      # (DECISIONS.md は ADR-0019 で廃止)
│   ├── tech/               # S3 技術設計(スタック/アーキ/モジュール/F-ID/ドメインモデル/開発の進め方/運用基盤) ※ADR-0028 で docs/indie-studio/tech/ に移動
│   └── decomposition/      # S4 の index.md(垂直スライス骨格・実 issue は Linear) ※ADR-0028 で docs/indie-studio/decomposition/ に移動
└── src/                    # S5 実装コード
```

## Considered Options

- **却下: CLAUDE.md を正本にする**。Claude 固有で、他エージェントに切り替えるとき正本ごと修正が要る。AGENTS.md を正本にし CLAUDE.md は参照に留める（ユーザーの global 設定 `~/.claude/CLAUDE.md → @AGENTS.md` と同型）。
- **却下: umbrella 無しの flat 配置 / `design`・`product` 等の umbrella 名**。別議論で却下済み。S1 の umbrella は `discovery` に確定。

## Consequences

- **S3 の repo セットアップ責務**：`AGENTS.md`（正本）・`CLAUDE.md`（`@AGENTS.md` ポインタ）・初期 `docs/adr/`・`CONTEXT.md` を配置/種まき。`AGENTS.md` は CONTEXT.md / DESIGN.md / 各設計ページ / ADR を参照する。（**ADR-0020 で改訂**：`DESIGN.md` は S3 配置ではなく、S1 後に具体デザイン憲法として組み上げプロトに先立って与える living file。生成機構は ADR-0020 決定5で未定）
- **DESIGN.md の位置づけ**：**ADR-0020 で再定義**。意図版 design-system.md は廃止、`DESIGN.md`＝プロトに先立つ具体のデザイン憲法で G2 以降 living に更新。
- **S5 はコードと PR が成果物**（docs ではない）。実装知見だけ `docs/adr/`・`CONTEXT.md` に追記。
- 各ステージ出力は commit scope（`docs(discovery):` / `docs(tech):` 等）で分離可能。

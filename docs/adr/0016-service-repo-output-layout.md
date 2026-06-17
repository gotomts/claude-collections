# サービス repo の repo-native 出力構成（全ステージ）と AGENTS.md / DESIGN.md

ハーネスの各ステージが書き出す repo-native 成果物の配置を確定する。エージェント横断の指示は **`AGENTS.md` を正本**にし、`CLAUDE.md` は `@AGENTS.md` を参照する薄いポインタにする（Claude 以外のエージェントに切り替えても正本を変えずに済む）。Claude Design がデザインシステムを生成した場合の実体は **`DESIGN.md`** として S3 が repo に配置する。

## Status

accepted（ADR-0010 の repo-native を全ステージの出力に具体化。ADR-0014/0015 の S3「CLAUDE.md 生成」を「AGENTS.md＋CLAUDE.md ポインタ＋DESIGN.md 配置」に更新）

## レイアウト

```
<service-repo>/
├── AGENTS.md               # エージェント横断の指示(S3 生成・正本)
├── CLAUDE.md               # @AGENTS.md を参照する薄いポインタ(S3 生成)
├── DESIGN.md               # デザインシステム参照(Claude Design ハンドオフ由来・S3 配置)
├── CONTEXT.md              # ユビキタス言語(S3 種まき → S5 が育てる)
├── docs/
│   ├── adr/                # 設計判断(S3 種まき → S5 追記)
│   ├── discovery/          # S1 企画→ブリーフ
│   │   ├── anchors/        #   prfaq / design-principles / provider / monetization-binary
│   │   ├── planning/       #   01,02,05-14,99 + feature-details.md
│   │   ├── design/         #   design-concept / design-system / design-tokens・screens.md・screen-specs/
│   │   └── brief.md      # (DECISIONS.md は ADR-0019 で廃止)
│   ├── tech/               # S3 技術設計(スタック/アーキ/モジュール/F-ID/ドメインモデル/開発の進め方/運用基盤)
│   └── decomposition/      # S4 の index.md(垂直スライス骨格・実 issue は Linear)
└── src/                    # S5 実装コード
```

## Considered Options

- **却下: CLAUDE.md を正本にする**。Claude 固有で、他エージェントに切り替えるとき正本ごと修正が要る。AGENTS.md を正本にし CLAUDE.md は参照に留める（ユーザーの global 設定 `~/.claude/CLAUDE.md → @AGENTS.md` と同型）。
- **却下: umbrella 無しの flat 配置 / `design`・`product` 等の umbrella 名**。別議論で却下済み。S1 の umbrella は `discovery` に確定。

## Consequences

- **S3 の repo セットアップ責務**：`AGENTS.md`（正本）・`CLAUDE.md`（`@AGENTS.md` ポインタ）・`DESIGN.md`（Claude Design ハンドオフのデザインシステム）・初期 `docs/adr/`・`CONTEXT.md` を配置/種まき。`AGENTS.md` は CONTEXT.md / DESIGN.md / 各設計ページ / ADR を参照する。
- **DESIGN.md の位置づけ**：S1 の `docs/discovery/design/design-system.md`（事前意図）に対し、`DESIGN.md`＝プロトタイプで実体化した実装時の権威版（Claude Design ハンドオフ由来）。
- **S5 はコードと PR が成果物**（docs ではない）。実装知見だけ `docs/adr/`・`CONTEXT.md` に追記。
- 各ステージ出力は commit scope（`docs(discovery):` / `docs(tech):` 等）で分離可能。

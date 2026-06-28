# 0006. enhance-brainstorming Phase 3 の Y 方式 (summary context 委譲)

## Status

Accepted (2026-06-25)

## Context

enhance-brainstorming は Phase 2 で summary.md を user 合意済みにし、Phase 3 で design.md を生成する。design.md の生成は **superpowers:brainstorming の skill を再利用したい** (公式の design 生成ロジック / 質問の質 / self-review の組み込みを活かす) が、superpowers:brainstorming は「会話で詰める + design.md 書き出し」を一気にやる skill であり、間に Phase 2 (summary 合意) を挟む場合の連携方法を決める必要がある。

## Decision

**Y 方式** (= summary context 委譲) を採用する:

1. enhance-brainstorming が Phase 1 (会話) + Phase 2 (summary 合意) を主導
2. Phase 3 で superpowers:brainstorming を invoke する際、合意済み summary を context として渡し、「以下が合意済み summary、design.md として詳細展開して」と委譲
3. superpowers:brainstorming は context を踏まえて design.md を生成 + commit + writing-plans 遷移を担う

superpowers:brainstorming の skill 内部は変更しない (公式 skill の更新の恩恵を受け続ける)。

## Consequences

- superpowers の design 生成ロジック / self-review / writing-plans 遷移を再利用、保守コスト低
- superpowers:brainstorming が summary context を完全無視して会話を再開する場合、enhance-brainstorming が user に「合意済みです」を再伝達 → なお続行なら受け入れる (確認会話ならコスト小)
- **Y 方式が運用上機能しないと判明したら Z 方式 (自前実装) に移行**: 本 ADR を update して trial 結果を記録、enhance-brainstorming が会話 → summary → design を全部自前で実装する形に変える

## Alternatives Considered

- Z 方式 (自前実装、initial 採用) — superpowers の design 生成ロジックを再実装することになり、superpowers の更新追従コストが増える。fallback として ADR-0006 に明記しつつ initial は採用しない
- X 方式 (superpowers:brainstorming 内部で summary を先に書くよう改変) — 公式 skill の改変は実現難、スコープ外。却下

# 0002. 5 成果物の出所と summary-first 順序

## Status

Accepted (2026-06-25)

## Context

CLAUDE.local.md の運用では Spec フェーズで 5 つの成果物 (design / plan / summary / gwt / pr-description) を作る。元々の運用順は「design → plan → summary → gwt → pr-description」で、summary は design の TL;DR として後追いで作っていた。しかし、design.md が長文になるとレビューコストが高く、design 全体を見直す手戻りが大きい。

## Decision

5 成果物の生成順を **summary-first** に変更する: `summary → design → plan → gwt → pr-description`。

各成果物の出所:

| 順 | 成果物 | 出所 |
|---|---|---|
| 1 | summary.md | enhance-brainstorming (templates) — 合意メモ |
| 2 | design.md | superpowers:brainstorming (合意済み summary を context として渡す = Y 方式 / ADR-0006) |
| 3 | plan.md | superpowers:writing-plans |
| 4 | gwt.md | enhance-brainstorming (templates) |
| 5 | pr-description.md | enhance-brainstorming (templates) |

templates は `enhance-superpowers/templates/` に同梱 (PC 以外でも使う前提)。CodeRabbit 前提文言は残す (汎用化しない、ADR-0001 のスコープ判断と整合)。

## Consequences

- Spec フェーズに認識齟齬検出ポイントが **3 重**になる: ① summary 合意 (大枠ズレ) → ② gwt 合意 (AC ズレ) → ③ pr-description 合意 (動作確認方法ズレ)。最大コストの齟齬 (大枠) を最も早く検出する「コスト × 検出時期」の最適化
- summary 生成時点 (Phase 2) で slug は確定済みなので、summary frontmatter に `design: ./{date}-{slug}-design.md` を **先行記載**できる (design.md は Phase 3 で同じ slug で生成される)
- pr-description の Spec フェーズ先行作成 (CLAUDE.local.md 由来) は維持。動作確認方法の言語化を Spec で潰すことで実装後の手戻りを防ぐ

## Alternatives Considered

- design → summary の従来順 — design の長文に対するレビューコストが高く、手戻りも大きい。却下
- summary を作らず design.md のみ — TL;DR がないと一望性が低く、PR レビュアーや他 collaborator が読む際の負担が大きい。却下

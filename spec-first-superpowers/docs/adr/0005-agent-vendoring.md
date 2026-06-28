# 0005. agent vendoring の選定理由 (4 体取り込み)

## Status

Accepted (2026-06-25)

## Context

`shared/agents/` には 13 体の engineering 系 agent (backend / frontend / mobile / infrastructure / performance / security / qa / code-reviewer / reviewer / software-architect / tech-lead / engineering-manager / principal-engineer) がある。spec-first-superpowers でどれを取り込むかが論点。

## Decision

initial で取り込む agent は **4 体** に絞る:

- `software-architect` — enhance-brainstorming Phase 1-3 (アプローチ / summary / design レビュー)、実装フェーズの任意 dispatch 案内
- `qa-engineer` — enhance-brainstorming Phase 4 (plan のテスト戦略) + Phase 5 (gwt の AC 網羅性) + gwt-test の AC 未達発覚時
- `code-reviewer` — write-review-response の判定迷い時 / 採用後修正の再 push 前 + 実装フェーズの任意 dispatch 案内
- `security-engineer` — enhance-brainstorming Phase 3/4 で常時能動 dispatch (セキュリティレビュー + 機微情報チェック) + write-review-response のセキュリティ系指摘 + STOP POINT 2 (code-review に加えて security-focused コードレビュー)

`dependencies.json` の `shared.agents[]` で宣言、`make sync` で `spec-first-superpowers/agents/` に generated file として展開。

## Consequences

- 実装系 5 体 (backend / frontend / mobile / infrastructure / performance) は **初期は外す**、必要時に dependencies.json に追加して再 sync
- reviewer / tech-lead / engineering-manager / principal-engineer は indie-studio 専用色が強く initial では取り込まない
- 4 体に絞ったことで `spec-first-superpowers/agents/` がコンパクトで読みやすい、indie-studio の 13 体 vendoring と棲み分け可能
- 増減基準: enhance-brainstorming / gwt-test / write-review-response の各タイミングで「能動 dispatch すべき職種」を識別したとき、その職種が agent としてあれば追加 sync、なければ新規 shared/agents/ に追加してから sync

## Alternatives Considered

- 全 13 体取り込み — 使わない agent が大半、`agents/` ディレクトリが肥大化。却下
- 0 体取り込み (skill のみ) — agent を使う場面 (ドキュメントレビュー / コードレビュー) で skill が自前で全部やることになり、silent failure pattern を誘発。却下
- 新規 agent を spec-first-superpowers 固有で立てる — initial は YAGNI、shared/ の既存 4 体で十分、不足判定が出てから新設する

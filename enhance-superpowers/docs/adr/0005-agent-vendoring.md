# 0005. agent vendoring の選定理由 (4 体取り込み)

## Status

Accepted (2026-06-25). Updated (2026-07-04): 既知制約 (dogfood 時の語彙ドリフト) を **解消**。root ADR-0004 の中立語彙原則 (2026-07-04 追加) に従って `shared/agents/` 13 file を collection 非依存の中立語彙に書き直し、enhance-superpowers の CONTEXT.md「indie-studio との禁止語彙」との衝突を除去。 Updated (2026-07-04): ADR-0012 D1 redesign で `enhance-executing-plans` skill が **executor 系 5 体** を追加 vendoring した (initial 4 → 9 体)。 Updated (2026-07-04): user 指摘「未 vendoring 4 体も別工程で使えるのでは」を受け、**残り 4 体 (reviewer / tech-lead / engineering-manager / principal-engineer) も追加 vendoring**、vendoring 総数は **全 13 体** に。旧「initial は 4 体に絞る」判断の理由 (indie-studio 専用色) は中立語彙化で失効。加えて **コードレビュー activity は `code-review` skill (CodeRabbit) を default** に、`code-reviewer` agent は判定 aid 専用に予約する運用に方針統一 (ADR-0013 拡張)。

## Context

`shared/agents/` には 13 体の engineering 系 agent (backend / frontend / mobile / infrastructure / performance / security / qa / code-reviewer / reviewer / software-architect / tech-lead / engineering-manager / principal-engineer) がある。enhance-superpowers でどれを取り込むかが論点。

## Decision

initial で取り込む agent は **4 体** に絞る:

- `software-architect` — enhance-brainstorming Phase 1-3 (アプローチ / summary / design レビュー)、実装フェーズの任意 dispatch 案内
- `qa-engineer` — enhance-brainstorming Phase 3 (gwt の AC 網羅性) + Phase 4 (plan のテスト戦略) + gwt-test の AC 未達発覚時
- `code-reviewer` — write-review-response の判定迷い時 / 採用後修正の再 push 前 + 実装フェーズの任意 dispatch 案内
- `security-engineer` — enhance-brainstorming Phase 3/4 で常時能動 dispatch (セキュリティレビュー + 機微情報チェック) + write-review-response のセキュリティ系指摘 + STOP POINT 2 (code-review に加えて security-focused コードレビュー)

`dependencies.json` の `shared.agents[]` で宣言、`make sync` で `enhance-superpowers/agents/` に generated file として展開。

## Consequences

- 実装系 5 体 (backend / frontend / mobile / infrastructure / performance) は **初期は外す**、必要時に dependencies.json に追加して再 sync
- reviewer / tech-lead / engineering-manager / principal-engineer は indie-studio 専用色が強く initial では取り込まない
- 4 体に絞ったことで `enhance-superpowers/agents/` がコンパクトで読みやすい、indie-studio の 13 体 vendoring と棲み分け可能
- 増減基準: enhance-brainstorming / gwt-test / write-review-response の各タイミングで「能動 dispatch すべき職種」を識別したとき、その職種が agent としてあれば追加 sync、なければ新規 shared/agents/ に追加してから sync
- **既知制約 (dogfood 時の語彙ドリフト) — 2026-07-04 解消**: 元 Accept 時点では `shared/agents/` の body が indie-studio 由来語彙塗れで、本コレクション CONTEXT.md「indie-studio との禁止語彙」と衝突していた。2026-07-04 に root ADR-0004 の中立語彙原則追加 + 案 a (`shared/agents/` を中立語彙に書き直し全 collection 再 sync) を採用して解消。enhance-brainstorming Phase 1 で `software-architect` を dispatch しても、agent body が「S3 のソフトウェアアーキテクト」を名乗る不整合は起きなくなった。invocation 時に呼び出し元 skill が context (architecture 規約 / 参照 docs / 進行 protocol) を prompt で渡す設計に変更 (root ADR-0004 参照)。indie-studio 側は同じ shared/ から re-sync され、SKILL 側に context 追加が必要になるが、本 PR (shared/agents/ 中立化) スコープでは skill 更新は含めない (indie-studio 側の SKILL 更新は follow-up PR で対応)

## Alternatives Considered

- 全 13 体取り込み — 使わない agent が大半、`agents/` ディレクトリが肥大化。却下
- 0 体取り込み (skill のみ) — agent を使う場面 (ドキュメントレビュー / コードレビュー) で skill が自前で全部やることになり、silent failure pattern を誘発。却下
- 新規 agent を enhance-superpowers 固有で立てる — initial は YAGNI、shared/ の既存 4 体で十分、不足判定が出てから新設する

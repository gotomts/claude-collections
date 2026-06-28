# 0003. skill 連鎖と 2 stop point

## Status

Accepted (2026-06-25)

## Context

enhance-superpowers は 4 skill (enhance-brainstorming / gwt-test / write-review-response / finish-spec-pr) で構成される。ユーザーが意識的に呼ぶ skill を最小化したい (理想は 1 skill のみ)、かつ各 skill の責任境界は明確にしたい。superpowers (公式) の brainstorming → writing-plans → executing-plans が「ユーザーは brainstorming 1 つだけ呼べば連鎖で進む」設計なので、これと同じ思想にしたい。

## Decision

`enhance-brainstorming` を **起点 skill** とし、内部で sub-skill (gwt-test / write-review-response / finish-spec-pr) を terminal state として連鎖 invoke する。フェーズ間で人間 (or 実装 AI) の介入が必要な箇所は **STOP POINT** として明示する。

- **STOP POINT 1**: 実装フェーズ — Spec フェーズ完了後、人間 or AI が実装する箇所
- **STOP POINT 2**: セルフレビュー — `code-review` skill (CodeRabbit) を user が手動 invoke する箇所。STOP POINT 2 案内には security-engineer によるコードレビューも含める (ADR-0008 関連)

stop 後の再開は (a) ユーザーが `enhance-brainstorming` を再 invoke (状態判定して続きから)、または (b) 個別 sub-skill (gwt-test / write-review-response / finish-spec-pr) を直接 invoke、のいずれでも可。

## Consequences

- ユーザーが意識的に呼ぶ skill は 1 つ (`enhance-brainstorming`)、superpowers と同じイメージ
- sub-skill を独立 skill にしているため、stop 後の再開や中断後の個別 invoke が柔軟
- 各 skill の責任境界が明確 (1 skill = 1 フェーズ)、保守コスト低
- superpowers の brainstorming hard-gate (user approval まで実装に進まない) と衝突しない (本コレクションは superpowers の skill を delegate で呼ぶだけ)

## Alternatives Considered

- 案 B: 単一 flow skill が end-to-end 進行 — brainstorming hard-gate と衝突、superpowers 更新で壊れやすい。却下
- 案 C: 規律 skill + テンプレートのみ (skill なし) — 規律強制が弱く skill 化の意味が薄い。却下

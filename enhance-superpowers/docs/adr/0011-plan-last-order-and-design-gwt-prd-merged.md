# 0011. 5 成果物の順序を plan-last に変更 (design + gwt + pr-description まとめ生成)

## Status

Accepted (2026-07-02).

Supersedes ADR-0002.

## Context

ADR-0002 で採用した summary-first 順序 (`summary → design → plan → gwt → pr-description`) を運用したところ、以下の課題が出た:

- **plan 再作コスト**: gwt (旧 Phase 5) で AC ズレが発覚したり、pr-description (旧 Phase 6) で動作確認方法ズレが発覚した場合、既に生成済みの plan.md の実装計画を後追いで書き直す必要があった。plan の作成コストが認識齟齬検出コストに乗ってしまう構造。
- **認識齟齬レビューの分散**: 認識齟齬検出 ② (gwt 合意) と ③ (pr-description 合意) を独立した 2 Phase に分けたことで、user 承認ポイントが 3 段構えになり、レビュー疲労が起きやすい。② と ③ は「動作の外形定義」の 2 面 (AC / 動作確認方法) で密接に関係するため、まとめて確認する方が意思決定の連続性が高い。

一方 summary-first の思想 (大枠ズレを最初に検出) は継続して有効。

## Decision

5 成果物の生成順を **plan-last** に変更する: `summary → (design + gwt + pr-description) → plan`。

**design / gwt / pr-description は同一 Phase (Phase 3) 内で連続生成し、3 file 揃ってから user 承認 1 回**。

各成果物の出所と Phase 対応:

| Phase | 順 | 成果物 | 出所 |
|---|---|---|---|
| 2 | 1 | summary.md | enhance-brainstorming (templates) — 合意メモ |
| 3 | 2 | design.md | superpowers:brainstorming (合意済み summary を context として渡す = Y 方式 / ADR-0006) |
| 3 | 3 | gwt.md | enhance-brainstorming (templates) |
| 3 | 4 | pr-description.md | enhance-brainstorming (templates) |
| 4 | 5 | plan.md | superpowers:writing-plans |

templates は `enhance-superpowers/templates/` に同梱 (ADR-0002 と同じ)。

## Consequences

- **認識齟齬検出は 3 重を維持、承認回数は 2 回に集約**: ① summary 合意 (Phase 2) → ② + ③ 一括合意 (Phase 3 の design + gwt + pr-description 揃い) → plan (Phase 4)。② と ③ を同時レビューすることで、AC と動作確認方法の整合性を 1 度に確認できる。
- **plan 再作コスト消滅**: plan は認識齟齬検出 ② + ③ の後に生成されるため、AC / 動作確認方法が確定してから実装計画を組める。plan の redo が発生しない。
- **agent dispatch は file 単位で継続**: design → software-architect + security-engineer + 機微情報チェック / gwt → qa-engineer / pr-description → dispatch なし (最小構造維持)。ADR-0007 の dispatch log 追記先は file 単位のまま、Phase 番号のみ更新 (旧 Phase 5 の gwt 系 → 新 Phase 3、旧 Phase 6 の pr-description → 新 Phase 3)。
- **ライセンスチェック (ADR-0009)** は plan.md 生成後 = Phase 4 で実施。Phase 番号は不変。
- **機微情報チェック (ADR-0008)** は design.md 生成後 = Phase 3 で実施。Phase 番号は不変。
- **pr-description の Spec フェーズ先行作成は継続**。ただし旧順序では plan.md のスコープから「## やったこと」を下書きしていたが、新順序では plan.md 未生成のため、**design.md のスコープと gwt.md の AC** から下書きする。実装完了後の finish-spec-pr で実装結果に合わせて整えるフローは変わらない。
- Phase 3 で 3 file 一括レビュー中に差し戻しが発生した場合、該当 file のみ再生成し 3 file 揃えて再提示する (承認単位は 3 file 一括のまま維持)。

## Alternatives Considered

- **plan を Phase 3 に置く (design → plan → gwt → pr-description、旧 ADR-0002 順序を維持)** — 上記 Context の「plan 再作コスト」問題が解決しない。却下
- **design / gwt / pr-description を独立 Phase に分割 (3 回承認)** — 承認 3 回でレビュー疲労が増える。② と ③ は同時に確認する方が意思決定の一貫性が高い。却下
- **3 file を 1 file に統合 (design 内に AC + 動作確認方法セクションを内包)** — pr-description は GitHub PR description text として単体で使用するため独立が必要、gwt は gwt-test skill で参照するため独立性が要る。却下

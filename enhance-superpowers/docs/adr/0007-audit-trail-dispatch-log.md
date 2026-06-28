# 0007. agent dispatch log (監査ログ) を 5 成果物のレビュー履歴セクションに集約

## Status

Accepted (2026-06-25)

## Context

各 skill で agent を能動 dispatch (ADR-0005 関連) する設計だが、「いつ / 誰を / 何のために dispatch したか + 回答要約」を残さないと、後から「なぜこの設計を採ったか」「なぜこの採用/Skip 判定にしたか」を追跡できない。AI セッション / agent dispatch の監査ログが要る。

新規 store (audit-log/ 別 dir 等) を作る選択肢もあるが、`docs/superpowers/{branch}/` という Spec フェーズの単一ソースに統合する方が検索性 / 物理的近接性が高い。

## Decision

agent dispatch log を **5 成果物の末尾「## レビュー履歴」セクション**に追記する。集約先は dispatch のタイミングと密接な成果物:

| dispatch タイミング | 追記先 |
|---|---|
| enhance-brainstorming Phase 1 / 2 | summary.md |
| enhance-brainstorming Phase 3 | design.md |
| enhance-brainstorming Phase 4 | plan.md |
| enhance-brainstorming Phase 5 | gwt.md |
| enhance-brainstorming Phase 6 | (なし、pr-description は最小構造維持の例外) |
| gwt-test (AC 未達発覚時) | gwt.md |
| STOP POINT 2 (security-engineer) | review-response.md (write-review-response 内で集約) |
| write-review-response 内の全 dispatch | review-response.md |

形式:

```markdown
## レビュー履歴

- {YYYY-MM-DD HH:MM} - `{agent-name}` を {Phase N / skill 名} で dispatch (目的: {目的}) → 「{回答要約}」
```

## Consequences

- 検索性: ある機能のレビュー履歴は単一ディレクトリ (`docs/superpowers/{branch}/`) 内に集約、grep で追跡可能
- 物理的近接性: 該当 plan の隣に dispatch log が並ぶ、文脈を辿りやすい
- pr-description は GitHub PR description text としてそのまま投稿される (CLAUDE.local.md 由来) ため、レビュー履歴を加えると description が肥大化。例外として pr-description にはレビュー履歴を追記しない (B 例外)
- 「設計判断の監査証跡」(A) はすでに 5 成果物 + ADR + commit log で実質カバー、本 ADR は agent dispatch log (B) を加えることで監査トレースを厚くする

## Alternatives Considered

- 別ファイル `audit-log.md` を作る — 5 成果物と別 store になり、近接性が落ちる。grep スコープが分散。却下
- 別 dir (`docs/superpowers/audit/`) — 同上、検索性低下。却下
- pr-description にもレビュー履歴を追記 — GitHub PR description が肥大化、CodeRabbit 自動サマリーと干渉。却下

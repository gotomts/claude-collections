# 0007. agent dispatch log (監査ログ) を 5 成果物のレビュー履歴セクションに集約

## Status

Accepted (2026-06-25). Updated (2026-07-02): ADR-0011 で 5 成果物の生成順が plan-last (`summary → design → gwt → pr-description → plan`) に変わったため、下記 Phase → 追記先 mapping の Phase 番号を更新 (追記先の file 単位マッピング自体は不変)。 Updated (2026-07-04): ADR-0012 で実装フェーズが skill 化 (`enhance-executing-plans`) されたため、実装 slice 単位の dispatch を plan.md に集約する行を mapping に追加。ADR-0013 で gwt-test の qa-engineer 常時 dispatch (AC 検証完了時) を追加したため、gwt-test 行の細分を更新。

## Context

各 skill で agent を能動 dispatch (ADR-0005 関連) する設計だが、「いつ / 誰を / 何のために dispatch したか + 回答要約」を残さないと、後から「なぜこの設計を採ったか」「なぜこの採用/Skip 判定にしたか」を追跡できない。AI セッション / agent dispatch の監査ログが要る。

新規 store (audit-log/ 別 dir 等) を作る選択肢もあるが、`docs/superpowers/{branch}/` という Spec フェーズの単一ソースに統合する方が検索性 / 物理的近接性が高い。

## Decision

> ※ ADR-0016 でレビューの宛先が変わった（ローカルは `shared:implementation-reviewer`、PR 後は builtin `/review`）。**下記 mapping の追記先 file は不変**で、`STOP POINT 2` 行は新しい宛先の dispatch log をそのまま受ける。加えて ADR-0016 D2 が **`finish-spec-pr` Step 6（`/review`）→ `review-response.md` という行を mapping に足している**（指摘 0 件・折り返さない・skip の各経路では `write-review-response` が起動せず記録が落ちるため、`finish-spec-pr` 自身が書く）。**本 ADR の `pr-description` 除外（B 例外）はそのまま維持される。**

> ※ ADR-0017 で**レビュワー側 skill `pr-review`** が加わり、追記先が 5 成果物の外に 1 つ増えた。`pr-review` の dispatch log は同 skill の成果物 — `{date}-pr{N}-summary.md`（Step 2）/ `{date}-pr{N}-gwt.md`（Step 3）/ `{date}-pr{N}-review-report.md`（Step 5 の子セッション）— の「## レビュー履歴」に追記する。**下記 mapping と `pr-description` 除外（B 例外）は不変。** これらの file は発動元リポジトリに置き **commit しない**ため、監査証跡はローカルに閉じる（ADR-0017 D4）。

agent dispatch log を **5 成果物の末尾「## レビュー履歴」セクション**に追記する。集約先は dispatch のタイミングと密接な成果物:

| dispatch タイミング | 追記先 |
|---|---|
| enhance-brainstorming Phase 1 / 2 | summary.md |
| enhance-brainstorming Phase 3 (design 関連) | design.md |
| enhance-brainstorming Phase 3 (gwt 関連) | gwt.md |
| enhance-brainstorming Phase 3 (pr-description 関連) | (なし、pr-description は最小構造維持の例外) |
| enhance-brainstorming Phase 4 | plan.md |
| enhance-executing-plans (実装 slice 単位、ADR-0012) | plan.md |
| gwt-test (AC 検証完了時 qa-engineer 常時 dispatch、ADR-0013) | gwt.md |
| gwt-test (AC 未達発覚時) | gwt.md |
| STOP POINT 2 (security-engineer + code-review skill auto-invoke、ADR-0013) | review-response.md (write-review-response 内で集約) |
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

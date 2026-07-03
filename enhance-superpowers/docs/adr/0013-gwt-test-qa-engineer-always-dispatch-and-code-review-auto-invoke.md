# 0013. gwt-test に qa-engineer 常時 dispatch を追加 + STOP POINT 2 の code-review skill を auto-invoke に変更

## Status

Accepted (2026-07-04).

## Context

ADR-0001 / ADR-0005 のコンセプト「各 skill ステップで specialist agent を能動 dispatch して silent failure を回避」に対して、以下の 2 箇所で silent failure pattern が残っていた:

- **gwt-test AC 検証完了時**: 現状は AC 未達発覚時のみ `qa-engineer` を能動 dispatch。AC 検証完了時 (全 AC 満たしても) に「網羅性 / 抜けたシナリオ」を qa-engineer が確認する dispatch がない
- **gwt-test Step 7 (STOP POINT 2)**: 「`code-review` skill を **user が手動 invoke**」と規定していた。code-review skill は「AI-powered code review using CodeRabbit... autonomously when the agent thinks a review is needed」と description で明記されており、自動 invoke 可能。user 手動依存は silent failure リスクを引き受ける必要のない設計選択

## Decision

### D1: gwt-test に qa-engineer 常時 dispatch を追加

`gwt-test` SKILL.md の Step 4 (AC 達成判定) 直後、または新 Step 6 として、**全 AC 検証完了時に qa-engineer を能動 dispatch** する:

- 目的: AC 網羅性 (異常系 / 境界値 / 空状態 / seasonality 等) の review、抜けたシナリオの検出
- dispatch log は gwt.md 末尾「## レビュー履歴」セクションに追記 (ADR-0007 準拠)
- AC 未達発覚時の qa-engineer dispatch (現行 Step 5) は継続、別イベントとして両立

### D2: STOP POINT 2 の code-review skill を auto-invoke に変更

`gwt-test` SKILL.md の Step 7 (STOP POINT 2 案内) を以下のように変更:

- **before**: 「`code-review` skill を user が手動 invoke (CodeRabbit の機械的レビュー)」
- **after**: 「invoke 前に user 1 問確認 (課金意識) → `Skill` tool で `code-review` skill を **自動 invoke** (CodeRabbit の機械的レビュー)」

security-engineer の 能動 dispatch (現行 Step 7) は変更なし。

skill 化 (新 skill `enhance-self-review` を作る) は選ばなかった: 現行 gwt-test Step 7 が既に「code-review + security-engineer の両方」を担っており、責務分離の必要がない (minimum viable fix)。

## Consequences

- **silent failure 消滅**: gwt-test 内の 2 箇所の silent failure (AC 網羅性 / code-review 手動依存) が能動 dispatch / auto-invoke に置き換わる
- **user 経験の変化**: STOP POINT 2 が「案内 → user 手動」から「skill が 1 問確認 → auto-invoke」に変わり、user は code-review 実行を意識する負担が減る
- **課金の透明性**: code-review skill 自体の billing は変わらず、auto-invoke されても user account に課金される (skill description に明記)。invoke 前の 1 問確認で意図しない課金を防ぐ
- **gwt-test の Phase 数 / step 数増加**: qa-engineer 常時 dispatch を追加する分、Step が 1 つ増える (現行 7 → 新 8)

## Alternatives Considered

- **AC 検証完了時の qa-engineer dispatch を optional にする** — 「AC 全達成なので不要」と判断すると silent failure に戻る。却下
- **STOP POINT 2 skill 化 (`enhance-self-review` 新 skill)** — skill 数が増えるが、責務分離の必要がない (gwt-test 内で完結可能)。却下
- **code-review skill invoke 前 user 確認を無くす** — 課金意識を欠く = user 体験悪化。却下

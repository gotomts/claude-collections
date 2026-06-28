---
title: {機能名} — 受け入れ条件（GWT）
issue: {issue-url}
design: ./{YYYY-MM-DD}-{slug}-design.md
summary: ./{YYYY-MM-DD}-{slug}-summary.md
---

# {機能名} — 受け入れ条件

> Given-When-Then 形式。各 AC は独立した検証単位。design の方式・summary の TL;DR を満たすことを確認する受け入れ基準とする。

## AC-1: {シナリオ名}

- **Given**: {前提条件・初期状態}
- **When**: {ユーザー操作・イベント}
- **Then**: {期待される観測可能な結果}

## AC-2: {シナリオ名}

- **Given**: {前提条件}
- **When**: {操作}
- **Then**: {期待結果}

## 異常系 / エッジケース

### AC-E1: {異常シナリオ名}

- **Given**: {異常を誘発する前提}
- **When**: {操作}
- **Then**: {エラーハンドリング・フォールバックの期待挙動}

## スコープ外（受け入れ対象としない）

- {検証しない項目とその理由}

## 検証チェックリスト

> 各 AC の検証状況を一覧で管理する。テストして AC を満たしたら `- [ ]` を `- [x]` に書き換える。

- [ ] AC-1: {シナリオ名}
- [ ] AC-2: {シナリオ名}
- [ ] AC-E1: {異常シナリオ名}

## 変更履歴

> テスト実施でバグが発覚し AC を修正した場合や、仕様変更で受け入れ条件が更新された場合に追記する。新しいエントリを上に積む（逆時系列）。

- {YYYY-MM-DD}: {対象AC} — {変更内容}（{変更理由・関連 issue / PR}）

## レビュー履歴

> enhance-brainstorming Phase 5 + gwt-test の AC 未達発覚時に dispatch した agent の log を追記。形式は ADR-0007 参照。

- {YYYY-MM-DD HH:MM} - `{agent-name}` を {Phase 5 / gwt-test} で dispatch (目的: {目的}) → 「{回答要約}」

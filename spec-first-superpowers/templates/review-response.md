---
title: {機能名} — code-review 指摘への対応方針
issue: {issue-url}
spec: ./{YYYY-MM-DD}-{slug}-design.md
summary: ./{YYYY-MM-DD}-{slug}-summary.md
gwt: ./{YYYY-MM-DD}-{slug}-gwt.md
---

# {機能名} — code-review 指摘への対応方針

> {YYYY-MM-DD} に {source: `code-review` skill (CodeRabbit) / GitHub PR の CodeRabbit インラインコメント (unresolved 分のみ)} で {対象 commit range or PR URL} を review した結果を整理する。
> 採用 {N} 件は本 PR で fix、Skip {M} 件は理由付きで本 PR スコープ外と判定。
> PR コメントが source の場合: CodeRabbit へのリプライは送らない。修正済みのコメントは CodeRabbit が自動 resolve しているため、本 md には残った unresolved コメントへの判定のみ記録する。

## 指摘サマリー ({N} 件)

| 重要度 | 件数 | 内訳 |
| --- | --- | --- |
| Major | {n} | {ID 一覧: 例 M1 (xxx) / M2 (yyy)} |
| Minor | {n} | {ID 一覧: 例 Mi1 (xxx)} |
| Trivial | {n} | {ID 一覧: 例 T1 (xxx) / T2 (yyy)} |

判定結果: **採用 {N} 件** / **Skip {M} 件**。

## 採用 ({N} 件) — 本 PR で fix

### {ID}. {タイトル} ({対象ファイル})

**指摘**: {CodeRabbit の指摘要約}

**判定**: 採用。{採用理由}

**修正案**:

```{lang}
// 修正前
{修正前のコード}

// 修正後
{修正後のコード}
```

**効果**: {挙動・副作用・他指摘への影響。任意セクション}

## Skip ({M} 件) — 本 PR スコープ外

### {ID}. {タイトル} ({対象ファイル})

**指摘**: {CodeRabbit の指摘要約}

**Skip 理由**: {下記いずれかに該当することを明記}

- 別 PR で対応する技術的な理由（既存パターンとの同型維持 / 全 caller 評価が必要 等）
- プロジェクト規約で enforce されていない style 系の不採用
- 他の採用済み指摘で自動消化されるため不要

## 連動関係と効果

- {指摘間の依存・自動消化関係。例: M4 採用により T7 が自動消化}
- {commit 構成計画。例: 採用 {N} 件はまとめて 1 commit として積む}
- {その他の所感・PR description への引用ポイント}

## レビュー履歴

> code-reviewer / security-engineer の dispatch log を集約。STOP POINT 2 で実施した security-engineer のコードセキュリティレビュー結果もここに記録。形式は ADR-0007 参照。

- {YYYY-MM-DD HH:MM} - `{agent-name}` を write-review-response で dispatch (目的: {目的}) → 「{回答要約}」
- {YYYY-MM-DD HH:MM} - `security-engineer` を STOP POINT 2 で dispatch (目的: security-focused コードレビュー) → 「{回答要約}」

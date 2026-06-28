# 0004. shared/skills/finish-stage-pr の body-source-path 拡張 (後方互換改修)

## Status

Accepted (2026-06-25)

## Context

`shared/skills/finish-stage-pr` は push + PR open を担う共有 helper で、Step 7 に body 構築の内蔵テンプレ (## 概要 / ## ゲートレポート / 繰り越し論点 / ## 関連) を持つ。このテンプレは indie-studio 専用色が強い (ゲート / 繰り越し論点 / stage は indie-studio の語彙)。

enhance-superpowers の `finish-spec-pr` は、Spec フェーズで作成した `pr-description.md` (`## やったこと` / `## 補足` / `## 動作確認方法` の 3 セクション固定) を body として PR を作りたい。両者のテンプレ構造は互換性がない。

## Decision

`shared/skills/finish-stage-pr` の **Step 7 を分岐型にリファクタ**する (後方互換維持):

- 呼び出し側が `body-source-path` (任意引数) を渡した場合 → そのファイルを Read で読み込み、内容を body にする
- 渡さない場合 (default、indie-studio など既存呼び出し) → 既存の内蔵テンプレで body を構築

`argument-hint` も `<title-suggestion> [body-source-path]` 形式に拡張。

## Consequences

- indie-studio は引数なしで既存挙動 (内蔵テンプレ)、変更なし
- enhance-superpowers の finish-spec-pr は `body-source-path={pr-description.md path}` を渡して呼ぶ
- 改修後 indie-studio で 1 回 PR 作成して dogfood 検証必須 (互換性確認)
- 将来、別コレクションが別のテンプレで body を渡したい場合も同じ仕組みで拡張可能 (Open/Closed Principle に準拠)

## Alternatives Considered

- 案 B: enhance-superpowers のテンプレを finish-stage-pr 既存テンプレに揃える — pr-description の独自性 (3 セクション固定 + CodeRabbit 自動サマリー前提) を捨てることになり、CLAUDE.local.md の設計意図と衝突。却下
- 案 C: enhance-superpowers が独自に push + gh pr create を実装 — コード重複、共有 helper の意義が薄れる。却下

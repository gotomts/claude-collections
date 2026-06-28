# 0009. Phase 4 で plan の依存ライブラリのライセンスチェック

## Status

Accepted (2026-06-25)

## Context

エンプラ特有要素のうち「コンプライアンス (ライセンス遵守)」を本コレクションでどう扱うかが論点。OSS ライセンスは商用利用の可否 / 派生著作物の扱い / source 公開義務などで大きな影響を与え、特に GPL / AGPL / SSPL / 商用制限ライセンスは plan で依存追加する際に事前確認が必要。

## Decision

enhance-brainstorming Phase 4 (plan 生成後) に **ライセンスチェック step** を追加する:

1. plan.md の内容から、追加予定の依存ライブラリ一覧を抽出
2. 各ライブラリのライセンスを確認 (推奨ツール: `license-checker` / `license-finder` / `oss-review-toolkit` 等を user に案内、不在なら手動)
3. **制限ライセンス** (GPL-2.0 / GPL-3.0 / AGPL / SSPL / 商用制限あり) が含まれる場合、user に **警告 + 1 問確認** ("このライブラリは制限ライセンスです。継続しますか?")
4. user 判断は dispatch log として plan.md のレビュー履歴に記録 (ADR-0007)

具体的なライセンス互換性チェック (例: GPL 派生著作物の扱い / Apache-2.0 と GPL-2.0 の不整合検証) は **本コレクションのスコープ外**、license-checker 等の専用ツールに委ねる。

## Consequences

- plan 段階で制限ライセンスを検出 = 実装後に発覚するより手戻りが小さい
- 個人 OSS プロジェクトでは制限ライセンスでも問題ない場合があるため、本コレクションは **警告 + user 判断** で強制しない (環境依存)
- license-checker 等の専用ツールが既に CI / pre-commit に組み込まれていれば、本 step は二重チェック / 早期検出として機能する (重複は許容)

## Alternatives Considered

- ライセンス互換性の自動判定を本コレクションに実装 — 規模が大きすぎる、既存ツールに委ねる方が筋。却下
- ライセンスチェックを行わない — エンプラ系業務 repo で問題発生。却下
- Phase 3 (design 段階) でチェック — design 段階では依存ライブラリが未確定の場合が多い、Phase 4 (plan 段階) の方が抽出精度が高い

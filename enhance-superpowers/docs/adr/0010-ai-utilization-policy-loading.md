# 0010. 全 skill Step 1 で `.ai-restrictions.md` を Read して AI 利用ポリシーを案内

## Status

Accepted (2026-06-25)

## Context

エンプラ特有要素のうち「コンプライアンス (AI 利用ポリシー)」を本コレクションでどう扱うかが論点。業務 repo では「機密情報を外部 AI に送らない」「特定ファイル (顧客データ / API キー / 認証情報) を AI に渡さない」等のポリシーがあり、本コレクションの skill が無自覚にこれらを違反する可能性がある。

ただし、AI 利用ポリシーの規格 (ファイル名 / 記述形式) はプロジェクト / 環境ごとに異なり、本コレクションが厳密な規格を強制するとスコープ拡大に繋がる。

## Decision

全 skill (enhance-brainstorming / gwt-test / write-review-response / finish-spec-pr) の **Step 1** で、プロジェクトルートの **`.ai-restrictions.md`** (または同等のプロジェクト固有 AI 利用ポリシーファイル) を Read する:

1. ファイルが存在 → 内容を user に案内 (「以下の AI 利用制約があります、注意してください: ...」)
2. ファイルが存在しない → skip (環境依存、案内のみで強制しない)

ファイル形式 (`.ai-restrictions.md` で markdown、内容は任意の制約記述) は本コレクションが推奨するが、別ファイル名 (`AI-POLICY.md` / `.ai-policy` / `docs/ai-restrictions.md` 等) を user が使う場合、各 skill の Step 1 を user 個別環境で上書きすることを許容 (将来的に skill option として `--ai-policy-path` 引数追加の余地あり)。

## Consequences

- 業務 repo で AI 取扱いガイドが skill 実行時に自動表示される、無自覚な違反を予防
- ファイル不在環境 (個人 OSS / 規定なし) では skip、空回りせず
- 強制ではなく **案内のみ** = user が判断 (本コレクションが特定の禁止ロジックを実装すると環境依存になる)
- `.ai-restrictions.md` の運用 (誰が書く / どう更新する / レビュー要否) はプロジェクトの責務、本コレクションは Read + 表示のみ

## Alternatives Considered

- 特定ファイル (例: secret token / .env) を本コレクションが自動検知して AI に渡さないようブロック — silent block は事故の元、ユーザー判断を奪う。却下
- AI 利用ポリシーをスコープ外 — エンプラ業務 repo で空白になり、ユーザー要請に応えない。却下
- 全 skill の Step 1 にロジックを散らさず、enhance-brainstorming の起動時にのみ Read — sub-skill を直接 invoke した場合に skip される。却下 (全 skill Step 1 で読む方が安全)

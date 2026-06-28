# 0001. コレクションのスコープと命名

## Status

Accepted (2026-06-25)

## Context

`~/.claude/CLAUDE.local.md` で運用してきた superpowers カスタマイズ (5 成果物 / Spec 先行 / GWT テスト運用 / code-review 採用Skip / 設計思想 / コメント方針) は PC ローカル設定に閉じており、他環境 (他 PC / 業務 repo) に持ち出せない。コミット前提の repo でも同じフローを使いたいが、ローカルファイル参照や PC 固有規約 (worktree → main 退避) が混ざっているため、そのまま持ち出すと壊れる。

## Decision

claude-collections repo に **`spec-first-superpowers`** という plugin collection を新設する。indie-studio と並列の自己完結コレクションとして配置。「コミット前提で他環境に持ち出せる部分」のみを抽出してパッケージ化する。

スコープ:
- **In**: コレクション新設、shared/skills/finish-stage-pr の後方互換改修、marketplace.json 登録、CONTEXT-MAP.md 索引追加、セキュリティレビュー (2 層)、監査ログ (dispatch log)、コンプライアンス 3 項目 (機微情報チェック / ライセンスチェック / AI 利用ポリシー案内)
- **Out**: 変更管理 / 承認フロー (別コレクション扱い)、コード変更ログ (git カバー)、本番デプロイ履歴 (CI/CD カバー)、indie-studio 挙動変更

命名は **`spec-first-superpowers`** — 「Spec フェーズで 5 成果物 (特に pr-description) を先行確定」がコレクションの最大の独自性を直撃。enterprise や production よりも特徴を捉える。

## Consequences

- claude-collections の plugin が 2 つ (indie-studio + spec-first-superpowers) になる、marketplace.json 登録で他人も install 可能
- CONTEXT.md に「indie-studio 禁止語彙 (S1〜S5 / ゲート / 繰り越し決定 / アンカー / Claude Design 等)」を明示して語彙の混在を防ぐ
- 後続で「監査ログ / コンプライアンス特化コレクション」を別途立てる場合、本コレクションは触らず別 dir で進める

## Alternatives Considered

- `enterprise-superpowers` — 命名上 enterprise を冠すると監査 / コンプラ / 承認フロー等の含意が出るが、本コレクションはローカルフロー流用が主旨で誤誘導。却下
- `disciplined-superpowers` — 規律強化のニュアンスは良いが superpowers 自体が既に規律 skill 集で差分が伝わらない。却下
- `personal-superpowers` — オーナー個人スタイルとして率直だが、他人にも使ってもらえる前提と矛盾。却下

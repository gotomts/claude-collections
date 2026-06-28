# 0001. コレクションのスコープと命名

## Status

Accepted (2026-06-25). Updated (2026-06-28): 当初 `spec-first-superpowers` で merge (PR #15) したが、user が branch 命名時に意図した名前 (`enhance-superpowers` 系) と乖離していたため、release 前に rename を実施 — 本 ADR の Decision / Alternatives Considered も更新済み。

## Context

`~/.claude/CLAUDE.local.md` で運用してきた superpowers カスタマイズ (5 成果物 / Spec 先行 / GWT テスト運用 / code-review 採用Skip / 設計思想 / コメント方針) は PC ローカル設定に閉じており、他環境 (他 PC / 業務 repo) に持ち出せない。コミット前提の repo でも同じフローを使いたいが、ローカルファイル参照や PC 固有規約 (worktree → main 退避) が混ざっているため、そのまま持ち出すと壊れる。

## Decision

claude-collections repo に **`enhance-superpowers`** という plugin collection を新設する。indie-studio と並列の自己完結コレクションとして配置。「コミット前提で他環境に持ち出せる部分」のみを抽出してパッケージ化する。

スコープ:
- **In**: コレクション新設、shared/skills/finish-stage-pr の後方互換改修、marketplace.json 登録、CONTEXT-MAP.md 索引追加、セキュリティレビュー (2 層)、監査ログ (dispatch log)、コンプライアンス 3 項目 (機微情報チェック / ライセンスチェック / AI 利用ポリシー案内)
- **Out**: 変更管理 / 承認フロー (別コレクション扱い)、コード変更ログ (git カバー)、本番デプロイ履歴 (CI/CD カバー)、indie-studio 挙動変更

命名は **`enhance-superpowers`** — 本コレクションは公式 `superpowers` plugin の **直線フローを尊重しつつ拡張する** 位置づけ (brainstorming → writing-plans → executing-plans の上に 5 成果物 / agent 能動 dispatch / 監査ログを被せる)、命名でも「superpowers の強化版」を直撃させる。enterprise / production / spec-first 等の機能寄り命名より、提供価値の本質 (= superpowers のフロー拡張) が伝わる。

## Consequences

- claude-collections の plugin が 2 つ (indie-studio + enhance-superpowers) になる、marketplace.json 登録で他人も install 可能
- CONTEXT.md に「indie-studio 禁止語彙 (S1〜S5 / ゲート / 繰り越し決定 / アンカー / Claude Design 等)」を明示して語彙の混在を防ぐ
- 後続で「監査ログ / コンプライアンス特化コレクション」を別途立てる場合、本コレクションは触らず別 dir で進める

## Alternatives Considered

- `spec-first-superpowers` — 当初 PR #15 で採用した名前。「Spec フェーズで 5 成果物を先行確定」を直撃する利点はあるが、(a) 起点 skill 名 `enhance-brainstorming` を含む collection 名に user 意図が傾いていたこと、(b) collection の本質は「機能 (spec-first)」ではなく「フロー拡張 (superpowers の上に被せる)」であること、の 2 点から rename。却下
- `enhance-brainstorming` — collection 名と同名 skill `enhance-brainstorming` (起点 skill) が衝突するため不採用 (`enhance-brainstorming/skills/enhance-brainstorming/` の二重ネストは混乱の元)
- `enterprise-superpowers` — 命名上 enterprise を冠すると監査 / コンプラ / 承認フロー等の含意が出るが、本コレクションはローカルフロー流用が主旨で誤誘導。却下 (branch 名にはこの語が残ったが、collection 名としては不採用)
- `disciplined-superpowers` — 規律強化のニュアンスは良いが superpowers 自体が既に規律 skill 集で差分が伝わらない。却下
- `personal-superpowers` — オーナー個人スタイルとして率直だが、他人にも使ってもらえる前提と矛盾。却下

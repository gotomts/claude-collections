# 0012. 実装フェーズも skill 化して agent 能動 dispatch を強制する + 全 skill に状態判定 Step 0 を導入

## Status

Accepted (2026-07-04).

Supersedes ADR-0003.

## Context

ADR-0003 は skill 連鎖と 2 STOP POINT (実装 / セルフレビュー) を定義した。STOP POINT 1 (実装フェーズ) は「人間 or 実装 AI に委ねる」設計で、enhance-brainstorming SKILL.md Step 7 が「実装中の推奨 agent 利用パターンを案内」する **案内文言のみ** で終わっていた (skill による agent 能動 dispatch なし)。

一方、enhance-superpowers のコンセプト (ADR-0001 / ADR-0005 / CONTEXT.md「agent dispatch matrix」) は「各 skill ステップで specialist agent を能動 dispatch して silent failure を回避する」= "import するだけで使わない pattern を作らない" を core value の 1 つに掲げている。

**この 2 つは矛盾する** — 実装フェーズだけ agent 能動 dispatch を捨てる = silent failure がここに集中的に発生する = コンセプト違反 = バグ。

さらに、ADR-0003 は「stop 後の再開は user が enhance-brainstorming を再 invoke (**状態判定して続きから**)」と規定するが、**状態判定ロジックが SKILL.md 内に実装されていない** = user / AI の解釈依存 = ハンドオフ再開 / 別セッション再 invoke 時にドキュメント生成順序が破壊される事故が起きる。

## Decision

### D1: 実装フェーズを skill 化 (redesign 2026-07-04: superpowers 委譲を廃止、executor 能動 dispatch に)

新 skill **`enhance-executing-plans`** を追加する (superpowers 公式の brainstorming → writing-plans → **executing-plans** の 3 段目相当)。

責務:

- **実装前**: `software-architect` を能動 dispatch (実装方針の Clean Architecture / SOLID 整合性の pre-flight review)
- **実装本体 (slice 単位)**: 各 slice の対象領域 (backend / frontend / mobile / infrastructure / mixed) を判定し、該当 executor agent (`backend-engineer` / `frontend-engineer` / `mobile-engineer` / `infrastructure-engineer` / mixed なら複数 executor を順次) を **能動 dispatch**。dispatch prompt に skill 側から context (タスク定義 / 参照 docs / 担当範囲 / architecture 規約 / テスト戦略 / 進行 protocol) を明示提供する (agent は中立語彙、root ADR-0004 の原則)
- **実装完了ごと (slice 単位)**: **`code-review` skill を invoke** (課金前 user 1 問確認、default skip = STOP POINT 2 に集約)。`code-reviewer` agent は判定 aid 専用に予約 (ADR-0013 拡張、2026-07-04)
- **セキュリティ箇所**: `security-engineer` を **常時能動 dispatch** (実装対象 slice に auth / crypto / データ取扱 / 外部入力等の変更が含まれる場合、評価 mode で使用宣言)
- **性能影響箇所**: `performance-engineer` を能動 dispatch (大規模 UI / 大量データ処理等の slice、評価 mode で使用宣言)
- **dispatch log**: plan.md 末尾「## レビュー履歴」セクションに追記 (ADR-0007 pattern、実装フェーズ dispatch は plan.md に集約)
- **完了後**: user 承認 gate + attempt/final marker (M2 fix 2026-07-04) → `gwt-test` skill を chain invoke

**superpowers:executing-plans 委譲は却下** (2026-07-04 redesign): 「実装本体を superpowers に丸投げ」設計は、実装本体で誰が dispatch されるかを skill 側で保証できず、silent failure コンセプト違反を「skill 境界の外」に隠すだけだった。executor agent を skill 側で能動 dispatch する形に redesign。

STOP POINT 1 の性質を変更: 「人間 / 実装 AI に完全委譲」→ 「新 skill が実装エンジニア (executor 系 agent) を slice 単位で能動 dispatch、実装前後の review agent 能動 dispatch も強制」。

### D2: 全 skill に Step 0 = 状態判定 を導入

各 skill (enhance-brainstorming / enhance-executing-plans / gwt-test / write-review-response / finish-spec-pr) の冒頭に **Step 0 = 状態判定** を追加:

1. `docs/superpowers/{branch}/` の既存 file を Read
2. 5 成果物 (summary / design / gwt / pr-description / plan) の存在有無を判定
3. `handoff.md` がある場合、その内容を Read して state summary を取得 (handoff-policy.md 準拠)
4. 現在の Phase / Step を確定 (下記 mapping):

| 状態 | 判定 | 適切な skill/step |
|---|---|---|
| summary.md 未生成 | Spec Phase 1 (会話理解) から | enhance-brainstorming Step 2 |
| summary.md あり、design.md 未生成 | Spec Phase 3 (design + gwt + pr-desc) から | enhance-brainstorming Step 4 |
| design + gwt + pr-desc 揃い、plan.md 未生成 | Spec Phase 4 (plan) から | enhance-brainstorming Step 5 |
| plan.md あり、実装未完 | 実装フェーズ | enhance-executing-plans |
| 実装完、gwt.md checklist 未完 | テストフェーズ | gwt-test |
| gwt checklist 完、review-response.md 未生成 | セルフレビューフェーズ | write-review-response |
| review-response.md あり、PR 未作成 | PR 作成フェーズ | finish-spec-pr |

5. 判定結果を user に「現在 Phase = X、Step Y から再開します」と明示、user 1 問確認 (誤検出時の catch)

### D3: 各 skill 冒頭に Phase → 前提 file → 出力 file の table を明示

各 SKILL.md の「## 動作」直前に **Phase 定義 table** を書く (再開判定を仕様化):

```markdown
## Phase 定義

| Phase | 前提 file | 出力 file | 出力条件 |
|---|---|---|---|
| ... | ... | ... | ... |
```

これにより、再開判定は「code に基づく」= 順序破壊事故を構造的に防止。SKILL.md の内容が変わっても、table を先に確認する規律で仕様が滑らかに伝わる。

## Consequences

- **実装フェーズの silent failure 消滅**: 実装前後で software-architect / code-reviewer / security-engineer の dispatch が強制される
- **user 意識 skill 数は変わらず 1 (enhance-brainstorming)**: enhance-executing-plans は skill chain で自動連鎖 invoke されるので、user は enhance-brainstorming を呼ぶだけ
- **superpowers 直線フローとの整合**: enhance-executing-plans は `superpowers:executing-plans` を委譲 invoke するので、公式の直線フロー (brainstorming → writing-plans → executing-plans) に順ずる
- **ハンドオフ再開の順序破壊解消**: 全 skill が Step 0 状態判定 + Phase table を持つ = 別セッションが古い context を持っていても、file 状態から現在 Phase を判定できる
- **dispatch log 集約先の拡張**: ADR-0007 の Phase → 追記先 mapping に「enhance-executing-plans (実装 slice 単位) → plan.md」を追加する (ADR-0007 の Updated セクションで更新)
- **ADR-0003 supersede**: 「STOP POINT 1 = skill なし」の決定は本 ADR で覆る。ADR-0003 は Status を `Superseded by ADR-0012` に更新

## Alternatives Considered

- **STOP POINT 1 の性質を維持し Step 7 に "user に実装前後で agent dispatch するよう促す" 強い prompt を追加** — 「案内文言だけ」の域を出ず、silent failure 回避は user の記憶依存 = コンセプト違反継続。却下
- **自前の実装 loop skill (superpowers:executing-plans に依存しない)** — superpowers 公式との直線フロー統合が壊れる。executing-plans に細かい改良が入っても取り込めない。却下
- **状態判定を skill 外部 (handoff.md 等) に委ねる** — handoff.md は user 環境依存で、file が無い場合の default が不定 = 順序破壊の温床。skill 内に判定ロジックを組み込む方が安定。却下
- **状態判定を新 skill (`enhance-resume` 等) に分離** — 全 skill から重複ロジックが除ける利点はあるが、Skill 呼び出し追加のオーバーヘッド + 呼び忘れリスク。各 skill 冒頭に inline で持つ方が silent failure 回避のコンセプトと整合

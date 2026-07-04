# enhance-superpowers コレクション

superpowers (公式) を base に、ローカル開発フローの規律 (5 成果物 / Spec 先行 / GWT テスト運用 / code-review 採用Skip / 設計思想 / コメント方針) を skill+agent コレクション化したもの。中規模開発で Spec フェーズに認識齟齬検出を 3 重に分散する思想。

## Language

**5 成果物 (Five deliverables)**:
Spec フェーズで生成される 5 つの markdown ファイル — summary / design / gwt / pr-description / plan。生成順は **plan-last** (`summary → design → gwt → pr-description → plan`、ADR-0011)。design / gwt / pr-description は Phase 3 で連続生成し、3 file 揃ってから user 承認 1 回 (認識齟齬検出 ② ③ 統合)。命名は `{YYYY-MM-DD}-{slug}-{suffix}.md`。配置は `docs/superpowers/{branch}/`。

**enhance-brainstorming**:
enhance-superpowers の起点 skill。`superpowers:brainstorming` の責任を拡張し、5 成果物の Spec フェーズ確定 + 後工程 sub-skill の連鎖駆動を担う。ユーザーが意識的に呼ぶ唯一の skill。

**STOP POINT**:
skill 連鎖の中で agent 能動 dispatch を強制する境目。本コレクションは 2 つ持つ:
- **STOP POINT 1 (実装フェーズ)**: ADR-0012 で `enhance-executing-plans` skill 化。実装前 software-architect + slice ごと executor 能動 dispatch + review (code-review skill optional / security-engineer / performance-engineer) を強制 dispatch。
- **STOP POINT 2 (セルフレビュー)**: ADR-0013 で `code-review` skill を **auto-invoke** (課金前 1 問確認、scope は code-review のみ)。security-engineer 能動 dispatch と write-review-response chain は独立 = 常時実行 (silent failure 回避)。

**skill 一覧** (5 skill、ADR-0012 で `enhance-executing-plans` を追加):
1. `enhance-brainstorming` — 起点、Spec 5 成果物確定
2. `enhance-executing-plans` — 実装フェーズ (2026-07-04 redesign: skill 側から executor agent を直接 dispatch、superpowers 委譲は廃止 = silent failure の言い換えだった)
3. `gwt-test` — AC 検証 + qa-engineer 常時 dispatch (ADR-0013) + STOP POINT 2 実行 (code-review auto-invoke + security-engineer)
4. `write-review-response` — CodeRabbit 指摘の採用/Skip 判定
5. `finish-spec-pr` — PR 作成 (mechanical)

**認識齟齬検出ポイント**:
Spec フェーズで設計の認識ズレを早期検出する 3 重の関所 — ① summary 合意 (大枠ズレ、Phase 2) / ② gwt 合意 (AC ズレ、Phase 3) / ③ pr-description 合意 (動作確認方法ズレ、Phase 3)。② と ③ は Phase 3 の 3 file 一括レビューに集約される (ADR-0011)。

**agent dispatch matrix** (2026-07-04 更新):
各 skill ステップで能動 dispatch する agent / skill と目的の一覧。`import するだけで使わない` silent failure pattern を回避するための明示的な対応表。全 13 agent + code-review skill を vendoring (ADR-0005):

| skill / step | 能動 dispatch (agent / skill) | 目的 |
|---|---|---|
| enhance-brainstorming Phase 1 | software-architect + reviewer | アプローチの Clean Architecture / SOLID + 独立観点評価 (真実源整合 / 反証可能性) |
| enhance-brainstorming Phase 2 (summary) | software-architect + reviewer | SOLID / YAGNI + summary 反証可能性 |
| enhance-brainstorming Phase 3 (design) | software-architect + security-engineer + principal-engineer + 機微情報チェック | SOLID / モジュール境界 / セキュリティ / 独立技術設計評価 / 機微情報 (ADR-0008) |
| enhance-brainstorming Phase 3 (gwt) | qa-engineer | AC 網羅性 |
| enhance-brainstorming Phase 4 (plan) | qa-engineer + security-engineer + tech-lead + engineering-manager + principal-engineer + ライセンスチェック | テスト戦略 / セキュリティ / スタック判断 / slice 分解 / 分解評価 / ライセンス (ADR-0009) |
| enhance-executing-plans Step 2 (実装前) | software-architect | 実装方針 pre-flight review (ADR-0012) |
| enhance-executing-plans Step 3 (実装本体) | backend/frontend/mobile/infrastructure-engineer (slice 対応で選定) | executor 能動 dispatch (ADR-0012 D1 redesign) |
| enhance-executing-plans Step 4 (slice review) | **code-review skill (optional 1問確認)** + security-engineer + performance-engineer | code review activity は code-review skill を default (ADR-0013 拡張) |
| gwt-test Step 5 (AC 未達時) | qa-engineer | 差し戻し findings 言語化 |
| gwt-test Step 6 (AC 完了時) | qa-engineer 常時 | AC 網羅性 review (ADR-0013 D1) |
| gwt-test Step 8 (STOP POINT 2) | **code-review skill auto-invoke** (課金前 1 問確認) + security-engineer 能動 | CodeRabbit + security-focused review (ADR-0013 D2、M4 fix で scope 分離) |
| write-review-response Step 2 (判定迷い / セキュリティ / 大規模 refactor) | code-reviewer (判定 aid) / security-engineer / reviewer | 判定補助 |
| write-review-response Step 4 (再 push 前) | **code-review skill** (課金前 1 問確認) | 差し戻しレビューは code-review skill (ADR-0013 拡張) |
| finish-spec-pr | (なし、mechanical) | — |

`code-reviewer` agent は判定 aid 専用 (false positive 判定補助 / 大規模 refactor 判定補助)。実際のコードレビュー activity は `code-review` skill (CodeRabbit) を使う (ADR-0005 / ADR-0013 2026-07-04 拡張)。

dispatch log の追記先 mapping は ADR-0007 参照。

**レビュー履歴セクション**:
5 成果物の末尾に追加される `## レビュー履歴` セクション。agent dispatch log (時刻 / agent / 目的 / 回答要約) をここに集約 (B = 監査ログ)。形式は ADR-0007 で定める。

**Y 方式**:
enhance-brainstorming Phase 3 で合意済み summary を context として `superpowers:brainstorming` に委譲し design.md を生成させる実装方式。fallback (Z 方式 = 自前実装) は ADR-0006 に明記。**enhance-executing-plans は 2026-07-04 D1 redesign で委譲を廃止**、Y 方式は brainstorming (Phase 3) のみ継続。executing-plans は skill 側から executor 直接 dispatch (silent failure 回避)。

**状態判定 (Step 0)**:
全 skill 冒頭に配置される Step 0。`docs/superpowers/{branch}/` の既存 file 有無から現在 Phase を判定し、適切な Step から再開する仕組み (ADR-0012 D2)。SKILL.md 冒頭の Phase 定義 table (ADR-0012 D3) を再開判定の仕様源とする。ハンドオフ再開 / 別セッション再 invoke 時のドキュメント生成順序破壊を構造的に防止。

## indie-studio との禁止語彙

indie-studio コレクションが使う以下の語彙は、enhance-superpowers では **使わない** (思想が異なるため、同じ語彙で混乱を生まない):

- `S1〜S5` (ステージ番号)
- ゲート / 大枠ゲート (G1〜G5)
- 繰り越し決定 (Deferred decision)
- アンカー (Anchor)
- 自走設計 / 補助設計
- self-grill / 導出エージェント / 評価エージェント
- Claude Design / ハンドオフバンドル / プロトタイプブリーフ
- ハーネス / オーケストレーター / ディレクター

enhance-superpowers は superpowers (公式) の直線フロー (brainstorming → writing-plans → executing-plans) を尊重しつつ、その上に「Spec フェーズの 5 成果物確定」「後工程連鎖」「agent 能動 dispatch」を被せる設計。

## 設計思想

- **Clean Architecture + Modular Monolith** を採用 (既存プロジェクトに別規約があればそちら優先)
- **YAGNI / DRY / KISS / SOLID** を遵守、衝突時は **SOLID 最優先**
- **DRY はテストコードで一部許容** (Given/When は重複可、assertion helper / factory / fixture builder は共通化可)
- **コードコメントは WHY のみ**、JSDoc 抑制
- **agent 能動 dispatch**: 各 skill ステップで agent を必ず使う場面を織り込む (silent failure 回避)
- **コミット前提**: 設計ドキュメントは worktree 同居・main 退避なし

## 配置

| ファイル | 配置先 |
|---|---|
| 5 成果物 (summary / design / gwt / pr-description / plan) | `docs/superpowers/{branch}/` |
| review-response.md | 同上 |
| handoff.md (任意、状態判定の補助) | 同上 |
| コレクション固有 ADR | `enhance-superpowers/docs/adr/` |
| skill / agent / template | `enhance-superpowers/{skills,agents,templates}/` |

## 関連

- 設計 doc: `docs/superpowers/feat-enterprise-superpowers-customization/2026-06-25-enhance-superpowers-collection-design.md`
- summary: 同 dir の `-summary.md`
- plan: 同 dir の `-plan.md`
- ADR 0001-0013 (コレクション固有): `enhance-superpowers/docs/adr/`
- root ADR: `docs/adr/` (リポジトリ全体の決定)

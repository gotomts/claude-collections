# enhance-superpowers コレクション

superpowers (公式) を base に、ローカル開発フローの規律 (5 成果物 / Spec 先行 / GWT テスト運用 / code-review 採用Skip / 設計思想 / コメント方針) を skill+agent コレクション化したもの。中規模開発で Spec フェーズに認識齟齬検出を 3 重に分散する思想。

## Language

**5 成果物 (Five deliverables)**:
Spec フェーズで生成される 5 つの markdown ファイル — summary / design / gwt / pr-description / plan。生成順は **plan-last** (`summary → design → gwt → pr-description → plan`、ADR-0011)。design / gwt / pr-description は Phase 3 で連続生成し、3 file 揃ってから user 承認 1 回 (認識齟齬検出 ② ③ 統合)。命名は `{YYYY-MM-DD}-{slug}-{suffix}.md`。配置は `docs/superpowers/{branch}/`。

**enhance-brainstorming**:
enhance-superpowers の起点 skill。`superpowers:brainstorming` の責任を拡張し、5 成果物の Spec フェーズ確定 + 後工程 sub-skill の連鎖駆動を担う。ユーザーが意識的に呼ぶ唯一の skill。

**STOP POINT**:
skill 連鎖の途中で人間 (or 実装 AI) の介入が必要な箇所。本コレクションは 2 つ持つ — STOP POINT 1 (実装フェーズ) と STOP POINT 2 (セルフレビュー = `code-review` skill 手動実行)。

**認識齟齬検出ポイント**:
Spec フェーズで設計の認識ズレを早期検出する 3 重の関所 — ① summary 合意 (大枠ズレ、Phase 2) / ② gwt 合意 (AC ズレ、Phase 3) / ③ pr-description 合意 (動作確認方法ズレ、Phase 3)。② と ③ は Phase 3 の 3 file 一括レビューに集約される (ADR-0011)。

**agent dispatch matrix**:
各 skill ステップで能動 dispatch する agent と目的の一覧 (本リポジトリの設計 doc / ADR-0007 参照)。`import するだけで使わない` silent failure pattern を回避するための明示的な対応表。

**レビュー履歴セクション**:
5 成果物の末尾に追加される `## レビュー履歴` セクション。agent dispatch log (時刻 / agent / 目的 / 回答要約) をここに集約 (B = 監査ログ)。形式は ADR-0007 で定める。

**Y 方式**:
enhance-brainstorming Phase 3 で合意済み summary を context として `superpowers:brainstorming` に委譲し design.md を生成させる実装方式。fallback (Z 方式 = 自前実装) は ADR-0006 に明記。

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
| 5 成果物 (design / plan / summary / gwt / pr-description) | `docs/superpowers/{branch}/` |
| review-response.md | 同上 |
| コレクション固有 ADR | `enhance-superpowers/docs/adr/` |
| skill / agent / template | `enhance-superpowers/{skills,agents,templates}/` |

## 関連

- 設計 doc: `docs/superpowers/feat-enterprise-superpowers-customization/2026-06-25-enhance-superpowers-collection-design.md`
- summary: 同 dir の `-summary.md`
- plan: 同 dir の `-plan.md`
- ADR 0001-0010 (コレクション固有): `enhance-superpowers/docs/adr/`
- root ADR: `docs/adr/` (リポジトリ全体の決定)

# S1 discovery 出力レイアウト確定——feature-details 廃止・screen-specs を area サブフォルダ化

S1（企画→ブリーフ）の `docs/discovery/` 出力のうち、未定義だった2点を確定する。`feature-details`（機能別詳細素材）を廃止し、`screen-specs/` を area サブフォルダ化する。あわせて ADR-0020 のデザイン層集約と整合させ、`design/` の最終構成を確定する。

## Status

accepted（ADR-0011 / ADR-0016 の planning・design レイアウトを確定。ADR-0020 と併走）

## 決定

1. **feature-details（機能別詳細素材）を廃止**。ADR-0011 ロスターのラベルと ADR-0016 の `planning/feature-details.md` を除去する。この artifact は旧 service-designer / prototype-designer に対応物が無く（07 機能スコープは意図的にフラット、画面詳細は画面軸の screen-specs）、ADR-0011 で未定義のまま導入された中間物だった。機能軸の業務ルール（例「編集は投稿後24h以内」）は**該当 screen-spec に inline で attach**、機能の見出し採否は `feature-scope`（07）が真実源。S4 は **screen-specs ＋ feature-scope ＋ プロトタイプ**から受入条件を起こす。
2. **screen-specs を area サブフォルダ化**：`docs/discovery/design/screen-specs/<area>/<screen>.md`。`<area>` は新規分類を作らず、**feature-scope の機能グループ（ユーザー行動軸＝「記録する」「つながる」等）を流用**する。機能グループ → 画面群のカバレッジ確認が自然になり、画面増加時もスケールする。
3. **design/ の最終構成**（ADR-0020 と整合）：`docs/discovery/design/` ＝ `screens.md`（画面一覧）＋ `screen-specs/<area>/`（画面詳細）**のみ**。視覚デザイン（design-concept / design-system / design-tokens）は廃止し repo-root `DESIGN.md` に集約（ADR-0020）。

## Considered Options

- **却下：feature-details を残す**。未定義の中間物で、機能軸ルールは screen-spec への attach、受入材料は S4 起こしで足り、置けば screen-specs / feature-scope と重複する。
- **却下：screen-specs をフラット per-screen 維持**（旧スキル踏襲）。画面増加時に一覧が長く、area 単位の完全性確認に弱い。既存の機能グループ流用なら分類コストはゼロ。

## Consequences

- `planning/` ＝ `01,02,05-14,99`（番号固定・03/04 と 09 二値は anchors/ へ）。`feature-details.md` は無い。
- `design/` ＝ `screens.md` ＋ `screen-specs/<area>/` のみ。
- S4 受入条件の入力は screen-specs（機能軸ルールを attach 済み）＋ feature-scope ＋ プロト。

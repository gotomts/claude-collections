# DESIGN.md 生成スキル `design-direction` を S1 と S2 の間に追加（5 スキル化）

ADR-0020 で「FLAGGED open」とした DESIGN.md 生成機構を、新スキル `design-direction` で確定する。位置：S1（`service-discovery`）と S2（Claude Design プロトタイプ）の間。入力：S1 成果物（anchors + planning + design/）＋ **任意の参考画像** 0〜N 枚（UI スクショに限らず風景・絵画・写真・ブランド画像など mood / palette 抽出用）。出力：`<service-repo>/DESIGN.md`（Google Labs `design.md` spec の 8 セクション ＋ indie-studio 拡張 2 セクション `## Visual Theme & Mood` / `## Voice & Tone`）。エージェント編成：`product-designer`（既存・拡張）＋ `visual-designer`（新規・実在職種）＋ `reviewer`（既存）。

参照：
- Google Labs `design.md` spec: https://github.com/google-labs-code/design.md
- Anthropic `frontend-design` skill: https://github.com/anthropics/skills/blob/main/skills/frontend-design/SKILL.md
- OneWave `color-palette-extractor`: https://github.com/onewave-ai/claude-skills/blob/main/color-palette-extractor/SKILL.md
- Anthropic vision cookbook: https://github.com/anthropics/claude-cookbooks/blob/main/multimodal/best_practices_for_vision.ipynb
- rohitg00 `family-picker` prompt: https://github.com/rohitg00/awesome-claude-design/blob/main/prompts/family-picker.md
- VoltAgent/awesome-design-md（60+ ブランドの DESIGN.md 実例）: https://github.com/VoltAgent/awesome-design-md

## Status

accepted（ADR-0020 決定 5「未確定」を resolved に上書き／ADR-0017「4 スキル ↔ 4 handoff」を 5 スキル ↔ 5 handoff に拡張）

## 決定

1. **新スキル `design-direction`** を indie-studio に追加（`indie-studio/skills/design-direction/SKILL.md`）。位置は S1 と S2 の間（S1.5）。S2（Claude Design）の入力起こしを担う。
2. **DESIGN.md spec として Google Labs `design.md`（alpha）を採用**。YAML frontmatter ＋ 8 セクション（Overview / Colors / Typography / Layout / Elevation & Depth / Shapes / Components / Do's and Don'ts）。トークン間参照は `{path.to.token}` 構文。spec バージョンは alpha 時点で pin する（spec.md L1）。
3. **indie-studio 拡張**：(a) `## Visual Theme & Mood`（Overview 直後・必須）＝ 参考画像 / mood の言語化、specific reference を 1 つ以上必須化。(b) `## Voice & Tone`（Components 後・サービス性質次第で省略可）＝ ブランド voice / コピー語彙の規律。spec の「未知セクション保持」規約に従い、互換性は維持される。
4. **スキル内ループ**：brainstorm → direction-pick（3 問の一問一答・人間ゲート）→ 画像 ingest（任意・`visual-designer` 担当）→ token plan → AI-defaults critique（warm-cream / black-acid / broadsheet 3 種への陥落自己評価）→ compose → reviewer 評価ループ（最大 3R・ADR-0018）→ ⚠️繰り越し提示。
5. **エージェント編成（実在職種・ADR-0013 共通形）**：director ＝ スキル本体／ role ＝ `product-designer`（既存拡張：direction-pick 対話と compose）＋ `visual-designer`（新規実在職種：参考画像から palette / typography / atmosphere 構造化抽出）／ critique ＝ `reviewer`（既存）。
6. **画像入力経路**：ユーザーが Claude Code チャットに直接添付（Vision API）または絶対 path で渡す。画像なしも可（`visual-designer` は `mode=tone-fallback` で design-principles からトーン抽出）。画像ピクセルは repo に commit しない（出典 path のみ DESIGN.md 内記載）。

## Considered Options

- **却下：`service-discovery`（S1）に DESIGN.md authoring を含める**。S1 ディレクターの制御フローが画面導出と mood 対話で混線し、3 問対話の人間ゲートが S1 既存ゲート（画面一覧レビュー）と分離不能になる。スコープが肥大化し、S1 の到達点「触れるプロトタイプの直前」がぼやける。
- **却下：S2（Claude Design）起動スキルの pre-input として組み込む**。S2 は Claude Design 自体（claude.ai 外部）が担うため、ハーネス内には対応スキルが存在しない。pre-input を S2 に乗せる構造そのものが作れない。
- **却下：dotfiles の `prototype-designer` スキルを流用 / 拡張**。Obsidian Canvas + 手作業 moodboard 前提で、indie-studio の自律ハーネス（subagent spawn ・ 評価ループ）と設計思想が抜本的に違う。dotfiles 側は本 ADR を受けて廃止予定（dotfiles repo の per-machine global scope 変更のため、本 PR には含まない）。
- **却下：DESIGN.md spec を自前定義**。Google Labs `design.md` spec が事実上の標準として確立済み（VoltAgent/awesome-design-md に 60+ ブランドの実例、classmethod の 70% 字数削減実測、Claude / Cursor の自動認識）。自前で互換のないフォーマットを切ると Claude Design / Stitch / 他 AI ツールとの互換性を失う。
- **却下：3-tier agent split（design-bridge + ui-designer + discovery prelude を別エージェント、VoltAgent 流）**。個人開発 1 人ハーネスのスケールで分業しすぎ。2-role（`product-designer` ＋ `visual-designer`）に縮約し、共通形の director + role + critique（reviewer）の 3 ノードで足りる（ADR-0013）。
- **却下：独自 vision tool / MCP（Pencil 等）に依存して image 抽出**。Pencil MCP は `.pen` ファイル前提で `.md` DESIGN への適用が無く、画像ピクセルの直接読みは Claude Vision API が唯一の現実解。MCP 依存を増やさずに `visual-designer` が Vision で読む。
- **採用：独立スキル `design-direction`** ＋ **Google Labs spec 採用** ＋ **2 role（`product-designer` 拡張 ＋ `visual-designer` 新規）＋ 既存 `reviewer`**。

## Consequences

- **ADR-0020 改訂**：決定 5「未確定」を resolved に書き換える。生成機構＝ `design-direction` スキル ＋ `product-designer` / `visual-designer` / `reviewer` 編成、と確定。
- **ADR-0017 改訂**：「4 スキル ↔ 4 handoff」は「5 スキル ↔ 5 handoff」に拡張。新 handoff は「画像入力 ＋ 3 問の雰囲気対話」。
- **`product-designer.md` 更新**：「DESIGN.md は作らない」記述削除。S1 の screens / screen-specs 担当に加え、S1.5 の direction-pick 対話と DESIGN.md compose を担当。description / 起動モードに `mode=direction-pick` / `mode=compose` を追加。
- **`visual-designer.md` 新規追加**：実在職種「ビジュアルデザイナー」として、画像 → mood / palette / typography vibe 抽出を担当。
- **`reviewer.md`** は既存のまま（DESIGN.md も評価対象に含むのは ADR-0013 共通形で既定）。
- **`service-discovery` SKILL.md** の TODO 節（「DESIGN.md は本スキル初版では実装しない」）は、本 ADR で resolved 化。`service-discovery` 自身の改修は brief.md の「デザイン方向」項を「DESIGN.md（design-direction 出力）を読む」に変える程度（別 PR で追従）。
- **DESIGN.md 位置**：ADR-0020 通り repo-root（変更なし）。
- **画像入力経路**：Vision API（チャット添付）か path 渡し。ハーネス内に画像保管領域は持たない。
- **dotfiles 側の影響**：`~/.dotfiles/claude/skills/prototype-designer/` は本 ADR の indie-studio 集約方針により廃止予定。別 PR（dotfiles repo）で実施。本 PR には含まない（scope を per-repo に閉じるため）。
- **spec バージョン pin**：Google Labs `design.md` は alpha のため、SKILL.md と本 ADR で参照リビジョンを明記し、spec 破壊変更時は再評価する。

## 未確定

なし。本 ADR で生成機構は確定。spec 進化に伴う調整は別 ADR で追跡する。

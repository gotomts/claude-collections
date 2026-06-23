# DESIGN.md format spec を Google Labs `design.md` alpha に pin

ADR-0020 / 0023 で「DESIGN.md は Google Labs `design.md` spec に準拠する」と決めたが、SKILL.md / agents の frontmatter 例には spec 非準拠の構造（`colors` の 3 階層ネスト・`typography` の category 分離 + scale 別出し・`spacing` の array 表記・`components` 3 階層 + variant のネスト・unit suffix 欠落）が残っていた。`shadows` / `motion` のような spec の YAML schema にない top-level key も例に含まれており、claude.ai/design など spec 準拠 consumer の token parser が受け付けない可能性が高い（spec の "Unknown frontmatter top-level key" の挙動は spec の Consumer Behavior table に規定がない＝consumer 実装依存）。本 ADR で **format 正本を Google Labs `design.md` spec (alpha) に pin** し、frontmatter スキーマ・拡張セクションの互換性ルール・shadows/motion の扱い・section alias 表記を確定する。

参照：
- Google Labs `design.md` spec: https://github.com/google-labs-code/design.md
- Spec 本体: https://raw.githubusercontent.com/google-labs-code/design.md/main/docs/spec.md
- 関連 ADR: ADR-0020（DESIGN.md＝具体デザイン憲法）／ADR-0023（design-direction スキル追加）

## Status

accepted（ADR-0020 / ADR-0023 を extends。既存 ADR 本文は immutable・触らない）

## 決定

1. **format 正本＝Google Labs `design.md` spec (alpha)**。spec のリビジョンは `version: alpha` を frontmatter で明示。consumer は spec 準拠 parser（claude.ai/design 等）を前提とし、indie-studio 内のいかなる schema も spec に**追加**することはあっても**外す**ことはしない。

2. **frontmatter スキーマは spec の正規構造に従う**（フラット map ＋ unit suffix ＋ hyphen 連結 variant）：

   - **`colors: map<string, Color>`**：フラット map 必須。ネスト不可。token reference は `{colors.<token-name>}` 形式。複合パレットは hyphen 連結（例：`text-primary`, `text-secondary`, `coffee-espresso`, `interactive-default`）。`<token-name>` に slash・dot を含めない。

   - **`typography: map<string, Typography>`**：各 token に `fontFamily` / `fontSize` / `fontWeight` / `lineHeight` / `letterSpacing` / `fontFeature` / `fontVariation` をフラットに併記。`display` / `body` / `mono` のような category 分離 ＋ 別途 `scale` の構造は禁止。`h1` / `h2` / `body-md` / `body-sm` / `label-caps` / `label-md` / `code` 等の semantic 名で 9〜15 levels を作る（spec 推奨）。

   - **`spacing: map<string, Dimension | number>`**：array 表記禁止。`base` / `xs` / `sm` / `md` / `lg` / `xl` の map（unitless 値はカラム数・比率等の意味論を持つ場合のみ）。

   - **`rounded: map<string, Dimension>`**：`sm` / `md` / `lg` / `xl` / `full` 等の map。

   - **`components: map<string, map<string, string>>`**：2 階層必須。3 階層禁止。variant は **hyphen 連結**で 1 階層目に展開する（`button-primary`, `button-primary-hover`, `button-secondary`, `card`, `card-hover`, `chip-spec`, `chip-flavor` 等）。各 component の sub-token 値は literal もしくは token reference（`{colors.<name>}` / `{rounded.<name>}` / `{typography.<name>}` / `{spacing.<name>}`）。

3. **Dimension には `px` / `em` / `rem` の unit suffix を必須**。`fontSize: 14` のような unitless 数値は禁止（`lineHeight` のみ unitless multiplier を許容＝spec 推奨）。

4. **`shadows` / `motion` は YAML top-level に置かない**：

   - **shadows**：`## Elevation & Depth` セクションの prose で具体値を書き、`components.<component>.boxShadow: "0 1px 2px ..."` のように **components 内に literal 値で散らす**。横断的に共有したい場合は最初に登場した component の token を `{components.<first>.boxShadow}` 形式で参照する（spec が components 内 reference を許す）。

   - **motion**：YAML token として持たない。`## Motion`（Unknown section・spec の Section Order には無いため preserve 扱い・ADR-0030 で位置を確定）の prose で duration / easing を具体値で書く。実装側（CSS / Flutter 等）は prose を読んで実装する。

   - 理由：spec の `Unknown frontmatter top-level key` 挙動は Consumer Behavior table に未規定。consumer が無視するか拒否するか保証がないため、spec 正規 schema の中で表現することで互換性を最大化する。

5. **拡張 2 セクション（indie-studio）の位置と互換性**：

   - **`## Visual Theme & Mood`**：Overview 直後（Colors の前）。Unknown section heading として spec の `Preserve` 規約で受け入れ可。
   - **`## Voice & Tone`**：Components 後・Do's and Don'ts の前。同じく Unknown section preserve。
   - **`## Motion`**（決定 4 で導入）：Components 後（Voice & Tone と前後どちらでも可。SKILL.md で位置を固定）。
   - 拡張セクションは spec 正規 8 セクションの **間に挿入**する形で順序を保ち、正規セクションの順序入れ替えは禁止。
   - 重複見出し禁止（spec が reject）。

6. **section alias 表記＝英語単独セクション名**：

   - `## Components / コンポーネント` のスラッシュ併記は禁止（parser が見出し文字列全体で section 判定する実装で hit しないリスク）。
   - 見出しは英語単独（`## Components`）。日本語訳が必要な場合は見出し直後のリード文 1 行で `コンポーネント — <一行説明>` の形で書く。
   - spec 公式の `(also: 'X')` 形式（例：`## Layout (also: 'Layout & Spacing')`）は spec で alias を許容する正規セクションでのみ採用可（Overview / Layout / Elevation & Depth）。indie-studio 拡張セクションは alias を持たない。

7. **token reference の解決**：すべて `{<group>.<token-name>}` 形式（spec 準拠）。フラット map 必須化により `colors.text.primary` のような dotted path は存在せず、`{colors.text-primary}` が一意に解決可能。

## Considered Options

### A. shadows / motion の YAML top-level 保持

- **却下：`shadows` / `motion` を YAML top-level に残す**（現状 SCN-36 方式）。spec の Consumer Behavior table に top-level key の挙動が未規定で、claude.ai/design など spec 準拠 consumer の動作が保証されない。token として読まれない場合、現状の machine-readable token 化は無に帰す。
- **却下：拡張 prefix `x-shadows:` / `x-motion:`**。OpenAPI 等の convention に倣う案だが、spec に prefix convention の規定がなく consumer 挙動はやはり未規定。本質的な解決にならない。
- **却下：完全に prose に降ろす（components から参照もしない）**。spec section に綺麗に収まる反面、claude.ai/design 側で shadow 値を component に適用できなくなり、視覚的整合性が consumer 任せになる。
- **採用：ハイブリッド（決定 4）**。shadow は `## Elevation & Depth` の prose で書き、`components.<name>.boxShadow` に literal 散らし（横断参照は `{components.<first>.boxShadow}`）。motion は `## Motion` の prose のみ。spec 正規 schema を一切壊さない最大互換解。

### B. typography の構造

- **却下：category 分離 + scale 別出し（現状）**。`typography.display.fontFamily` + `typography.scale.lg: 17` のような構造は spec の `map<string, Typography>` ＝各 token にフラットに 6 プロパティを併記する規約と整合しない。token reference `{typography.h1}` で composite を引きたい component 側（spec の `Components > Component Property Tokens` で typography 参照を許容）の機能が壊れる。
- **採用：semantic 名でフラット map（決定 2）**。`h1`, `h2`, `body-md`, `body-sm`, `label-caps`, `label-md`, `code` 等で 9〜15 levels（spec 推奨）。

### C. section alias 表記

- **却下：スラッシュ併記 `## Components / コンポーネント`**。spec の Section Order は英語の正規名で記述されており、parser が見出し文字列全体で section 判定する実装の場合 hit しない。文字列マッチ精度のリスクを取らない。
- **却下：spec 公式 `(also: 'X')` 形式で日本語訳を併記**（`## Components (also: 'コンポーネント')`）。spec 公式の alias 表記は「Layout & Spacing」のような spec 内 alias 用で、各言語訳の用途に拡張するのは spec 解釈の越権。
- **採用：英語単独 + リード文で日本語訳**（決定 6）。parser 互換性と読み手向け日本語訳の両立。

### D. format 正本の選択

- **却下：自前 format 定義**。Google Labs `design.md` spec が事実上の標準（VoltAgent/awesome-design-md に 60+ ブランド実例、Claude / Cursor の自動認識）として確立済み（ADR-0023 で既決）。本 ADR では正本 pin の事実を確定するのみ。

## Consequences

- **影響範囲（SKILL / agent / mock 規約）**：
  - `indie-studio/skills/design-direction/SKILL.md`：frontmatter 例・規約・section alias 規約・shadows/motion の置き場所・拡張セクション順序を本 ADR の決定に揃える。
  - `indie-studio/agents/product-designer.md`：`mode=compose` の YAML 出力フォーマット・self-grill 観点を spec 準拠に揃える。
  - `indie-studio/agents/visual-designer.md`：マージ提案レポート（`## Colors` / `## Typography` 流し込み欄）を spec 準拠スキーマに揃える。
  - `indie-studio/agents/reviewer.md`：評価観点に「spec compliance（フラット map・unit suffix・hyphen variant・shadows/motion の YAML top-level 不使用）」を追加。

- **既存 DESIGN.md への影響**：本 ADR 適用前に旧 SKILL 規約で生成した DESIGN.md（socialcoffeenote `SCN-36` 等）は**新 format で再生成が必要**。これらの再生成は当該サービス repo の別 issue で対応する（claude-collections 内では本 PR 範囲外）。

- **claude.ai/design 等 consumer 側の挙動**：spec 準拠化により token parser が正常に動作し、Claude Design / Stitch / VoltAgent 系ツールで自動 component 生成が機能する見込み。

- **spec バージョン pin の運用**：frontmatter `version: alpha` を全 DESIGN.md で明示。spec が **alpha** のため breaking change 発生時は本 ADR を別 ADR で extends して再評価する。**再評価 trigger**：(a) Google Labs spec の `version` が `alpha` から変わったとき、(b) frontmatter schema / Section Order の規定が変わったとき、(c) Consumer Behavior の Unknown content 規約が変わったとき。

- **拡張セクションの将来追加**：indie-studio 拡張は現時点で `## Visual Theme & Mood` / `## Voice & Tone` / `## Motion` の 3 種。新規追加は本 ADR を extends する別 ADR で正規順序内の位置・preserve 互換性を確定してから行う。

- **ADR-0028 との関係**：DESIGN.md 自体は repo-root 配置（ADR-0028 で確定）で変更なし。本 ADR は format / schema の正本を確定するのみ。

## 未確定

- **複合 token reference の表現力**：spec の Components 内 reference が `{typography.h1}` のような composite を許す範囲は実装が evolving。複雑な component で typography 全体を引きたい場合の書き方は本 ADR では深掘りせず、spec 仕様の evolve に追従する。

- **claude.ai/design 側の実装挙動の実証**：spec 準拠化で実際に Claude Design 側の自動 component 生成が改善するかは、新 format で 1 サービス通した時点で実測して別 ADR or `## 未確定` 更新で記録する。

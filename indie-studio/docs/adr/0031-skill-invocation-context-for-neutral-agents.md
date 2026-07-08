# 中立 shared agent を dispatch する SKILL は invocation prompt に固有 context を明示する

claude-collections root の ADR-0004（shared-agent-vendoring 中立語彙原則）により、`shared/agents/` の職種 agent は collection 非依存の中立語彙で書かれ、body に indie-studio 固有値（stage 番号・`docs/indie-studio/...` パス・self-grill / 繰り越し protocol・タグ体系・観点 ⑤ 書式）を持たない。中立 agent は「入力契約」節で **呼び出し元 skill が mode / 上流成果物 / architecture 規約 / 出力先 / 進行 protocol / 評価観点 / タグ体系 を指定する** と宣言している（agent 側の中立化は正しく設計されている）。

一方、indie-studio の SKILL 側のディレクター制御フロー記述は、この入力契約の各項目を埋めきれていなかった。特に `tech-design`（S3）・`decomposition`（S4）は「スキル1 と同型。Agent tool で spawn」の一文で済ませ、invocation prompt の中身が未構造化だった。この状態で中立 agent を dispatch すると、agent が本スキルの stage / 出力先 / protocol / 観点を知らずに **劣化起動**する（crash ではない silent degradation。dogfood しないと表面化しない）。

参照：
- 関連 ADR: root ADR-0004（shared-agent-vendoring 中立語彙原則・本 ADR が対になる帰結）／ADR-0022（S1/S3 roster 実在職種）／ADR-0018（評価ループ・差し戻し protocol）／ADR-0019（決定記録 inline・繰り越しマーカー）／ADR-0024（観点 ⑤ 書式）／ADR-0027（tech-design 拡張・G3 スコアカード）
- 発見経緯: shared/agents/ 中立化（root PR #25）後の follow-up 精査で、中立 agent を dispatch する SKILL の invocation 記述の gap として特定

## Status

accepted（root ADR-0004 を extends する indie-studio 側の帰結。既存 SKILL の起動機構記述を強化するもので、フロー・ロスター・ゲート構造は変えない）

## 決定

中立 agent（`shared/agents/` 由来）を dispatch する各 SKILL の「ディレクター制御フロー」節に、**「起動 context（中立 agent への invocation 必須要素）」小節**を置く。中立 agent の入力契約項目（mode/stage・入力の所在・architecture 規約・出力先・進行 protocol・評価観点・タグ体系）に、その SKILL の indie-studio 固有値を 1:1 で埋める対応を明示する。

- 対象 SKILL と中立 agent:
  - `tech-design`（S3）: software-architect / tech-lead / infrastructure-engineer / security-engineer / principal-engineer
  - `decomposition`（S4）: engineering-manager / qa-engineer / principal-engineer
  - `implementation`（S5）: frontend / backend / mobile / infrastructure-engineer / code-reviewer / security-engineer / performance-engineer
  - `stack-direction`（S1a）: tech-lead / reviewer
  - `service-discovery`（S1）: reviewer のみ
  - `design-direction`（S1b）: reviewer のみ
- **product/design 系の独自 agent**（product-manager / product-designer / ux-researcher / visual-designer / ui-prototyper / business-strategist）は `indie-studio/agents/` の手書き agent で、stage / 出力先 / self-grill / 観点 ⑤ を body に持つため **対象外**（mode/area・所在の受け渡しで足りる）。
- 特に明示を要する核心値: architecture 規約（既定の型）／進行 protocol（decide-record-proceed・ADR-0019 inline・`⚠️繰り越し` マーカー）／接頭辞付き機能一覧 `F-{MODULE}-{連番}` 形式／タグ体系（HITL/AFK・根幹/非根幹）／評価観点セットと観点 ⑤ の適用対象／差し戻し protocol（round1 fresh→continuation・3R）。
- 表現形式は各 SKILL 内に置く（共通テンプレを外出ししない）。indie-studio SKILL の自己完結原則に従う。

## 影響

- 中立 agent が本スキルの固有 context を prompt から受け取って起動するため、silent degradation が構造的に解消される。
- shared/agents/ を将来さらに中立化しても、SKILL 側の起動 context 小節が「何を渡すべきか」の真実源になるため、agent body と SKILL の責務分界が明確になる。
- 新しく中立 agent を dispatch する SKILL を追加する際は、本 ADR に従い起動 context 小節を必須とする（漏らすと degradation）。
- SKILL.md がやや冗長になるが、invocation の受け渡しは agent の入力契約と対で読めるため保守性はむしろ上がる。

## 検討した代替案

- **agent body に indie-studio 固有 context を戻す**: root ADR-0004 の中立語彙原則に反し、vendoring（複数 collection での再利用）を壊す。却下。
- **agent に「SKILL.md の該当節を読め」と参照させる**: 間接的で脆い（agent が別 context で SKILL 全体を読む負荷・参照先ずれ）。invocation prompt に直接埋める方が明快。却下。
- **共通テンプレを 1 箇所（ADR / 共通 doc）に外出しし SKILL は参照のみ**: DRY だが indie-studio SKILL の自己完結原則に反し、SKILL 単体で読めなくなる。核心値は各 SKILL で異なる（出力先・stage・観点対象）ため共通化の利得も薄い。却下。

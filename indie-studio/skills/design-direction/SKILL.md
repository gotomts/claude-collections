---
name: design-direction
description: service-discovery スキル(ステージ1)が出した brief / persona / feature-scope / screen-specs などの discovery corpus と、任意の参考画像（UI スクショ・風景・絵画・写真など）を入力に、Claude Design に渡すための具体デザイン憲法 DESIGN.md と HTML mock を組み上げたいときに使う、AI 自律開発ハーネスのサブステージ S1b スキル。上流＝S1a stack-direction（スタック確定済）、下流＝S2 プロトタイプ（Claude Design）。Google Labs design.md spec (alpha) に pin した 8 セクション + indie-studio 拡張 3 セクション (Visual Theme & Mood / Voice & Tone / Motion) で書く。reviewer 合格後に ui-prototyper が HTML mock を 1 ファイル統合で生成し、人間視覚確認ゲート（最大 2 ループ）を経て S2 へ渡す。新規 DESIGN.md 起こしと既存 DESIGN.md の方向性更新の両方に使う。画面詳細(screen-specs)・プロトタイプ生成自体・技術設計は下流スキルの責務でここでは扱わない。
maintainer: gotomts
---

# design-direction

AI 自律開発ハーネスの **サブステージ S1b（S1 / S1a 後段 → S2 入力起こし）** スキル。実行環境は **Claude Code**。このスキルを読んだメインセッションが**ディレクター**となり、人間と「雰囲気」を 3 問対話で握り、参考画像があれば視覚的に mood / palette / typography を抽出して、**具体値＋禁止事項**で書かれた `DESIGN.md`（デザイン憲法）と、token を CSS variable に 1:1 写像した HTML mock を組み上げる。

到達点：**「アンカー → 触れるプロトタイプの直前」までを、最少 3 問の direction-pick + 1 回（最大 2 回）の mock 視覚確認だけで、AI デフォルト3種に陥らず、Claude Design が全画面で統一感を保てる具体憲法 ＋ 視覚で妥当性を握れる mock に落とす**。質は対話量ではなく self-grill + AI-defaults critique + 視覚確認の徹底度から出す（ADR-0004 / 0005 / 0020 / 0023 / 0029 / 0030）。

**format 正本**：DESIGN.md は **Google Labs `design.md` spec (alpha) に pin**（ADR-0029）。frontmatter スキーマ・section alias・shadows / motion の扱い・拡張セクション位置は本 SKILL.md の規約に従う（spec 違反は reviewer の blocker findings になる）。

## いつ使うか

- `service-discovery`（S1）が完了し、`docs/indie-studio/discovery/` に anchors + planning + design (screens.md / screen-specs) が揃った状態で、Claude Design に渡すための **DESIGN.md がまだ無い** とき。
- 既存 DESIGN.md の方向性を再検討したいとき（mood の方針変更、参考画像の追加）。
- ハーネスのサブステージ S1b として、S1a と S2 の間で人間が起動するとき。

**ここで扱わないこと**：screen-specs（S1 product-designer 担当）／スタック・3rd party 制約・build vs buy（上流 S1a stack-direction）／プロトタイプ生成そのもの（Claude Design＝claude.ai・S2）／技術設計・分解・実装（S3〜S5）。

## ステージ構造

```text
S1 完了（anchors + planning + design/screens.md / screen-specs）
  → direction-pick 対話（3問・type-2 人間ゲート）
  → 画像 ingest（任意・画像なしも可）
  → token plan（color / type / layout / signature）
  → AI-defaults critique（陥落チェック）
  → compose DESIGN.md（Google Labs spec pin + indie-studio 拡張 3 セクション）
  → reviewer 評価ループ（最大3R・spec compliance 含む）
  → HTML mock 生成（ui-prototyper・token を CSS variable に 1:1 写像）
  → 視覚確認ゲート（type-2 人間ゲート・最大 2 ループ・自由記述許容）
  → ⚠️繰り越し提示
  → 人間が claude.ai（Claude Design）へ ← このスキルの終端
```

- 各点の「決める／検証する」は人間、**書くのは AI**（ADR-0012）。
- 3 問対話は **G1 アンカー対話と独立** の type-2（人間が方向を決め AI が書く）。アンカーは決め直さない。

## 入力

S1 成果物（必須）と参考画像（任意）：

| 区分 | 中身 | 場所 |
|---|---|---|
| 必須 | アンカー（PRFAQ・デザイン原則・提供形態・マネタイズ二値） | `docs/indie-studio/discovery/anchors/` |
| 必須 | feature-scope・persona | `docs/indie-studio/discovery/planning/` |
| 推奨 | screens.md / screen-specs | `docs/indie-studio/discovery/design/` |
| 任意 | 参考画像 0〜N 枚（UI スクショ・風景・絵画・写真・ブランド写真等） | チャット添付 or path 指定 |

**S1a 出力**（推奨）：`docs/indie-studio/tech/stack-direction/stack.md` ・ `build-vs-buy.md` を `## Components` 記述の前に読む。提供形態と build vs buy の整合が取れる（ADR-0026）。S1a が未起動なら `anchors/provider.md` のみから推測する暫定運用（精度低）。

参考画像は UI に限らない。**mood / palette / typography vibe を握るための視覚資料**であれば形式不問。**0 枚も可**（design-principles のトーン記述からのみ起こす fallback モード）。

## 出力

主成果物は 2 つ：

1. **`<service-repo>/DESIGN.md`**（**repo-root**・ADR-0020）：Google Labs `design.md` spec (alpha) 準拠（ADR-0029）。
2. **`<service-repo>/docs/indie-studio/design-direction/mock/<service-slug>-design-mock.html`**：1 ファイル統合の HTML mock（ADR-0030）。

### DESIGN.md frontmatter（spec pin・ADR-0029）

```yaml
---
version: alpha
name: <service>
description: <philosophy 1行>
colors:                          # map<string, Color> フラット必須・ネスト禁止
  primary: "#1A1C1E"
  secondary: "#6C7278"
  tertiary: "#B8422E"
  neutral: "#F7F5F2"
  surface: "#FFFFFF"
  text-primary: "#1A1C1E"        # 複合パレットは hyphen 連結
  text-secondary: "#6C7278"
  interactive-default: "#009DBF"
typography:                       # map<string, Typography> ・各 token にフラットに 6 プロパティ
  h1:
    fontFamily: "Inter"
    fontSize: 30px                # ★ Dimension は px/em/rem 必須
    fontWeight: 600
    lineHeight: 1.25
    letterSpacing: -0.02em
  body-md:
    fontFamily: "Inter"
    fontSize: 16px
    fontWeight: 400
    lineHeight: 1.5
  label-caps:
    fontFamily: "JetBrains Mono"
    fontSize: 12px
    fontWeight: 500
    letterSpacing: 0.1em
rounded:                          # map<string, Dimension>
  sm: 4px
  md: 8px
  lg: 12px
  full: 9999px
spacing:                          # map<string, Dimension | number> ・array 表記禁止
  base: 4px
  xs: 4px
  sm: 8px
  md: 16px
  lg: 32px
  xl: 64px
components:                       # map<string, map<string, string>> 2 階層必須
  button-primary:                 # variant は hyphen 連結（3 階層禁止）
    backgroundColor: "{colors.primary}"
    textColor: "{colors.surface}"
    rounded: "{rounded.md}"
    padding: 12px
  button-primary-hover:
    backgroundColor: "{colors.secondary}"
  card:
    backgroundColor: "{colors.surface}"
    rounded: "{rounded.lg}"
    padding: 16px
    boxShadow: "0 1px 2px rgba(0,0,0,0.04)"   # shadow は components 内 literal で散らす
  card-hover:
    boxShadow: "{components.card.boxShadow}"  # 横断参照は最初の component を refer
---
```

### 本文セクション順（spec 正規 8 + indie-studio 拡張 3）

```text
## Overview                # [必須] philosophy / vibe（prose 最上段）
## Visual Theme & Mood     # [必須] ★indie-studio 拡張：参考画像/mood の言語化（specific reference 必須）
## Colors                  # [必須] named hex/oklch + 用途
## Typography              # [必須] 6 プロパティ semantic 名（h1 / body-md / label-caps 等で 9-15 levels）
## Layout                  # [必須] base unit + 8 段階 scale（unit suffix 必須）
## Elevation & Depth       # [必須] shadow の具体値（prose） + components 内 literal 値で散らす
## Shapes                  # [必須] radii / border
## Components              # [必須] 2 階層 + variant hyphen 連結。**S1a `stack-direction` の `stack.md`（提供形態）と `build-vs-buy.md`（SaaS 採用箇所）を読んでから書く**（ADR-0026）
## Motion                  # [条件付き] ★indie-studio 拡張：実装で motion を使うなら必須（reduced-motion fallback を含む）、使わないなら省略可。duration / easing の具体値（prose のみ・YAML token 化しない）
## Voice & Tone            # [条件付き] ★indie-studio 拡張（コピー語彙の規律が要るなら必須、ロゴ単体等なら省略可）
## Do's and Don'ts         # [必須] anti-pattern（最後）
```

**mandatory（9 セクション） vs conditional（2 セクション）の区別**：

- **mandatory（必ず生成）**：Overview / Visual Theme & Mood / Colors / Typography / Layout / Elevation & Depth / Shapes / Components / Do's and Don'ts
- **conditional（要件が成立するときのみ生成）**：Motion（実装で motion を使うなら必須）・Voice & Tone（コピー語彙の規律が要るなら必須）

条件付きの省略は理由付き `➖省略(理由)` で完全性ガードに集計する（黙って端折らない）。

### format 規約（ADR-0029）

- **section alias は英語単独**：`## Components` のように英語単独で書き、日本語訳は見出し直後のリード文 1 行で `コンポーネント — <一行説明>` の形で提供。`## Components / コンポーネント` のスラッシュ併記は禁止（parser hit リスク）。
- **prose first, tokens second**（ADR-0020）。What / Why / How で短く（各 2-3 文上限）。
- **token reference**：`{<group>.<token-name>}` 構文（spec 準拠）。フラット map 必須により `{colors.text-primary}` の形で解決。
- **重複見出し禁止**（spec linter で reject）。
- **shadows は YAML top-level に置かない**：`## Elevation & Depth` セクションの prose で具体値を書き、`components.<name>.boxShadow` に literal で散らす。横断共有は `{components.<first>.boxShadow}` で refer。
- **motion は YAML token 化しない**：`## Motion` セクション（Unknown section preserve）の prose で duration / easing を具体値で書く。実装側（CSS / Flutter 等）は prose を読む。
- **拡張セクション位置**：`## Visual Theme & Mood` は Overview 直後、`## Motion` と `## Voice & Tone` は Components 後・Do's and Don'ts の前（順序は SKILL.md 規約で固定）。
- **Unknown section preserve**：サービス都合で `## Iconography` 等の追加は可（spec 互換）。ただし正規 8 セクションの順序入れ替えは禁止。

## ロスターと依存順

ディレクター（＝スキル本体）が、4 つの職種エージェントを **依存順** に起動する（ADR-0013 共通形・ADR-0022 拡張・ADR-0030 で ui-prototyper 追加）。

| エージェント | 担当成果物 | 依存 |
|---|---|---|
| `product-designer` | direction-pick 対話 → token plan → DESIGN.md compose | S1 成果物・visual-designer 出力 |
| `visual-designer` | 参考画像 → mood / palette / typography vibe の構造化抽出 | 参考画像（画像なし時は fallback） |
| `reviewer` | DESIGN.md draft の評価・差し戻し（独立職種・mock は評価対象外） | DESIGN.md draft |
| `ui-prototyper` | reviewer 合格版 DESIGN.md → HTML mock 生成（token を CSS variable に 1:1 写像） | DESIGN.md（reviewer 合格版）・screens.md |

依存順：direction-pick → 画像 ingest（あれば、direction-pick と並列可）→ token plan → AI-defaults critique → compose → reviewer → **mock 生成（ui-prototyper）→ 視覚確認ゲート**。

## ディレクター制御フロー

**起動機構**：ディレクター（＝スキル本体のメインセッション）は各職種を **Agent tool**（`subagent_type` ＝ エージェントファイル名：`product-designer` / `visual-designer` / `reviewer` / `ui-prototyper`）で spawn する。プロンプトに mode・S1 成果物の所在・参考画像 path（あれば）・既存 DESIGN.md draft の所在（あれば）を渡す。差し戻しは**同じ職種を continuation で再起動**（findings を渡す・ADR-0018）。

**期待マニフェスト**（完全性ガードの基準）：

- **DESIGN.md の必須要素**：
  - **mandatory（必ず生成・YAML frontmatter ＋ 9 セクション）**：YAML frontmatter ／ Overview ／ Visual Theme & Mood ／ Colors ／ Typography ／ Layout ／ Elevation & Depth ／ Shapes ／ Components ／ Do's and Don'ts。
  - **conditional（要件が成立するときのみ生成・2 セクション）**：`## Motion`（実装で motion を使うなら必須・reduced-motion fallback を含む）、`## Voice & Tone`（コピー語彙の規律が要るなら必須、ロゴ単体等なら省略可）。
  - 各要素を ✅生成 / ➖省略(理由) / ⚠️未達(理由) で決着。conditional の省略は理由付き `➖` で扱う（mandatory の省略は `⚠️未達` で扱う）。
- **HTML mock の必須要素** ＝ CSS `:root` の token 写像（DESIGN.md YAML を 1:1 kebab-case で）＋ Component gallery（button / card / chip / badge / input / FAB 等の全 variant）＋ 主要画面 1〜2 枚（`[MVP]` × `priority: high` から feature-scope 最大被覆）。

**並列/直列**：画像 ingest（visual-designer）と direction-pick 序盤の anchors / design-principles 読み込みは並列可。token plan 以降は直列（compose は単一ファイル DESIGN.md への書き込みのため）。mock 生成は reviewer 合格後の直列ステップ（DESIGN.md と並列に書かない）。

1. **direction-pick 対話**（人間ゲート・type-2）：`product-designer` を `mode=direction-pick` で spawn し、3 問の一問一答で direction を 1 つに絞る（後述）。3 問で握れない場合は decide-record-proceed（候補を ⚠️繰り越しで残す）。
2. **画像 ingest**（任意・並列可）：参考画像があれば `visual-designer` を `mode=extract` で spawn し、画像から mood / palette / typography vibe を構造化抽出。画像なしは `mode=tone-fallback` で design-principles のみから記述子抽出。
3. **token plan**：`product-designer` を `mode=compose` で continuation 再起動し、color 4-6 hex（named）/ type 2+ roles / spacing scale / radius / signature element を内製。
4. **AI-defaults critique**（自己 critique・必須）：plan が AI デフォルト3種に陥っていないか自答（後述）。陥っていれば plan に戻す。
5. **compose DESIGN.md**：`product-designer` continuation で、YAML frontmatter ＋ **mandatory 9 セクション**（必須）＋ **conditional 2 セクション**（要件が成立するときのみ）を **spec pin フォーマット**（ADR-0029）で `<service-repo>/DESIGN.md` に書く。フラット map / unit suffix / hyphen variant / 英語単独セクション名を守る。shadows は components 内 literal、motion は `## Motion` prose のみ。
6. **reviewer 評価ループ**（ADR-0018）：`reviewer` を spawn（fresh）し、DESIGN.md の findings を完全マニフェストで返させる（**spec compliance** を評価観点に含む）。最大 3 ラウンド差し戻し。round2-3 は continuation で凍結スコープ確認のみ。finding ごとに ✅解消 ／ ➖省略(理由) ／ ⚠️未達(理由) を決着。**mock は reviewer の評価対象外**（次ステップで別軸として視覚確認する）。
7. **HTML mock 生成**（ADR-0030）：`ui-prototyper` を `mode=mock` で spawn（fresh）。reviewer 合格版 DESIGN.md と `screens.md` を入力に、Component gallery + 主要 1〜2 画面 hybrid を 1 ファイル統合で `<service-repo>/docs/indie-studio/design-direction/mock/<service-slug>-design-mock.html` に書き出す。token は CSS custom property に 1:1 kebab-case 写像。
8. **視覚確認ゲート**（人間ゲート・type-2・最大 2 ループ・ADR-0030）：ディレクターが mock の path を提示し、人間に「1) OK（S2 へ進む） 2) 戻る（修正したい）」の 1 問を投げる。
   - **OK** → ステップ 9 へ。
   - **戻る**（自由記述許容）：ディレクターが回答を DESIGN.md の該当 token / セクションにマップし、`product-designer` を `mode=compose` で continuation 再起動して token を修正。その後 `ui-prototyper` を continuation で再起動して mock 再生成。再ゲート。
   - **2 ループ目も「戻る」** → decide-record-proceed。論点を `⚠️繰り越し` マーカーで `## Visual Theme & Mood` または該当セクションに inline 残し、S2 G2 で人間が確定する論点として送る。
9. **完全性ガード**（ADR-0011）：期待マニフェストの各セクション ＋ mock の必須要素を ✅ / ➖ / ⚠️ で決着。
10. **⚠️繰り越し提示**（ADR-0019）：3 問で握れなかった direction 候補・画像から複数 mood が出た場合の択一・視覚確認ゲートで未決着の論点など、繰り越し inline マーカーを集めてディレクターが終端でレポート提示。プロトを触ってから G2 で確定する論点として残す。

## direction-pick 対話（3 問・人間ゲート）

3 問の一問一答で direction を 1 つに絞る。各問は **yes / no か番号** で答えられるよう必ず選択肢化する（一問一答規律）。

**デフォルト 3 軸**（`product-designer` はサービス性質に応じて差し替え可）：

1. **温度**：1) warm（暖色寄り・親しみ） 2) cool（寒色寄り・正確）
2. **密度**：1) spacious（余白多・1 ビュー 1 要点） 2) dense（情報密集・1 ビュー 多要点）
3. **形式性**：1) playful（手書き／不揃いを許容） 2) precise（規律的・幾何学的）

各問の前に **推奨**（design-principles と feature-scope から判断した推奨 1 行＋理由 1 行）を提示してから尋ねる。3 問終了後に direction を 1 行で要約して**最終確認**（yes / no）。

サービス性質や design-principles と合わない軸が混じる場合、軸自体を差し替えてよい（例：B2B ツールでは「形式性」より「権威性」軸の方が有効）。差し替えた場合は理由を 1 行で説明する。

**握れない場合**：3 問で割れる軸は ⚠️繰り越しマーカーとして DESIGN.md `## Visual Theme & Mood` に候補併記で残し、プロトで両側を見せる前提で進める。

## 画像 ingest（visual-designer の役割）

参考画像があれば `visual-designer` に渡す。画像は：

- **UI スクショ**：typography・layout・component vibe を抽出。
- **風景・絵画・写真・プロダクト写真等**：palette・atmosphere・形容詞群を抽出。

`visual-designer` は Claude Vision で画像を読み、**構造化抽出レポート**（中間データ、別ファイル化しない）を product-designer に返す。形式と規律は `visual-designer.md` 参照。

**画像入力経路**：ユーザーが Claude Code チャットに直接添付（Vision API）／または絶対 path 指定。**画像ピクセルは repo に commit しない**（容量・著作権リスク）。出典・パスは DESIGN.md `## Visual Theme & Mood` 内に記載のみ。

## HTML mock 生成（ui-prototyper の役割・ADR-0030）

`ui-prototyper` は reviewer 合格版の DESIGN.md と `screens.md` を入力に、1 ファイル統合の HTML mock を生成する。token を CSS custom property に 1:1 kebab-case で写像し、視覚で direction の妥当性を確認できる「実体」を作る。担い手は **UI プロトタイパー（実在職種）**で、`product-designer`（DESIGN.md compose 担当）とは職務スコープを分離する（試し作りで見せる専任）。

**構造（hybrid・1 ファイル統合）**：

1. **`:root` の CSS variable 写像**：DESIGN.md frontmatter の YAML token を CSS custom property に 1:1 kebab-case で写す（`colors.text-primary` → `--color-text-primary`、`components.button-primary.backgroundColor` → `--button-primary-background-color` 等。**property 名は短縮しない**＝1:1 reversible mapping のため）。shadows / motion は DESIGN.md の prose を読んで CSS variable 化する（`--shadow-sm` / `--motion-quick-duration` 等）。
2. **Component gallery**：button / card / chip / badge / input / FAB の **全 variant**（primary / secondary / icon / destructive・hover / focus / disabled・public / private / draft 等）を並べて表示。
3. **主要画面 1〜2 枚**：`screens.md` から `[MVP]` × `priority: high` × **feature-scope の `[作る]` 機能を最大被覆**する screen を選ぶ。該当画面がない場合は area prefix の core から 1〜2 枚（**最大 2 枚まで**＝Component gallery + 1〜2 key screens の hybrid 構成と整合）。
4. **device frame**：iPhone 14 Pro 390×844 / Android Pixel 7 412×915 等の viewport で枠を見せる（proto-fidelity 表現）。

**配置先**：`<service-repo>/docs/indie-studio/design-direction/mock/<service-slug>-design-mock.html`（ADR-0028 namespace + ADR-0030）。複数 mock を作る場合は `<service-slug>-design-mock-<screen>.html`。

**self-grill 観点**：

- CSS variable 写像が DESIGN.md YAML と齟齬していないか（命名・値）。
- shadows / motion の prose 値を `:root` で variable 化しているか（DESIGN.md prose → mock CSS variable の写像規律）。
- Component gallery で全 variant を網羅しているか（黙って 1 つでも端折ると視覚妥当性が握れない）。
- 主要画面選定が feature-scope 被覆の根拠を持っているか（恣意的選択は self-grill で却下）。
- 画像・動画・外部送信を含まないか（DESIGN.md 方針継承）。

## 視覚確認ゲート（ADR-0030・人間 type-2 ゲート・最大 2 ループ）

`direction-pick` 3 問と並ぶ、S1b の人間ゲート。reviewer 合格後・S2 直前に置く。

**手順**：

1. ディレクターが mock の path を 1 行で提示（例：「mock を生成しました：`docs/indie-studio/design-direction/mock/<service-slug>-design-mock.html`」）。
2. **1 問**：「mock を確認しました：1) OK（S2 へ進む） 2) 戻る（修正したい）」。一問一答（自由記述で来た場合は番号化を促してリトライ、提示済み選択肢にマップ可能なら自動マップしつつ確認を取ってよい）。
3. **OK** → ⚠️繰り越し提示 → S2 へ。
4. **戻る** → 「何を直したいですか？」を自由記述で受け取る（Claude Code チャット環境で番号制約を物理的にかけられない代替）。回答が来たら、ディレクターが **DESIGN.md の該当 token / セクションにマップ**してから `product-designer` を `mode=compose` で continuation 再起動。token / セクション修正後、`ui-prototyper` を continuation で再起動して mock 再生成。再ゲート。
5. **2 ループ目も「戻る」** → decide-record-proceed。論点を `⚠️繰り越し` マーカーで `## Visual Theme & Mood` または該当セクションに inline 残す。S2 G2 で人間が確定する論点として送る。**3 ループ目には進まない**（infinite-tweak 防止）。

**collateral damage 防止**：1 ループ目の修正が他セクションに矛盾を生んでいないか、`ui-prototyper` が mock 再生成時に self-grill で確認する。矛盾を発見した場合は finding として director に報告（mock 内のコメントではなく対話で返す）。

## AI-defaults critique（必須・陥落チェック）

`frontend-design`（anthropics/skills）／ Google Labs PHILOSOPHY.md 由来の AI 失敗パターン 3 種に、token plan が陥っていないかセルフチェック。1 つでも該当したら plan に戻す。

1. **warm-cream（#F5F0E8 系）＋ terracotta／serif 1 種類**：「上品な手書き notepad」風で全 AI が陥る。
2. **black 背景 + acid green / cyan アクセント**：「ハッカー風 / 未来 SaaS」風で全 AI が陥る。
3. **broadsheet 黒 hairline + 大きな serif 見出し**：「上質な新聞 / マニフェスト」風で全 AI が陥る。

陥落していれば、`## Visual Theme & Mood` の specific reference に**逆方向**の固有名（例：陥落＝broadsheet なら「Memphis Group」「Fluxus poster」等）を追加し、palette / typography を見直す。

## self-grill・decide-record-proceed・繰り越し

- **self-grill**（ADR-0005）：各職種は griller と answerer を兼ね、anchors（特に design-principles）と feature-scope を答え合わせ材料に自答する。人間に質問を投げない（停止しない）。**例外は 2 つ**：(a) direction-pick 3 問の人間対話（type-2・product-designer 担当）、(b) 視覚確認ゲートの 1 問対話（type-2・ディレクター直轄・ADR-0030）。両方とも人間が方向を決め AI が書く構造。
- **decide-record-proceed**（ADR-0004）：3 問で握れない軸・画像で割れる候補は、根拠ある仮決を下し、根拠を DESIGN.md `## Visual Theme & Mood` に inline で残して進む。専用の決定ログ file は作らない（ADR-0019）。
- **繰り越し決定**（ADR-0019）：プロトを触ってから決めたい論点は ⚠️繰り越しマーカー＋候補で inline 残し、ディレクターが終端で集約レポート提示。G2 で人間が確定する。

## 出力レイアウト

```text
<service-repo>/
├── DESIGN.md                                # 本スキルの主成果物その 1（repo-root・ADR-0020）
└── docs/
    └── indie-studio/
        ├── discovery/                       # S1 成果物（読むだけ）
        └── design-direction/
            └── mock/
                └── <service-slug>-design-mock.html  # 本スキルの主成果物その 2（ADR-0030）
```

- DESIGN.md は **repo-root** に置く（ADR-0020）。`docs/indie-studio/discovery/design/` 配下には置かない。
- HTML mock は `docs/indie-studio/design-direction/mock/` 配下に置く（ADR-0028 namespace + ADR-0030）。repo-root には置かない（service repo 固有のドキュメントと混在防止）。
- `visual-designer` の中間抽出レポート（画像ごとの構造化出力）は DESIGN.md `## Visual Theme & Mood` 本文に**取り込み**、別ファイルとしては残さない（二重管理回避）。
- 参考画像そのものは repo に commit しない（容量・著作権リスク）。出典・パスは DESIGN.md 内に記載する。
- HTML mock に画像ファイル・動画ファイルを embed しない。emoji / SVG / unicode は許容。フォントは Google Fonts CDN（preconnect 経由）・OS フォントを推奨。

## 品質バー（端折り禁止）

- 「minimal」は人間の入力最小化を指し、**導出物の最小化ではない**（ADR-0011）。mandatory 9 セクション + mock の必須要素を端折らない。conditional 2 セクション（Motion / Voice & Tone）の省略は ➖省略(理由) で完全性ガードに通す。
- 抽象語で止めない（"modern" / "clean" / "trustworthy" → 具体トークンと specific reference まで）。
- DESIGN.md は **prose first, tokens second**（Google Labs PHILOSOPHY.md）。トークン値だけのファイルにしない。
- 形容詞列挙の罠を避ける：必ず 1 つは固有名（人物・作品・年代・出典）を出す。
- **spec compliance を破らない**（ADR-0029）：フラット map / unit suffix 必須 / hyphen variant / 英語単独セクション名 / shadows・motion の YAML top-level 不使用。違反は reviewer の blocker findings。
- **mock は token と齟齬しない**（ADR-0030）：CSS variable 写像と DESIGN.md YAML が 1:1 で対応する。mock が "盛って" DESIGN.md にない token を独自定義しない。

## 破壊的操作の禁止

- push / PR / merge / 課金 / 外部送信はしない。repo へのファイル書き込みと commit に留める。
- アンカー（`docs/indie-studio/discovery/anchors/`）は決め直さない（G1 で確定済み・読むだけ）。
- screen-specs（`docs/indie-studio/discovery/design/screen-specs/`）は触らない（S1 `product-designer` 担当・並列ジョブ競合回避）。
- 画像ピクセルを repo に commit しない（出典は path のみ DESIGN.md 内記載）。
- mock html に画像ファイル・動画ファイルを embed しない（emoji / SVG / unicode は許容）。

## 前提・後段

- **前提**：`S1 service-discovery` 完了（`docs/indie-studio/discovery/` 一式）＋ `S1a stack-direction` 完了（`docs/indie-studio/tech/stack-direction/{stack,data-profile,third-party,build-vs-buy}.md`）。
- **後段**：`S2` プロトタイプ（Claude Design＝claude.ai）。DESIGN.md ＋ mock html を持って claude.ai に渡る（mock は視覚妥当性の参照、Claude Design への直接入力は DESIGN.md）。

## 関連 ADR

スキル追加判断＝ADR-0023。DESIGN.md＝ADR-0020（決定 5 resolved）。**format spec pin＝ADR-0029（Google Labs `design.md` alpha に pin・shadows/motion・section alias）**。**HTML mock step + ui-prototyper agent＝ADR-0030**。共通形＝ADR-0013。評価ループ＝ADR-0018。決定記録＝ADR-0019。ロスター＝ADR-0022 拡張（`visual-designer` 追加・`product-designer` 拡張・**ADR-0030 で `ui-prototyper` 追加**）。出力位置＝ADR-0020（DESIGN.md）／ADR-0028 + ADR-0030（mock）。サブステージ命名＝ADR-0025。

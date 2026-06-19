---
name: design-direction
description: service-discovery スキル(ステージ1)が出した brief / persona / feature-scope / screen-specs などの discovery corpus と、任意の参考画像（UI スクショ・風景・絵画・写真など）を入力に、Claude Design に渡すための具体デザイン憲法 DESIGN.md を組み上げたいときに使う、AI 自律開発ハーネスのステージ1.5スキル。Google Labs design.md spec の8セクション+indie-studio 拡張2セクション(Visual Theme & Mood / Voice & Tone)で書く。新規 DESIGN.md 起こしと既存 DESIGN.md の方向性更新の両方に使う。画面詳細(screen-specs)・プロトタイプ生成自体・技術設計は下流スキルの責務でここでは扱わない。
maintainer: gotomts
---

# design-direction

AI 自律開発ハーネスの **ステージ1.5（S1 後段 → S2 入力起こし）** スキル。実行環境は **Claude Code**。このスキルを読んだメインセッションが**ディレクター**となり、人間と「雰囲気」を 3 問対話で握り、参考画像があれば視覚的に mood / palette / typography を抽出して、**具体値＋禁止事項**で書かれた `DESIGN.md`（デザイン憲法）を組み上げる。

到達点：**「アンカー → 触れるプロトタイプの直前」までを、最少 3 問の対話＋任意の画像入力だけで、AI デフォルト3種に陥らず、Claude Design が全画面で統一感を保てる具体憲法に落とす**。質は対話量ではなく self-grill + AI-defaults critique の徹底度から出す（ADR-0004 / 0005 / 0020 / 0023）。

## いつ使うか

- `service-discovery`（S1）が完了し、`docs/discovery/` に anchors + planning + design (screens.md / screen-specs) が揃った状態で、Claude Design に渡すための **DESIGN.md がまだ無い** とき。
- 既存 DESIGN.md の方向性を再検討したいとき（mood の方針変更、参考画像の追加）。
- ハーネスの5スキル（ADR-0017 / ADR-0023）の **1.5番目** として、S1 と S2 の間で人間が起動するとき。

**ここで扱わないこと**：screen-specs（S1 product-designer 担当）／プロトタイプ生成そのもの（Claude Design＝claude.ai・S2）／技術設計・分解・実装（S3〜S5）。

## ステージ構造

```
S1 完了（anchors + planning + design/screens.md / screen-specs）
  → direction-pick 対話（3問・type-2 人間ゲート）
  → 画像 ingest（任意・画像なしも可）
  → token plan（color / type / layout / signature）
  → AI-defaults critique（陥落チェック）
  → compose DESIGN.md（Google Labs spec + indie-studio 拡張）
  → reviewer 評価ループ（最大3R）
  → ⚠️繰り越し提示
  → 人間が claude.ai（Claude Design）へ ← このスキルの終端
```

- 各点の「決める／検証する」は人間、**書くのは AI**（ADR-0012）。
- 3 問対話は **G1 アンカー対話と独立** の type-2（人間が方向を決め AI が書く）。アンカーは決め直さない。

## 入力

S1 成果物（必須）と参考画像（任意）：

| 区分 | 中身 | 場所 |
|---|---|---|
| 必須 | アンカー（PRFAQ・デザイン原則・提供形態・マネタイズ二値） | `docs/discovery/anchors/` |
| 必須 | feature-scope・persona | `docs/discovery/planning/` |
| 推奨 | screens.md / screen-specs | `docs/discovery/design/` |
| 任意 | 参考画像 0〜N 枚（UI スクショ・風景・絵画・写真・ブランド写真等） | チャット添付 or path 指定 |

参考画像は UI に限らない。**mood / palette / typography vibe を握るための視覚資料**であれば形式不問。**0 枚も可**（design-principles のトーン記述からのみ起こす fallback モード）。

## 出力

`<service-repo>/DESIGN.md`（**repo-root**・ADR-0020）。Google Labs `design.md` spec の正規セクション順に indie-studio 拡張 2 セクションを入れる：

```yaml
---
version: alpha
name: <service>
description: <philosophy 1行>
colors: { primary: "#xxxxxx", ... }
typography: { display: { fontFamily: "...", fontSize: "...", ... }, body: { ... } }
rounded: { ... }
spacing: { base: 4, scale: [4, 8, 12, 16, 24, 32, 48, 64] }
components: { button: { ... }, card: { ... } }
---

## Overview                # philosophy / vibe（prose 最上段、必須）
## Visual Theme & Mood     # ★indie-studio 拡張：参考画像/mood の言語化（specific reference 必須）
## Colors                  # named hex/oklch + 用途
## Typography              # 6プロパティ：fontFamily / fontSize / fontWeight / lineHeight / letterSpacing / fontFeature
## Layout                  # base unit + 8段階 scale
## Elevation & Depth       # shadow tokens
## Shapes                  # radii / border
## Components              # 主要コンポーネント（button / card / input 等）
## Voice & Tone            # ★indie-studio 拡張（コピー語彙・呼称規約。サービス性質次第で省略可）
## Do's and Don'ts         # anti-pattern（最後）
```

- prose（散文）が主、tokens（YAML）が context（ADR-0020）。What / Why / How で短く（各 2-3 文上限）。
- トークン間参照は `{colors.primary}` 構文（spec.md 準拠、後段で linter 解決可）。
- **重複見出し禁止**（spec linter で reject）。日本語訳併記時は `## Colors / カラー` のように 1 見出しに統合。
- 未知セクション保持規約に従い、サービス都合で `## Motion` 等の追加は可（spec 互換）。

## ロスターと依存順

ディレクター（＝スキル本体）が、3 つの職種エージェントを **依存順** に起動する（ADR-0013 共通形・ADR-0022 拡張）。

| エージェント | 担当成果物 | 依存 |
|---|---|---|
| `product-designer` | direction-pick 対話 → token plan → DESIGN.md compose | S1 成果物・visual-designer 出力 |
| `visual-designer` | 参考画像 → mood / palette / typography vibe の構造化抽出 | 参考画像（画像なし時は fallback） |
| `reviewer` | DESIGN.md draft の評価・差し戻し（独立職種） | DESIGN.md draft |

依存順：direction-pick → 画像 ingest（あれば、direction-pick と並列可）→ token plan → AI-defaults critique → compose → reviewer。

## ディレクター制御フロー

**起動機構**：ディレクター（＝スキル本体のメインセッション）は各職種を **Agent tool**（`subagent_type` ＝ エージェントファイル名：`product-designer` / `visual-designer` / `reviewer`）で spawn する。プロンプトに mode・S1 成果物の所在・参考画像 path（あれば）・既存 DESIGN.md draft の所在（あれば）を渡す。差し戻しは**同じ職種を continuation で再起動**（findings を渡す・ADR-0018）。

**期待マニフェスト**（完全性ガードの基準）：DESIGN.md の必須セクション ＝ YAML frontmatter ＋ Overview / Visual Theme & Mood / Colors / Typography / Layout / Elevation & Depth / Shapes / Components / Do's and Don'ts の 9 セクション。**Voice & Tone** はサービス性質次第（コピー語彙の規律が要るなら必須、ロゴ単体等なら省略可）。各セクションを ✅生成 / ➖省略(理由) / ⚠️未達(理由) で決着。

**並列/直列**：画像 ingest（visual-designer）と direction-pick 序盤の anchors / design-principles 読み込みは並列可。token plan 以降は直列（compose は単一ファイル DESIGN.md への書き込みのため）。

1. **direction-pick 対話**（人間ゲート・type-2）：`product-designer` を `mode=direction-pick` で spawn し、3 問の一問一答で direction を 1 つに絞る（後述）。3 問で握れない場合は decide-record-proceed（候補を ⚠️繰り越しで残す）。
2. **画像 ingest**（任意・並列可）：参考画像があれば `visual-designer` を `mode=extract` で spawn し、画像から mood / palette / typography vibe を構造化抽出。画像なしは `mode=tone-fallback` で design-principles のみから記述子抽出。
3. **token plan**：`product-designer` を `mode=compose` で continuation 再起動し、color 4-6 hex（named）/ type 2+ roles / spacing scale / radius / signature element を内製。
4. **AI-defaults critique**（自己 critique・必須）：plan が AI デフォルト3種に陥っていないか自答（後述）。陥っていれば plan に戻す。
5. **compose DESIGN.md**：`product-designer` continuation で、YAML frontmatter ＋ 10 セクションを spec フォーマットで `<service-repo>/DESIGN.md` に書く。
6. **reviewer 評価ループ**（ADR-0018）：`reviewer` を spawn（fresh）し、DESIGN.md の findings を完全マニフェストで返させる。最大 3 ラウンド差し戻し。round2-3 は continuation で凍結スコープ確認のみ。finding ごとに ✅解消 ／ ➖省略(理由) ／ ⚠️未達(理由) を決着。
7. **完全性ガード**（ADR-0011）：期待マニフェストの各セクションを ✅ / ➖ / ⚠️ で決着。
8. **⚠️繰り越し提示**（ADR-0019）：3 問で握れなかった direction 候補・画像から複数 mood が出た場合の択一など、繰り越し inline マーカーを集めてディレクターが終端でレポート提示。プロトを触ってから G2 で確定する論点として残す。

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

## AI-defaults critique（必須・陥落チェック）

`frontend-design`（anthropics/skills）／ Google Labs PHILOSOPHY.md 由来の AI 失敗パターン 3 種に、token plan が陥っていないかセルフチェック。1 つでも該当したら plan に戻す。

1. **warm-cream（#F5F0E8 系）＋ terracotta／serif 1 種類**：「上品な手書き notepad」風で全 AI が陥る。
2. **black 背景 + acid green / cyan アクセント**：「ハッカー風 / 未来 SaaS」風で全 AI が陥る。
3. **broadsheet 黒 hairline + 大きな serif 見出し**：「上質な新聞 / マニフェスト」風で全 AI が陥る。

陥落していれば、`## Visual Theme & Mood` の specific reference に**逆方向**の固有名（例：陥落＝broadsheet なら「Memphis Group」「Fluxus poster」等）を追加し、palette / typography を見直す。

## self-grill・decide-record-proceed・繰り越し

- **self-grill**（ADR-0005）：各職種は griller と answerer を兼ね、anchors（特に design-principles）と feature-scope を答え合わせ材料に自答する。人間に質問を投げない（停止しない）。**唯一の例外**は direction-pick 3 問の人間対話（type-2）。
- **decide-record-proceed**（ADR-0004）：3 問で握れない軸・画像で割れる候補は、根拠ある仮決を下し、根拠を DESIGN.md `## Visual Theme & Mood` に inline で残して進む。専用の決定ログ file は作らない（ADR-0019）。
- **繰り越し決定**（ADR-0019）：プロトを触ってから決めたい論点は ⚠️繰り越しマーカー＋候補で inline 残し、ディレクターが終端で集約レポート提示。G2 で人間が確定する。

## 出力レイアウト

```
<service-repo>/
├── DESIGN.md    ← 本スキルの成果物（repo-root）
└── docs/
    └── discovery/  ← S1 成果物（読むだけ）
```

- DESIGN.md は **repo-root** に置く（ADR-0020）。`docs/discovery/design/` 配下には置かない。
- `visual-designer` の中間抽出レポート（画像ごとの構造化出力）は DESIGN.md `## Visual Theme & Mood` 本文に**取り込み**、別ファイルとしては残さない（二重管理回避）。
- 参考画像そのものは repo に commit しない（容量・著作権リスク）。出典・パスは DESIGN.md 内に記載する。

## 品質バー（端折り禁止）

- 「minimal」は人間の入力最小化を指し、**導出物の最小化ではない**（ADR-0011）。9 / 10 セクションを端折らない。
- 抽象語で止めない（"modern" / "clean" / "trustworthy" → 具体トークンと specific reference まで）。
- DESIGN.md は **prose first, tokens second**（Google Labs PHILOSOPHY.md）。トークン値だけのファイルにしない。
- 形容詞列挙の罠を避ける：必ず 1 つは固有名（人物・作品・年代・出典）を出す。

## 破壊的操作の禁止

- push / PR / merge / 課金 / 外部送信はしない。repo へのファイル書き込みと commit に留める。
- アンカー（`docs/discovery/anchors/`）は決め直さない（G1 で確定済み・読むだけ）。
- screen-specs（`docs/discovery/design/screen-specs/`）は触らない（S1 `product-designer` 担当・並列ジョブ競合回避）。
- 画像ピクセルを repo に commit しない（出典は path のみ DESIGN.md 内記載）。

## 関連 ADR

スキル追加判断＝ADR-0023。DESIGN.md＝ADR-0020（決定 5 resolved）。共通形＝ADR-0013。評価ループ＝ADR-0018。決定記録＝ADR-0019。ロスター＝ADR-0022 拡張（`visual-designer` 追加・`product-designer` 拡張）。出力位置＝ADR-0020。

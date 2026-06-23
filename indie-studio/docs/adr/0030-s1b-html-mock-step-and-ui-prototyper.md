# S1b design-direction に HTML mock 生成ステップを追加（新 agent `ui-prototyper`）

ADR-0023 で確定した S1b `design-direction` は reviewer 評価ループ合格後に直接 S2 Claude Design へハンドオフする設計だった。実運用（socialcoffeenote SCN-36 の direction-pick 検証）で **token を視覚で確認するための HTML mock が S2 直前にあると direction の妥当性を「机上の token」ではなく「実際の見た目」で人間が握れる**ことが確認できた。token の論理整合性は reviewer が見るが、WCAG / 色覚多様性 / palette の組み合わせの違和感 / typography rhythm の妥当性のような視覚要素は実機 / 視覚で初めて判定可能。本 ADR で **reviewer 合格後・S2 直前に HTML mock 生成 + 視覚確認ゲートを挟むステップを正式に追加**し、新 agent **`ui-prototyper`**（UI プロトタイパー・実在職種）を担い手として導入する。

参照：
- 関連 ADR: ADR-0023（design-direction スキル追加）／ADR-0013（共通形）／ADR-0022（S1 roster 実在職種）／ADR-0026（新規職種は追加しない原則の射程）／ADR-0029（DESIGN.md format spec pin）
- 実証ケース: socialcoffeenote SCN-36 の `docs/indie-studio/design-direction/mock/scn-design-mock.html`（1258 行・1 ファイル統合・CSS variable で YAML token を 1:1 写像）

## Status

accepted（ADR-0023 を extends。ADR-0022 / ADR-0026 の職種追加判断を本 ADR で適用範囲明確化）

## 決定

1. **S1b フローに HTML mock ステップを追加**。位置は **reviewer 評価ループ合格後・⚠️繰り越し提示前**：

   ```
   compose DESIGN.md
     → reviewer 評価ループ（最大 3R・既存）
     → ★ HTML mock 生成（ui-prototyper・新規）
     → ★ 視覚確認ゲート（type-2 人間ゲート・最大 2 ループ・新規）
       ├─ OK → 続く
       └─ 戻る → product-designer continuation で DESIGN.md token 修正
                 → ui-prototyper continuation で mock 再生成
                 → 再ゲート（合計 2 ループまで）
     → ⚠️繰り越し提示
     → S2 Claude Design へ
   ```

2. **担い手＝新 agent `ui-prototyper`（UI プロトタイパー）**：

   - **職種根拠（ADR-0022 実在職種原則）**：UI プロトタイパーは IDEO / consultancy デザインスタジオ / プロダクトデザインチームで実在する職種。「UI を試し作りで見せる」役割の専任で、`product-designer`（要件と UI 構造の設計）・`visual-designer`（mood の視覚抽出）と職務スコープが分かれる。

   - **追加根拠（ADR-0026 新規職種追加の射程）**：ADR-0026 は S1a `stack-direction` の文脈で「新規職種は追加しない（tech-lead + reviewer のみ）」を確立した。射程は S1a に限定で、S1b では既に visual-designer を新規追加した先例（ADR-0023）がある。mock 生成は視覚化の専任作業で、product-designer / visual-designer どちらに振っても職種スコープが歪む（前者は compose・後者は抽出方向）ため、新 agent 追加が正当。

   - **配置**：`indie-studio/agents/ui-prototyper.md`。

3. **起動モード**：

   - `mode=mock`：DESIGN.md（reviewer 合格版）を入力に、HTML mock を生成。`<service-repo>/docs/indie-studio/design-direction/mock/<service-slug>-design-mock.html` に書き出す。

4. **mock の構造＝1 ファイル統合・hybrid 構成**：

   - **Component gallery**：button（primary / secondary / icon / destructive 全 variant）・card（base / hover）・chip（spec / flavor 等の semantic variant）・badge（public / private / draft）・input（normal / focus / error）・FAB を **全 variant 並べて表示**。

   - **主要画面 1〜2 枚**：`screens.md` から **`[MVP]` かつ `priority: high`** の screen のうち、**feature-scope の `[作る]` 機能を最大被覆する** 1〜2 画面を選ぶ。該当画面がない場合は area prefix の core から各 1 枚（最大 4 枚まで）。

   - **1 ファイル統合**：CSS `:root` の variable 写像を単一にし、token 修正時の波及を即座に視覚反映できるようにする。screen ごとのファイル分割は token duplication / drift リスクのため禁止。

5. **token 写像規約（YAML → CSS custom property、1:1 kebab-case）**：

   | YAML path | CSS variable |
   |---|---|
   | `colors.<token-name>` | `--color-<token-name>` |
   | `typography.<token-name>.fontSize` | `--type-<token-name>-size`（`-family` / `-weight` / `-line-height` / `-letter-spacing` も同様） |
   | `spacing.<scale-level>` | `--space-<scale-level>` |
   | `rounded.<scale-level>` | `--radius-<scale-level>` |
   | `components.<component-name>.<property>` | `--<component-name>-<property-kebab>`（例：`button-primary-background-color` → `--button-primary-bg`、命名は読みやすさを優先して短縮可・ただし mock 内で一貫させる） |
   | `## Elevation & Depth` セクションの shadow 値 | `--shadow-<role>`（mock 内 inline 定義・ADR-0029 で YAML top-level に置かない方針と整合） |
   | `## Motion` セクションの duration / easing | `--motion-<role>-duration` / `--motion-<role>-easing`（同上） |

   写像が DESIGN.md と齟齬しないことを `ui-prototyper` が self-grill で確認する。

6. **配置先**：`<service-repo>/docs/indie-studio/design-direction/mock/<service-slug>-design-mock.html`（ADR-0028 の namespace 化と整合）。

   - root 配置（`<service-repo>/DESIGN-mock.html` 等）は却下：service repo 固有の運用ドキュメントと混在する。
   - `docs/indie-studio/discovery/design/` 配下は却下：discovery は S1 `product-designer` の area で competing write を生むリスク。
   - 複数 mock を作る場合は `<service-slug>-design-mock-<screen>.html` 命名。

7. **視覚確認ゲートの規律（type-2 人間ゲート・direction-pick と並ぶ S1b の唯一の人間対話）**：

   - **質問**：1 問。「mock を確認しました：1) OK（S2 へ進む） 2) 戻る（修正したい）」。
   - **「戻る」の自由記述**：何を直したいかを自由記述で受け取る（番号制約を物理的にかけられない Claude Code チャット環境のため）。**ui-prototyper / product-designer が必ず DESIGN.md の該当 token / セクションにマップしてから修正に入る**（自由記述をそのまま指示として読まない）。
   - **最大ループ**：**2 回**。1 回目「戻る」→ token 修正 → mock 再生成 → 2 回目ゲート。2 回目「戻る」が来た場合は decide-record-proceed＝**`⚠️繰り越し`** マーカーで `## Visual Theme & Mood` または該当セクションに inline 残し、S2 G2 で人間が確定する論点として送る。
   - **collateral damage 防止**：1 ループ目の修正が他セクションに矛盾を生んでいないか、ui-prototyper が mock 再生成時に self-grill で確認する。

8. **共通形との整合（ADR-0013）**：

   - director（design-direction スキル本体）＋ 職種エージェント（product-designer / visual-designer / **ui-prototyper**）＋ 評価エージェント（reviewer）の 3 ノード構成は不変。
   - reviewer は mock 自体を評価対象に**しない**（mock は機械的視覚出力で reviewer の評価観点＝anchor 整合・真実源・カバレッジ逆引きとは別軸）。reviewer は DESIGN.md（spec compliance 含む・ADR-0029）のみ評価する。
   - 完全性ガード（ADR-0011 期待マニフェスト）の主成果物に mock html を**含める**：DESIGN.md ＋ mock html の 2 成果物。✅生成 / ➖省略(理由) / ⚠️未達(理由) で決着。

9. **画像ピクセル / 動画 / 外部送信の禁止**：mock 内に画像ファイル・動画ファイルを embed しない（DESIGN.md の方針継承）。emoji / SVG / unicode は許容。フォントは Google Fonts CDN（preconnect 経由）・OS フォントを推奨。

## Considered Options

### A. 担い手（職種選定）

- **却下：`product-designer` の新 mode `mode=mock`**。DESIGN.md compose と同職種で token 一貫性を維持できる利点はあるが、**`product-designer` のスコープが画面導出（S1）・direction-pick 対話・DESIGN.md compose・HTML mock 化と肥大**する。職種スコープが「設計」と「実装」を跨ぐと self-grill 観点が散逸し、品質バーが落ちる懸念。
- **却下：`visual-designer` 拡張**。`visual-designer` は「画像→ mood 抽出」の方向で、生成（DESIGN.md → mock）とは対称的でない。職種定義として座りが悪い。
- **却下：既存 `frontend-engineer` を拡張**（S1b mode を追加）。`frontend-engineer` は S5 実装担当で職種スコープが S1b〜S5 をまたぐ。共通形（ADR-0013）の「stage 内で職種が完結する」性質が崩れる。
- **却下：成果物名由来の `mock-builder`**。ADR-0022 の「実在職種で設計（成果物名・概念で割らない）」原則に反する。「mock」は成果物名・「builder」は概念で、実在職種ではない。
- **採用：新 agent `ui-prototyper`（UI プロトタイパー）**。実在職種（決定 2 で根拠記述）。スコープが「UI を試し作りで見せる」専任で他職種と職務領域が明確に分離。

### B. mock の構造

- **却下：screen 単位でファイル分割**。CSS variable 写像が screen ごとに duplicate し token drift の温床。token 修正の波及が見えない。
- **却下：Component gallery のみ（screen 無し）**。primitives 単体での視覚妥当性は確認できるが、**文脈での違和感**（list の rhythm・spacing が密集する画面の窮屈さ等）を見逃す。
- **却下：dashboard 相当を 1 ファイル詰め込み（SCN-36 現状方式）**。primitives の見え方が dashboard コンテキストに拘束され、他 variant が見えにくくなる。
- **採用：Component gallery + 主要 1〜2 画面の hybrid を 1 ファイル統合**。primitives の妥当性と文脈妥当性を両立。

### C. 視覚確認ゲートのループ上限

- **却下：1 ループのみ（OK / NG の 2 択）**。「NG」を G2 まで持ち越すと S2 プロトタイプが歪んだ token で組まれる。S1b で修正可能なものは S1b で吸収すべき。
- **却下：reviewer と同じ最大 3 ループ**。視覚 review で 3 ループは token のチューニングを手引きでやるには多すぎる。デザインの infinite-tweak を誘発しかねない。
- **採用：最大 2 ループ・自由記述許容（決定 7）**。1 回目で修正・2 回目で決着。余地は `⚠️繰り越し` で G2 へ送る decide-record-proceed（ADR-0004 / 0019）。

### D. 配置先

- **却下：repo-root に `DESIGN-mock.html`**。service repo 固有のドキュメントと混在し、ハーネス由来であることが不明確。
- **却下：`docs/indie-studio/discovery/design/mock/`**。discovery は S1 `product-designer` の area で write 競合の温床。
- **採用：`docs/indie-studio/design-direction/mock/`**（決定 6）。ADR-0028 の namespace 化と整合。

### E. token 写像規約の柔軟性

- **却下：完全に YAML path をそのまま CSS variable 名にする**（例：`colors.text-primary` → `--colors-text-primary`）。spec の token reference 構文と CSS variable 命名の慣習が違うため可読性が落ちる。
- **採用：1:1 kebab-case 写像（決定 5）**。`colors` は `--color-` 接頭辞、components は名前を直接 prefix にする。可読性と一意性の両立。

## Consequences

- **新規ファイル**：
  - `indie-studio/agents/ui-prototyper.md`（新 agent 本体）

- **既存ファイル更新**：
  - `indie-studio/skills/design-direction/SKILL.md`：ステージ構造に mock step + 視覚確認ゲートを追加。ロスター表に `ui-prototyper` を追加。完全性ガードの主成果物に mock html を追加。出力レイアウトに mock 配置先を追加。
  - `indie-studio/agents/product-designer.md`：視覚確認ゲートで「戻る」時の continuation 修正の規律を追加（mock 修正連携）。
  - `indie-studio/agents/reviewer.md`：mock html は評価対象外であることを明示（評価観点に追加しない）。

- **CONTEXT.md への影響**：用語・規律レベルでは ADR-0022 / 0028 の既存記述で吸収可能。`ui-prototyper` 職種を CONTEXT.md に新規語彙として追加するかは別 PR で判断（本 PR では agent.md / SKILL.md / ADR の 3 点で職種が定義されていれば運用上は機能する）。

- **dotfiles 側への影響なし**：本 ADR は claude-collections 内で完結。dotfiles の `prototype-designer` 廃止（ADR-0023 既決）に追加の影響はない。

- **既存 service repo（SCN 等）への影響**：本 ADR 適用前に手動で作成された mock（SCN-36 の `scn-design-mock.html`）は legacy として扱う。新 format での再生成は当該 service repo の別 issue で対応する（本 PR 範囲外）。

- **共通形（ADR-0013）の更新**：S1b の職種数が 3（product-designer / visual-designer / reviewer）→ 4（+ **ui-prototyper**）に。director ＋ 職種群 ＋ 評価の 3 ノード構成は不変。

- **ADR-0026 との関係**：「新規職種は追加しない」原則の射程を「S1a stack-direction の特定文脈」に限定して読む。S1b では既に visual-designer（ADR-0023）で前例があり、本 ADR で ui-prototyper を追加する判断は「実在職種＋既存職種のスコープが歪まないため」を根拠とする。

## 未確定

- **mock 視覚確認ゲートの自動化**：将来 orchestrator が立ち上がった際、視覚確認ゲートを screenshot diff 等で部分自動化する余地。現状は人間目視。

- **mock の brave 拡張**：dark mode / 別 OS（iOS / Android）の split view を mock に含めるかは初版で判断せず、運用 1〜2 サービスで実例を見てから別 ADR で判断する。

- **ui-prototyper の S5 への波及**：S5 実装段で `frontend-engineer` が ui-prototyper の mock を起点に実装する境界は本 ADR では深掘りしない。S5 を共通形で作り直す段（ADR-0013）で別 ADR で確定。

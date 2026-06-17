# DESIGN.md＝具体のデザイン憲法（repo-root・統一プロトの入力）——意図版 design-system 廃止・生成機構は未定

`DESIGN.md` は「デザインシステムを1枚の Markdown に集約した repo-root の見た目の憲法」（Stitch / awesome-design-md の概念）。**具体値＋禁止事項**で書き、Claude Code・Cursor・Claude Design 相当の**全 AI エージェントが自動参照**する。AI は曖昧な「意図」より**具体**に従いやすいので、intent ではなく concrete で書く。本 ADR は ADR-0016 の「DESIGN.md＝プロト後の realized 版・S3 配置」を誤りとして正し、ADR-0011 のデザイン層（moodboard 廃止 → design-system＋design-tokens）を改訂する。

参照：
- Google Stitch（AI UI design）: https://blog.google/innovation-and-ai/models-and-research/google-labs/stitch-ai-ui-design/
- DESIGN.md 解説（classmethod）: https://dev.classmethod.jp/articles/design-md-ai-agent-design-system/

## Status

accepted（ADR-0016 の DESIGN.md 定義/タイミング/作成者を supersede。ADR-0011 のデザイン層出口を改訂）

## 決定

1. **DESIGN.md＝repo-root の具体デザイン憲法**（standing / living file）。構成は awesome-design-md の9セクション準拠：ビジュアルテーマ・雰囲気／カラーパレットと役割／タイポグラフィ／コンポーネントスタイル／レイアウト原則／深さと段階（シャドウ等）／Do's and Don'ts／レスポンシブ動作／エージェント向けプロンプトガイド。
2. **役割＝統一プロトの入力**。Claude Design に渡し、**全画面で DESIGN.md に準拠**させて統一感のあるプロトを作らせる。プロト後 G2 で更新され、下流（S3/S5）と全エージェントが自動参照する。＝realized（プロト後）でも intent（散文の意図）でもなく、**プロトに先立つ concrete な拠り所**で、その後 living に更新される。
3. **S1 デザイン層の出力は DESIGN.md に集約**。別ファイル `design-concept.md` / `design-system.md`（意図版）/ `design-tokens`（別ファイル）は**廃止**し、DESIGN.md のセクションに吸収する。具体トークン値（色・タイポ・余白等）は DESIGN.md のカラー/タイポ セクションに markdown で載せ、別の `.css` / `.json` は持たない。
4. **ロスター読み替え**：ADR-0011 の「デザインシステムエンジニア（design-system + design-tokens 担当）」は、別ファイル廃止に伴い **DESIGN.md の該当セクション（具体値）の導出担当**に読み替える。
5. **未確定（flag）＝DESIGN.md の生成機構**。誰が・どの環境で組み上げるか（Claude Code か等）は未定。とくに **mood/aesthetic（どんな雰囲気にするか）は人間との枠組み対話＋参考画像の入力を要し、純自律ではない**。ADR-0011 の「moodboard 廃止」は *Obsidian Canvas に貼る機構* の廃止であって、**画像で美的方向を人間が与える必要そのものは存続**し、DESIGN.md の mood セクションへ流れ込む。この対話の所在・画像入力の経路・moodboard 概念の再評価は別途詰める。

## Considered Options

- **却下：意図版 design-system.md を Claude Design に渡す**。AI は意図より具体に従う（Stitch / DESIGN.md の知見）。統一感は「具体値への準拠」から出るので、拠り所は concrete でなければならない。
- **却下：DESIGN.md をプロト後の realized 版としてのみ S3 が配置**（ADR-0016 原案）。それでは「統一プロトを作るための入力」が存在せず、Claude Design が画面ごとにドリフトする。先に具体憲法を与える必要がある。
- **却下：design-concept / design-system / design-tokens を別ファイルで維持**。1枚集約の DESIGN.md と二重管理になる。

## Consequences

- **ADR-0016 改訂**：`docs/discovery/design/` から design-concept / design-system / design-tokens を除去（`screens.md` ＋ `screen-specs/` のみ）。DESIGN.md は repo-root（位置は ADR-0016 通り）だが、定義・タイミング・作成者は本 ADR が上書きする。
- **ADR-0011 改訂**：デザイン層の出口＝design-system＋design-tokens → **DESIGN.md**。moodboard 廃止の射程を「Canvas 機構の廃止／美的画像入力の必要は存続」と明確化。
- 旧・保留論点「design-tokens の形式（css/json/md）」は別ファイル廃止により**消滅**（DESIGN.md 内に具体値）。
- **生成機構は未確定**（決定 5）。スキル1 を書く際、DESIGN.md の mood 対話・画像入力・組み上げ担当が未定である点を残課題として扱う。

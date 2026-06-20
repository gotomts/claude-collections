# load-bearing claim への red-team レンズ（観点 ⑤）と PRFAQ ゴールラインの 3 行 extract

phuryn/pm-skills の `strategy-red-team`（steelman → 攻撃 → `Fails if ___` → kill criteria）を、indie-studio の自走ハーネスと整合する形で取り込む。reviewer の評価観点に **⑤ load-bearing claim の反証可能性** を追加し、対象を **load-bearing corpus 4 点** に絞る。出力構造（ADR-0018 の finding 6 要素）は不変のまま、観点 ⑤ の finding は固定書式（`Steelman:` / `Fails if:` / `Kill criteria:` のリテラル先頭文字列）で書き、reviewer 完了報告に派生ビュー `## Red-team index` を載せる（A+ ハイブリッド）。G1 アンカー対話では PRFAQ ゴールライン確定後に AI が候補生成 → 人間が番号選択（カスタム可）し、確定 3 行を PRFAQ に inline 配置する。

参照：
- phuryn/pm-skills `strategy-red-team`（思想ソース）: https://github.com/phuryn/pm-skills/blob/main/pm-execution/skills/strategy-red-team/SKILL.md
- phuryn/pm-skills `identify-assumptions-new`（4 core + 拡張 4 リスク分類の語彙ソース・本 ADR では取り込まず将来検討）

## Status

accepted（ADR-0018 の finding 観点 ①〜④ を ①〜⑤ に拡張／ADR-0002 の PRFAQ DoD を extends／ADR-0019 の繰り越し決定機構と連携）

## 決定

1. **観点 ⑤「load-bearing claim の反証可能性」を reviewer に追加**：ADR-0018 の finding 観点列挙（①anchor 整合・②真実源整合・③カバレッジ逆引き・④内部一貫性）に⑤を追加。①〜④ と独立軸で、claim の弱点（steelman に耐えない／反証不可能／kill criteria が引けない）を見る。重大度（`blocker`/`minor`）・差し戻し protocol・round 1 fresh → 2-3 凍結 continuation は ADR-0018 のまま。

2. **対象は load-bearing corpus 4 点に限定**：① `anchors/prfaq.md` の **ゴールライン**（"価値が出る最小ライン"）／② `planning/07-feature-scope.md` の **MVP 線根拠** と **`[作らない]` 根拠**（フラットな機能行自体は対象外）／③ `planning/09-monetization.md` の **⚠️繰り越し 候補**（無料/有料境界）／④ `planning/12-risks-assumptions.md` の **全 assumption**。これ以外の corpus（persona・usage-scenes・competition・pitch・marketing・kpi・legal・nfr・roadmap・screens・screen-specs）には観点 ⑤ を当てない（findings 量爆発と ADR-0018 のスコープ凍結崩壊を防ぐ）。

3. **観点 ⑤ の finding は固定書式**：ADR-0018 の finding 6 要素（対象／観点／重大度／根拠／期待／提案）は不変。観点 ⑤ の finding に限り、内部書式を次のリテラル先頭文字列で凍結する：
   - `根拠` の冒頭：`Steelman: <claim が真である最強の理由>`
   - `期待` の冒頭：`Fails if: <反証可能な条件・観測可能で具体的>`
   - `提案` の冒頭：`Kill criteria: <この週に取れる最安テスト>`
   この書式により、reviewer 間の出力品質ブレを抑え、`grep "Fails if:"` で findings 横断検索が機械的に効く。

4. **reviewer 完了報告に派生ビュー `## Red-team index` を追加**：findings 一覧（既存）の後ろに、観点 ⑤ findings を抽出した集約参照節を置く。形式：
   ```
   ## Red-team index（派生ビュー・観点 ⑤ 抽出）
   - <対象>: Fails if <条件> → Kill criteria <最安テスト>
   ```
   これは findings のコピーではなく **集約参照**（同じ事実を 2 箇所に書かない）。ディレクターはこの index を ADR-0019 の `⚠️繰り越し` 候補配置に直接転用できる。

5. **PRFAQ ゴールラインに 3 行 inline 配置（G1 で人間共著）**：service-discovery の G1 アンカー対話で、ゴールラインの本文確定後に次のステップを追加する：
   - AI が self-grill で `Steelman` / `Fails if` / `Kill criteria` 候補をそれぞれ 3〜5 個生成
   - 人間に**1 ターン 1 候補群**で提示し、**番号で選択**してもらう（AGENTS.md「yes/no か番号で」と整合）。カスタム入力（番号 0 = カスタム）も許可
   - 確定した 3 行を PRFAQ の「## ゴールライン」節真下に inline 配置（YAML/箇条書きどちらでも可・実装は SKILL.md で固定）
   ゴールラインは「サービスのコア」であり、人間の domain knowledge を混入させる場として G1 対話のラウンド増加（5 ラウンド → 6〜8 ラウンド程度）を許容する。これは ADR-0004 自走規律の「**アンカー対話を除く**一問一答ゼロ」例外内。

6. **担当職種（product-manager / business-strategist）は初回出力時から固定書式で書く**：reviewer の観点 ⑤ 差し戻しを round 1 で systematically 発生させないため、PM は `12-risks-assumptions.md` の各 assumption・`07-feature-scope.md` の MVP 線根拠と `[作らない]` 根拠に、BS は `09-monetization.md` の繰り越し候補に、`Steelman:` / `Fails if:` / `Kill criteria:` の 3 行を初回から併記する。書式が崩れた場合のみ reviewer が round 2-3 で差し戻す。

## Considered Options

- **却下：観点 ⑤ を全 corpus に当てる**。findings 量が爆発し、round 1 fresh の完全マニフェスト原則（ADR-0018）と衝突。スコープ凍結（round 2-3 は round 1 findings の解消のみ検証）が機能しなくなる。load-bearing の定義（「偽なら下流 corpus が空転する claim」）で 4 点に絞ることで、red-team を pre-mortem と分ける本質（強い主張だけを攻撃する）も保たれる。

- **却下：B 案＝完了報告に並列セクションとして `Red-team / Kill criteria` を追加**。findings 一覧と並列の別出力ができ、ディレクターの完全性ガード集計が二系統化。ADR-0018 の finding 構造改訂が必要になる。A+ ハイブリッド（観点 ⑤ + 固定書式 + 派生ビュー）で同等の検索性・転用容易性を、構造 1 系統のまま実現できる。

- **却下：C 案＝重大度判定基準に注入のみ**（「steelman に耐えなければ blocker」を reviewer.md の重大度節に追加）。手順（steelman → 攻撃 → Fails if → Kill criteria）が明示されず、reviewer 個体差で出力品質がブレる。ADR-0005 self-grill の趣旨「手順を明示して品質を再現させる」と逆向き。

- **却下：3b＝AI 自律導出だけで PRFAQ ゴールラインに 3 行を入れる**（G1 対話完了後に AI が self-grill で導出して inline 追記）。人間の domain knowledge が PRFAQ ゴールラインに混入せず、サービスのコアが薄まる。ユーザーが「PRFAQ はサービスのコアを考えるところ／ラウンドが増えるのは構わない／後続精度を上げたい」と明示した意向に逆向き。3b は ADR-0004 規律と整合するが、G1 アンカー対話自体が規律の例外領域なので、ラウンド増加コストは規律違反ではない。

- **却下：phuryn/pm-skills を Claude Code plugin として install して `Skill` 呼び**。phuryn の skills は「人間と対話しながら PM が決める」co-pilot 設計で、interview-script / create-prd / OST いずれも user 入力を逐次要求する。ADR-0004（decide-record-proceed）・ADR-0005（self-grill）の自走設計と思想衝突する。思想だけ抽出して reviewer / PM / BS に移植する本 ADR の路線が筋。

- **却下：phuryn の 8 risk categories（Value/Usability/Viability/Feasibility + Ethics/GTM/Strategy/Team）を `12-risks-assumptions` の分類軸として導入**。価値は高いが本 ADR のスコープ外。red-team レンズ取り込みが先で、分類軸は別 ADR（将来）で検討する。

- **却下：phuryn の Opportunity Solution Tree（OST）を feature-scope の中間構造に**。`07-feature-scope.md` のフラット構造を outcome → opportunities → solutions の 3 段に再編する構造変更で、ADR-0011 / 0021 の planning レイアウトに踏み込む。本 ADR のスコープを越える。S1 が安定してから別 ADR で検討。

- **採用**：観点 ⑤ + 固定書式 + 派生ビュー（A+ ハイブリッド）＋ G1 で人間共著の 3 行 extract（3a・実装制約：候補生成 + 番号選択で AGENTS.md と整合）。対象は load-bearing 4 点に限定。担当職種は初回から固定書式で書く。

## Consequences

- **ADR-0002 を extends**：PRFAQ DoD に「ゴールラインは `Steelman: / Fails if: / Kill criteria:` の 3 行を併記すること」を追補する。ADR-0002 本体は immutable 運用のため触らず、本 ADR が extends する位置で記述する（indie-studio の ADR 群は supersede ではなく追補で関係を作る運用）。
- **ADR-0018 互換**：finding 構造（対象／観点／重大度／根拠／期待／提案）は不変。観点が 4 → 5 に拡張されるのみ。差し戻し protocol（round 1 fresh → 2-3 凍結 continuation・最大 3R・上流再オープン深さ 1・成果物ごと独立予算）は無変更。
- **ADR-0019 連携**：観点 ⑤ findings は `⚠️繰り越し` マーカーの**候補供給源**。reviewer の `Red-team index` で炙り出された `Fails if` のうち「触ってから決める方が安い」ものは、担当職種が inline で `⚠️繰り越し` 候補として残せる。逆方向（既存の `⚠️繰り越し` 候補に reviewer が観点 ⑤ で `Fails if` / `Kill criteria` を補強する）も成立する。
- **`agents/reviewer.md` 更新**：観点 ⑤ を追加、固定書式（`Steelman:` / `Fails if:` / `Kill criteria:`）の規約、「完了報告（ディレクターへ返す）」節に `Red-team index` 派生ビューの形式を追加。
- **`agents/product-manager.md` 更新**：`12-risks-assumptions.md` の各 assumption と `07-feature-scope.md` の MVP 線根拠・`[作らない]` 根拠に、初回出力時から 3 行併記する規約を追加。self-grill 観点に「load-bearing claim の反証可能性」を追加。
- **`agents/business-strategist.md` 更新**：`09-monetization.md` の `⚠️繰り越し` 候補に、初回出力時から 3 行併記する規約を追加。self-grill 観点に「load-bearing claim の反証可能性」を追加。
- **`skills/service-discovery/SKILL.md` 更新**：「G1：アンカー対話（type-2）」節の `prfaq.md` 説明に、ゴールライン確定後の 3 行 extract ステップを追加（AI が候補生成→人間が番号選択→ inline 配置）。
- **影響範囲は S1 のみ**。S3（技術設計）・S4（分解）・S5（実装）の reviewer 相当（プリンシパルエンジニア・評価3観点）への観点 ⑤ 展開は本 ADR では決めない。S1 の運用で得た知見を踏まえて別 ADR で検討。
- **G1 ラウンド数**：従来 5 ラウンド程度 → 6〜8 ラウンド程度（PRFAQ ゴールラインの 3 行 extract で +1〜3）。ユーザー許容範囲として明示済み。
- **reviewer 個体差リスク**：固定書式の遵守は SKILL.md の規約強度に依存する。reviewer.md でリテラル先頭文字列（`Steelman:` / `Fails if:` / `Kill criteria:`）を強く指定し、書式違反は round 1 findings 自体の差し戻し対象とする（自分の出力を grade する自己評価ループ）。

## 未確定

- **観点 ⑤ の S3/S4/S5 への拡張**：本 ADR は S1 範囲。後続ステージのプリンシパルエンジニア・評価3観点へ展開するかは S1 運用後に別 ADR で判断する。
- **phuryn の 8 risk categories 取り込み**：`12-risks-assumptions.md` の分類軸として導入する価値はあるが本 ADR スコープ外。S1 で観点 ⑤ が安定したら別 ADR で検討。
- **OST 構造化**：`07-feature-scope.md` のフラット構造を outcome → opportunities → solutions の 3 段に再編する案は、ADR-0011 / 0021 の planning レイアウト改訂を伴うため本 ADR スコープ外。S1 安定後に別 ADR で検討。

# S3 tech-design 強化（実現可能性 6 観点の追加と G3 スコアカード）

ADR-0015 で確定した `S3 tech-design` のスコープ（型・スタック・モジュール・ドメインモデル・運用基盤）は「何を build するか」中心で、「is it buildable / sustainable / right」の **feasibility 視点が薄い**。S3→S1 フィードバックに「技術見積もり（配信実費・コスト・実現可能性）」と書かれているが、ロスター（architect / tech-lead / infra / security / principal）に明示の対応役割がなく、infrastructure-engineer の付帯任務になっている。本 ADR で S3 に **6 観点（build vs buy 詳細・コスト積算・運用 sustainability・規制法令・リスク台帳・パフォーマンス予算）**を追加し、既存ロスターの責務拡張で吸収する（**新規職種は追加しない**）。さらに G3 ゲートに「実現可能性スコアカード」を導入して、観点別の意思決定情報を人間に晒す。

ADR-0026 で `S1a stack-direction` がスタック関連 4 観点を握る前提で、S3 はスタック・3rd party・build vs buy 基本を**読むだけ**にし、その上で 6 観点の深堀りを追加する。

## Status

accepted（ADR-0015 を extends：S3 スコープを feasibility 観点で拡張／ADR-0026 と並行：S1a 確定済みを読むだけ／ADR-0007 G3 ゲートを extends：スコアカード追加）

## 決定

1. **既存ロスターの責務拡張で 6 観点を吸収**（**新規職種は追加しない**）：

   | 観点 | 担当（既存職種の拡張） | 出力先 |
   |---|---|---|
   | build vs buy **詳細**（コスト試算・SLA リスク・移行コスト含む） | `tech-lead` 拡張 | `docs/tech/build-vs-buy-detail.md` |
   | コスト積算（1 ユーザーあたり infra+3rd party 費用・break-even・scaling cost） | `infrastructure-engineer` 拡張 | `docs/tech/cost-model.md` |
   | 運用 sustainability（個人で sustain 可能か・SLA 現実値・インシデント対応） | `infrastructure-engineer` 拡張 | `docs/tech/ops-sustainability.md` |
   | 規制・法令（GDPR / accessibility / 業界規制 / データ越境） | `security-engineer` 拡張 | `docs/tech/compliance.md` |
   | リスク台帳（SPOF / ベンダーロックイン / bus factor / 技術成熟度） | `principal-engineer` 拡張 | `docs/tech/risk-register.md` |
   | パフォーマンス予算（NFR の latency/throughput → 技術選定への実現マッピング） | `software-architect` 拡張 | `docs/tech/perf-budget.md` |

2. **S3 ステージ構造を更新**：

   ```plaintext
   ステージ1: コア技術判断
     - スタック → 読むだけ（S1a 確定済）
     - モジュール → architect
     - ドメインモデル → architect
     - 〔追加〕パフォーマンス予算 → architect
     - 〔追加〕build vs buy 詳細 → tech-lead
     → 〔一拍: 人間とモジュール分割を確認〕
   ステージ2: 運用判断
     - インフラ・IaC・CI/CD・非機能実現 → infrastructure-engineer
     - セキュリティ設計 → security-engineer
     - 〔追加〕コスト積算 → infrastructure-engineer
     - 〔追加〕運用 sustainability → infrastructure-engineer
     - 〔追加〕規制・法令 → security-engineer
     - 〔追加〕リスク台帳 → principal-engineer
     → アーキ/インフラゲート（人間/G3、実現可能性スコアカード付き）
   ```

3. **G3 ゲートに「実現可能性スコアカード」を導入**：観点 12 軸（既存スコープ 6 + 追加 6）ごとに **A 成立 / B 疑義あり / C 困難** を A/B/C で 1 行表示する。`principal-engineer`（評価役）が完了報告に含める。形式：

   ```markdown
   ## 実現可能性スコアカード（G3 ゲート用）

   | 観点 | スコア | 根拠（1 行） |
   |---|---|---|
   | スタック適合性 | A/B/C | <根拠> |
   | データプロファイル実現性 | A/B/C | <根拠> |
   | 3rd party 制約適合 | A/B/C | <根拠> |
   | build vs buy 妥当性 | A/B/C | <根拠> |
   | パフォーマンス予算 | A/B/C | <根拠> |
   | コスト持続性 | A/B/C | <根拠> |
   | 運用 sustainability | A/B/C | <根拠> |
   | 規制適合 | A/B/C | <根拠> |
   | セキュリティ設計 | A/B/C | <根拠> |
   | リスク台帳 | A/B/C | <根拠> |
   | モジュール構成 | A/B/C | <根拠> |
   | ドメインモデル | A/B/C | <根拠> |
   ```

   人間は B/C を見て「許容するか／設計に戻すか」を判断する（決めるのは人間、書くのは AI／ADR-0012）。判断結果は ADR-0019 inline 規律で各観点ページに残し、G3 では別ファイルを作らない。

4. **S3 入力に S1a の 4 ファイルを追加**：`docs/tech/stack-direction/{stack,data-profile,third-party,build-vs-buy}.md` を S3 の必須入力に加える。S3 はこれらを**読むだけ**で決め直さない（ADR-0026 と整合）。

5. **完全性ガードの期待マニフェスト更新**：S3 完了時の成果物に上記 6 ファイル（`build-vs-buy-detail.md` 〜 `perf-budget.md`）を追加。各ファイルを ✅生成 / ➖省略(理由) / ⚠️未達(理由) で決着（ADR-0011）。

6. **評価ループは ADR-0018 のまま**：principal-engineer が round1 fresh → 2-3 凍結 continuation で評価。観点 ⑤ load-bearing claim の反証可能性（ADR-0024）の S3 拡張は本 ADR では決めない（S1 運用後に別 ADR で検討する未確定事項としてキープ）。

## Considered Options

### A. S3 強化を今やるか後でやるか

- **却下：S3 強化を別フェーズに繰り越し**（ADR-0019 の繰り越しマーカーで残すだけ）。「枠組み（S1a）を先に検証してから細部を直す」原則（ADR-0007）と整合するが、ユーザーから「今反映しないと忘れそう」の判断あり。`tech-design が薄い` 課題の言語化が現時点で鮮明なうちに ADR 化する方が、決定の鮮度が落ちる前に焼き付けられて長期コストが低い。
- **却下：S3 強化はやらない**（現状維持）。analysis で示した「build vs buy 詳細・コスト積算・リスク台帳・パフォーマンス予算の欠落」が放置される。indie dev は「赤字続行不可」「個人で sustain」の制約が強く、これらの観点が S3 から欠けたまま運用すると S5 実装で破綻リスクが出る。
- **採用：S1a 新設と同時に S3 強化を一括**。決定の鮮度を保ち、ADR 1 回の更新で枠組み全体を整える。

### B. 新規ロスター追加 vs 既存責務拡張

- **却下：新規ロスター追加**（cost-analyst / compliance-officer / risk-analyst 等）。観点ごとに専門職を立てると S3 ロスターが 5 → 8 以上に膨らみ、indie dev 単独運用と相容れない。職種間の責務境界も曖昧化する（cost と build vs buy は重複しやすい）。
- **採用：既存責務拡張**。各観点を最も近い既存職種に振り、agent.md の「自分が見る観点」を拡張する。ロスター数は不変（5 職種）、新規 agent ファイル不要。

### C. G3 スコアカードの位置付け

- **却下：スコアカードを別ファイル `docs/tech/feasibility-scorecard.md` として配置**。ADR-0019「決定記録は inline・専用の決定ログ file は作らない」原則と衝突する。
- **却下：スコアカード自体を導入しない**（既存の差し戻し findings だけで G3 を運用）。観点別の意思決定情報が分散し、人間が「何を許容して何を戻すか」を一覧で判断できない。
- **採用：principal-engineer の完了報告に inline 派生ビューとして組み込む**。findings は各観点ページに inline、スコアカードは派生ビュー（集約参照）。ADR-0024 の `Red-team index` と同型の構造で、観点ごとに発火するゲート判断材料を 1 枚に集める。

## Consequences

- **既存 SKILL.md 更新**：
  - `indie-studio/skills/tech-design/SKILL.md`：入力に S1a の 4 ファイル追加、ステージ構造に 6 観点を追加、ロスターの責務拡張を明示、G3 スコアカードの仕様を追加、出力レイアウトに 6 新ファイル追加
- **既存 agent.md 更新（責務拡張）**：
  - `agents/tech-lead.md`：build vs buy 詳細を追加（S1a での「判定」と S3 での「詳細」を切り分けて記述）
  - `agents/infrastructure-engineer.md`：コスト積算・運用 sustainability を追加
  - `agents/security-engineer.md`：規制・法令を追加（既存のセキュリティ設計と並列の観点として）
  - `agents/principal-engineer.md`：リスク台帳と G3 スコアカード派生ビューを追加
  - `agents/software-architect.md`：パフォーマンス予算を追加
- **G3 ゲートの運用変更**：人間は findings 一覧 + スコアカードの両方を見る。スコアカードは観点別意思決定の集約参照、findings は個別の差し戻し対象。
- **S3→S1 フィードバック強化**：従来「技術見積もり（配信実費・コスト・実現可能性）」と書かれていた粗いフィードバックが、コスト積算 / リスク台帳 / 実現可能性スコアカードという具体に分解される。S1 planning（マネタイズ価格・NFR 目標値・機能の実現可否）への戻し方が明確化する。
- **ADR-0015 を extends**：S3 スコープを 6 観点拡張。ADR-0015 本文は immutable・触らない。
- **ADR-0019 連携**：スコアカードは inline 派生ビュー（集約参照）として配置。専用ログ file は作らない原則を堅持。
- **ADR-0024（観点 ⑤）の S3 展開は本 ADR では決めない**：principal-engineer の評価観点に load-bearing claim 反証可能性を追加するかは S1 運用後に別 ADR で判断（ADR-0024 の未確定事項を踏襲）。

## 未確定

- **コスト積算のテンプレ**：1 ユーザーあたり infra+3rd party 費用、break-even、scaling cost の具体的な算出方法をテンプレ化するかは、`infrastructure-engineer` の運用 2〜3 サービスで実例を蓄積してから別 ADR で判断。
- **リスク台帳の分類軸**：SPOF / ベンダーロックイン / bus factor / 技術成熟度の他に、phuryn/pm-skills の 8 risk categories（Value / Usability / Viability / Feasibility / Ethics / GTM / Strategy / Team）を取り込むかは ADR-0024 未確定事項と連動。S1 / S3 双方で risk 取り扱いが安定してから検討。
- **観点 ⑤（load-bearing claim 反証可能性）の S3 展開**：principal-engineer の評価観点に追加するかは S1 運用後に判断（ADR-0024 と整合）。
- **G3 スコアカードの観点 12 軸の固定 vs 可変**：サービス性質で観点が変わる場合（例：B2B SaaS と consumer mobile で重視軸が違う）の取り扱い。固定にすると形骸化、可変にすると比較困難。S3 運用 2〜3 サービスで判断。

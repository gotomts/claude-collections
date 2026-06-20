# S1a stack-direction スキル追加（プロトタイプ前に技術判断を握る）

ADR-0015 で確定した `S3 tech-design` の「型 → スタック → モジュール → ドメインモデル → 運用基盤」のうち、**スタック判断 + データプロファイル当たり + 3rd party 制約 + build vs buy** をプロトタイプ（S2）より前に切り出し、新規スキル `S1a stack-direction` として独立させる。理由：プロトタイプの interaction 雛形（iOS HIG / Material / Web）は提供形態とスタックで全く別物になり、`S1b design-direction` が組む `DESIGN.md` の `## Components` セクションは提供形態に強く依存する。技術判断が S2 より後にあると、プロトタイプは技術未確定で組まれ、Components は技術整合しないまま Claude Design に渡る。この歪みを構造的に解消する。

## Status

accepted（ADR-0015 を extends：S3 から先行判断 4 観点を切り出す／ADR-0017 を extends：「人間 handoff 境界で 4 分割」のスキル数が 5 になる／ADR-0025 と並行：命名規約に従う／ADR-0013 共通形に従う）

## 決定

1. **新規スキル `S1a stack-direction`** を indie-studio に追加（`indie-studio/skills/stack-direction/SKILL.md`）。位置は `S1 service-discovery` と `S1b design-direction` の間。

2. **スコープは 4 観点**：プロトタイプ品質に直結するものに限定する：
   - **スタック決定**（提供形態起点・言語・FW・主要ライブラリ・データストア）
   - **データプロファイル当たり**（扱うデータの種別・量・成長・freshness）
   - **3rd party 依存と hard constraints**（auth / payment / storage / push / search / LLM API 等の rate limit・料金・SLA・ToS）
   - **build vs buy 判定**（foundational capability ごとの 自前 vs SaaS）

3. **入力**：アンカー4点（`docs/discovery/anchors/`、特に `provider.md` が起点）＋ S1 discovery corpus（`docs/discovery/`、特に feature-scope・persona・nfr）。同 repo を直読み（ADR-0010）。

4. **出力**：`<service-repo>/docs/tech/stack-direction/` 配下に 4 ファイル：
   - `stack.md`：スタック選定と根拠
   - `data-profile.md`：データプロファイル当たり
   - `third-party.md`：3rd party 依存と制約一覧
   - `build-vs-buy.md`：foundational capability ごとの判定表

5. **ロスター（最小構成）**：
   - `tech-lead`：4 観点すべての担当（スタック・データプロファイル・3rd party・build vs buy は技術判断として一体）
   - `reviewer`：評価（差し戻し・最大 3R）
   - **新規職種は追加しない**（indie dev 単独運用の持続可能性を優先）

6. **制御フロー**：共通形（ADR-0013／director ＋ 職種 ＋ 評価）／評価ループ（ADR-0018 round1 fresh → 2-3 凍結 continuation・最大 3R）／完全性ガード（ADR-0011 期待マニフェスト = 4 成果物・✅/➖/⚠️）／決定記録（ADR-0019 inline・繰り越しはマーカー）／self-grill ＋ decide-record-proceed（ADR-0004/0005 停止ゼロ）。

7. **ステージ構造**：
   ```plaintext
   ステージ1: スタック判断（提供形態 + データプロファイル → スタック）
     →〔一拍: 人間とスタック候補を確認（提供形態が複数の場合のみ）〕
   ステージ2: 3rd party + build vs buy 判断
     →〔一拍: build vs buy の方針確認（PRFAQ に "オフライン優先" 等の制約がある場合のみ）〕
     → 完全性ガード → S1b design-direction へ
   ```
   両方の対話点は条件付き発火（該当なしなら全自走・ADR-0004）。

8. **下流への影響を SKILL.md に明示**：
   - `S1b design-direction` は `## Components` セクションを書くときに本スキルの `stack.md` と `build-vs-buy.md` を読む（HIG / Material / Web に応じた具体記述になる）
   - `S3 tech-design` はスタック・3rd party・build vs buy を**読むだけ**（決め直さない）。`S3` ステージ1 の「型 → スタック → モジュール → ドメインモデル」のうち、スタック関連は本スキル確定済として扱う。

9. **破壊的操作の禁止**：push / PR / merge / 課金 / 外部送信はしない。repo へのファイル書き込みと commit に留まる（ADR-0004）。

## Considered Options

### A. 切り出すスコープ（4 観点 vs より狭く / より広く）

- **却下：スタック決定のみ**（最小スコープ）。プロトタイプの interaction 雛形は固まるが、「3rd party の rate limit で無料プラン UX が成立しない」「データが重すぎてプロトタイプの想定が破綻」が S2 後に判明し差し戻すリスクが残る。indie dev の反復コストを考えると前段で潰したい。
- **却下：4 観点 + AI/ML 実現可能性 + コスト天井**（広めスコープ）。AI 主軸でないサービスでは AI/ML 試算が空回りし、コスト天井はプロトタイプ後の数字とブレやすい。S1a が肥大化して焦点が失われる。コスト積算は S3 強化側（ADR-0027）で扱う。
- **採用：4 観点（スタック + データプロファイル + 3rd party + build vs buy）**。プロトタイプの interaction 雛形とフロー（自前 vs SaaS の UX 差）を両方握れる最小実用集合。AI/ML 実現可能性は AI 主軸サービスのみ条件付きで効くので S3 側で扱う方が安定する。

### B. 順序（S1a と S1b の前後）

- **却下：design-direction → stack-direction → prototype**。`DESIGN.md` の `## Components` が技術未確定で書かれる（現状の歪みが残る）。
- **却下：stack-direction ∥ design-direction（並列）**。並列 spawn の調整コストと Components 整合の事後 reconcile が必要。indie dev 単独運用ではメリットが見合わない。
- **採用：stack-direction → design-direction → prototype**。`DESIGN.md` の `## Components` が技術整合する。依存関係が明快。

### C. ロスター（職種数）

- **却下：tech-lead + product-engineer 新規 + architect + reviewer**（4 職種）。build vs buy を「事業判断」として product-engineer に振る案。しかし build vs buy は本質的に「技術 + コスト + 制約」の交差点で、tech-lead の視野で扱える。新規職種を立てると S1 / S3 ロスターと重複しやすく、indie dev の単独運用で持続できない。
- **却下：tech-lead だけ**（評価なし）。共通形（ADR-0013）の director ＋ 職種 ＋ 評価から逸脱する。reviewer 不在は品質ガードが効かない。
- **採用：tech-lead + reviewer**（既存 2 職種のみ）。スタック判断は技術一体の判断として tech-lead が見る。データプロファイルは「重さの当たり」止まりで S3 architect の domain model に引き継ぐ前提。新規職種を立てない。

## Consequences

- **新規ファイル**：
  - `indie-studio/skills/stack-direction/SKILL.md`（本スキル本体）
- **既存スキル更新**：
  - `indie-studio/skills/service-discovery/SKILL.md`：「後段（S1b design-direction）」節を「後段（S1a stack-direction → S1b design-direction）」に拡張、依存関係を明示
  - `indie-studio/skills/design-direction/SKILL.md`：「ここで扱わないこと」に「スタック決定・3rd party 制約・build vs buy（上流 S1a）」を追加、`## Components` セクションを書くときに S1a の `stack.md` / `build-vs-buy.md` を読む規約を追加
- **既存 agent 更新（責務拡張なし、参照追加のみ）**：
  - `indie-studio/agents/tech-lead.md`：本スキルでの担当（4 観点）を追加。既存 S3 での担当との切り分けを記述（S1a：4 観点を握る／S3：スタックは読むだけ、その他を深堀り）
- **下流への影響**：
  - `S1b design-direction` の `## Components` 精度向上（提供形態固有の component 仕様）
  - `S3 tech-design` の入力にスタック関連 4 ファイルが追加される（ADR-0027 で更新）
- **G3 ゲートには影響なし**：S1a は新規ゲートを生まない。次の人間ゲートは S2 プロトタイプを経て G2。
- **ADR-0015 を extends**：S3 から 4 観点を切り出す関係を本 ADR で確定（ADR-0015 本文は immutable・触らない）。
- **ADR-0017 を extends**：「人間 handoff 境界で 4 分割」が 5 分割になる（ADR-0023 で既に 5 になっており、本 ADR で 6 に。スキル数で数えれば 6・人間 handoff 境界としては変わらず）。
- **影響範囲**：1 新規ファイル + 2 既存 SKILL.md 更新 + 1 既存 agent.md 更新。`docs/discovery/` 配下は変更なし（S1 成果物は読むだけ）。

## 未確定

- **データプロファイルの S3 domain model への引き継ぎ形式**：S1a の `data-profile.md` を S3 architect が読み、domain model に展開する境界を明示する仕様。S1a 運用後に判明する詳細で別 ADR で決める。
- **build vs buy の判定基準テンプレ**：foundational capability（auth/payment/storage/push/search/LLM）ごとに「indie dev デフォルトは buy」「`PRFAQ に X 制約があれば build`」型のテンプレを作るかは、S1a 運用 1〜2 サービスで実例を蓄積してから別 ADR で判断する。

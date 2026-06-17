# HANDOFF — AI 自律開発ハーネス設計（grill-with-docs セッション）

> 別端末への引き継ぎ用。2026-06-17 時点。ブランチ `claude/grill-with-docs-0ooumk`。
> **真実源は `CONTEXT.md`・`docs/adr/0001`〜`0022`・`docs/ROADMAP.md`**。本書はその索引と現在地。
> 注意：コミットはローカルのみ（push 未）。別端末で読むには、このブランチを push → 別端末で pull が必要。

## 第2セッション追記（2026-06-17・スキル1 実装まで到達）

設計の残論点を ADR で決着させ、**スキル1（ステージ1）の実体を実装**した。

- **追加 ADR**：0018 評価ループ差し戻し protocol（全ステージ共通）／0019 DECISIONS.md 廃止（決定は inline/git/ADR・繰り越しは inline ⚠️マーカー＋ゲート提示）／0020 DESIGN.md＝repo-root の**具体デザイン憲法**（意図版 design-system 廃止・design-concept/system/tokens 集約・生成機構は未定）／0021 feature-details 廃止・screen-specs を area サブフォルダ化／0022 **S1 roster を実在職種で再構成**。
- **実装した実体**：`skills/service-discovery/SKILL.md`（ディレクター playbook）＋ 職種エージェント5体 `agents/{ux-researcher,product-manager,business-strategist,product-designer,reviewer}.md`。旧 `skills/service-derivation/` ＋ `agents/service-deriver.md` は**削除**。
- **残課題（重要）**：(a) **DESIGN.md の生成機構**（ADR-0020 決定5・mood/aesthetic は画像つき人間対話を要し純自律でない・担い手＝プロダクトデザイナー）→ スキル1 では未実装の TODO。(b) スキル1 の**実証**（socialcoffeenote）。(c) スキル2-4（技術設計 S3 / 分解 S4 / 実装 S5）の実体化。
- **再現方法**：context 消失時は `docs/adr/0018`〜`0022` と `skills/service-discovery/SKILL.md` を読めば、スキル1 の設計意図と実体が揃っている。スキル1 の修正・スキル2-4 の新規はこの ADR 群と SKILL.md の形式に従う。

## このリポジトリは何か
個人開発者が「企画→プロトタイプ→設計→実装→リリース」を一人で回すための **AI 自律開発ハーネス（制御層）**の設計と実装を集約する repo（`agents`、改名しうる）。ADR-0009：スキル・エージェント・オーケストレーター・設計判断を agents に集約（dotfiles の fleet は廃止予定）。

## このセッションでやったこと
当初タスクは「service-derivation スキルの実装」。だが grill 中に ROADMAP の「企画→ブリーフ＝1スキル」が根本から過小と判明し、**ハーネス全体（G1〜G5）を設計し直した**。ADR-0011〜0017 にコミット済み。**設計の幹は固まった。実装は未着手。**

## 全体像（確定）
- **ステージ列**：G1 アンカー / S1 企画→ブリーフ / S2 プロトタイプ(Claude Design・外部) / S3 技術設計 / S4 分解 / S5 実装。
- **人間は5ゲートだけ**（G1〜G5）。重要な意思決定は人間、それ以外は AI。全自動完走は目的でない。
- **文書は2モードのみ（ADR-0012）**：(1) AI 自律 (2) 人間と対話して AI が書く。**人間は手で文書を書かない**。アンカーは(2)。Obsidian vault はこのワークフローから退役（anchors も corpus も repo-native）。
- **共通ステージ形（ADR-0013）**：S2 以外の全ステージ＝**ディレクター（スキルを読んだメインセッションの制御役）＋ 職種エージェント群 ＋ 評価エージェント**。各ステージ＝自律導出＋枠組み判断の対話の混合。
- **feature-team / fleet 廃止（ADR-0013/0014）**：dev-\*/rev-\*/pr-publisher の**エージェント**は補助設計で廃止。ただし**スタック/レビュー技術スキル**（flutter-\*/expo-\*/dart-\*/next-\*/hono/vercel-\* 等）は資産として存続し職種へ割当。
- **ステージ間フィードバック**：G2→S1（プロトタイプの明確化を screen-specs 核ドキュメントへ書き戻し・陳腐化防止）。S3→S1（技術見積もりで マネタイズ価格/NFR/実現可否 を確定）。

## スキル分割（ADR-0017）＝4スキル
人間 handoff 境界で分割。ステージ/ロスターは各スキルの内部構造。
1. **アンカー対話＋企画・デザイン導出** → ブリーフ（G1＋S1。→ 人間が claude.ai へ）
2. **技術設計**（完成プロト起点・S3）
3. **分解**：index.md →〔G4 リスト承認〕→ Linear 起票（S4）
4. **実装**：起票済みチケット → PR（S5・→ G5）
- 横断オーケストレーターは複雑な自動連結を持たない（薄い launcher か不要）。人間が4スキルを順に起動。

## 職種ロスター（ADR-0014・現実の職種で）
- **S1（ADR-0022 で実在職種に再構成・5体＋ディレクター）**：ディレクター(スキル本体)/UX リサーチャー/プロダクトマネージャー(feature-scope/roadmap/specific-topics/risks/nfr)/ビジネスストラテジスト(competition/pitch/monetization/marketing/kpi/legal)/プロダクトデザイナー(screens/screen-specs・DESIGN.md は機構確定後)/レビュアー(評価)。旧 ADR-0011 の8体(プロダクトクリティーク・リスク法務品質・デザインシステムエンジニア)は廃止。
- **S3（6体）**：ディレクター/ソフトウェアアーキテクト/テックリード/インフラエンジニア/セキュリティエンジニア/プリンシパルエンジニア(評価)。
- **S4（4体）**：ディレクター/エンジニアリングマネージャー(or テックリード)/QA エンジニア(受入条件)/プリンシパルエンジニア(評価)。
- **S5（8体）**：ディレクター/フロント・バック・モバイル・インフラエンジニア(スタック別・並列)/コードレビュアー・セキュリティ・パフォーマンス(評価3観点)。**QA は置かず開発エンジニアがテスト・E2E を書く**。

## 出力レイアウト（ADR-0016）
```
<service-repo>/
├── AGENTS.md   # エージェント横断の指示(正本・S3 生成)
├── CLAUDE.md   # @AGENTS.md を参照する薄いポインタ
├── DESIGN.md   # デザインシステム(Claude Design ハンドオフ由来・S3 配置)
├── CONTEXT.md  # ユビキタス言語(S3 種まき→S5 育てる)
├── docs/
│   ├── adr/                 # S3 種まき→S5 追記
│   ├── discovery/           # S1: anchors/(prfaq,design-principles,provider,monetization-binary) planning/(01,02,05-14,99+feature-details) design/(design-concept,design-system,design-tokens,screens.md,screen-specs/) brief.md DECISIONS.md
│   ├── tech/                # S3
│   └── decomposition/       # S4 index.md(実 issue は Linear)
└── src/                     # S5 実装
```

## ハーネス設計の要点
- **screen-specs ライフサイクル**：S1 で導出(期待値)→Claude Design をブリーフ→プロトタイプで明確化→**書き戻して権威化**→S3/S4/S5 が読む。先行導出する理由＝Claude Design に無駄画面を作らせないため（ADR-0003 を自律前提で精緻化）。
- **完全性ガード（ADR-0011）**：期待マニフェスト＋3状態決着(✅生成合格/➖省略(理由)/⚠️未達(理由))＋ゲートでギャップレポート提示＝黙って欠落が通過しない。
- **評価ループ**：最大3ラウンド差し戻し（findings 付きで同一職種を continuation 再起動・該当ファイル改訂）→未達は decide-record-proceed。依存順厳守（上流合格→下流着手）。
- **画面一覧**：エージェントがドラフト→人間が枠組みレビュー（G4 相当の軽い関所）→以降自律。
- **moodboard 廃止**。デザイン層の出口＝design-system＋design-tokens を Claude Design に渡し準拠させる。
- **HITL/AFK は ADR-0005 通り「self-grill への粗いヒント」として残す**（廃止しない）。G5 のレビュー要否は別レイヤ＝根幹/非根幹タグ（ADR-0008）。
- **アンカー＝4独立ドキュメント**（提供形態は PRFAQ と別・ADR-0002）。

## 未着手 / 次の一手
1. **【最優先・スキル1 の穴】DESIGN.md の生成機構を決める**（ADR-0020 決定5）。mood/aesthetic は画像つき人間対話を要し純自律でない・担い手＝プロダクトデザイナー。決まれば `product-designer.md` と `service-discovery/SKILL.md` に DESIGN.md 生成を追加する。
2. **スキル1（service-discovery）の実証**（socialcoffeenote）。既存アンカー → 5エージェント → discovery corpus → ブリーフ。アンカー実体は Obsidian vault `projects/active-dev/socialcoffeenote/01-service-designer/`（03-prfaq, 04-design-principles, 09-monetization, 提供形態）。出力先 repo は `gotomts/socialcoffeenote`。**writing-skills の GREEN テスト＝この実証**。
3. **スキル2 技術設計（S3）**の実体化（ADR-0015・ロスター ADR-0014＝プリンシパルエンジニア等。S1 と同じ共通形）。
4. **スキル3 分解（S4）・スキル4 実装（S5）**の実体化（ADR-0015）。S5 は feature-team 後継。
5. **グローバル配送**：ユーザーが dotfiles 側で別途検討（agents が正本・ADR-0009、`~/.claude` は nix/home-manager 管理で agents は読み取り専用。skills は dotfiles への symlink）。

> スキル1 の SKILL.md ＋ エージェント5体は**実装済み**（第2セッション追記参照）。旧誤実装は削除済み。

## 進め方の約束（ユーザーの強い好み・メモリにも記録済み）
- **質問は yes/no か番号**で（散文の開いた質問はしない。AskUserQuestion ウィジェットは不安定なのでテキスト番号）。
- **実体に接地してから提案**（既存スキル定義・vault 成果物を先に読む。抽象論で先回りしない）。
- **決定を忘れない**：crystallize ごとに docs/ADR へ書き出す。
- **エージェントは現実の職種**で設計（成果物名で割らない）。
- **人間は文書を書かない**（AI 自律 or 対話駆動のみ）。
- **全体を把握してから細部**（枠組みズレは細部の正しさを無意味にする）。
- **廃止は punt せず・かつ勝手に決めずユーザー確認**（Linear/HITL を私が誤って廃止主張→撤回した前例あり）。

## 再開方法
`CONTEXT.md` → `docs/ROADMAP.md` → `docs/adr/0001`〜`0017` を読む。本 HANDOFF.md は索引。実装に入る前に「未着手/次の一手」のどれから着手するかをユーザーに確認する。

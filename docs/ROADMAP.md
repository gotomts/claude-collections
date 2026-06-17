# ROADMAP — AI 自律開発ハーネス

このリポジトリ（`agents`、改名しうる）を、AI による自律的な開発のためのスキル・エージェント・オーケストレーター集として育てる。本書は grill セッション（CONTEXT.md ＋ ADR-0001〜0010）で確定した設計を、着手可能な順序に落としたもの。

## 目的（ハーネスエンジニアリング）

アンカーを入力し、各大枠ゲートで承認するだけでリリース可能なソフトウェアに至る。人間の介入を「枠組みを決める/検証する瞬間」だけに局所化し、ステージ間の手配線（指揮者業務）をゼロにする。**枠組みがズレれば細部の正しさは無意味**（ADR-0007）。

## 設計の幹（確定済み）

- ADR-0001 アンカーゲート方式（人間はアンカーのみ、以降は自律導出）
- ADR-0002 アンカー集合＝PRFAQ／デザイン原則／提供形態／マネタイズ（ペルソナは導出）
- ADR-0003 プロトタイプ段を Claude Design に置換（prototype-designer/-builder 廃止）
- ADR-0004 自走設計（停止は設計ゲートと不可逆対外操作のみ）
- ADR-0005 self-grill（導出 corpus を答え合わせ材料に、ティアは決定単位ランタイム）
- ADR-0006 プロトタイプゲートは人間駆動の並列デュアル訂正（Claude Design ∥ Claude Code）
- ADR-0007 人間の意思決定を5つの大枠ゲートに限定
- ADR-0008 適応 PR ゲート（要否は G4 でタグ、非根幹は自動 merge）
- ADR-0009 agents＝ハーネスのホーム（fleet 廃止）
- ADR-0010 corpus は repo-native（サービス repo の docs/ サブツリー）
- ADR-0011 企画→ブリーフ段は多職種エージェント編成（ディレクター＋専門6＋評価1）。screen-specs は期待値として先行導出、moodboard 廃止、design-tokens を Claude Design に渡す。出力は `docs/discovery/`、完全性ガード（マニフェスト＋3状態＋ギャップレポート）
- ADR-0012 ドキュメントは AI が書く（自律 or 対話駆動）。人間は書かない。アンカーは対話駆動で AI が書く。Obsidian vault 退役
- ADR-0013 共通ステージ形（ディレクター＋職種＋評価／S2 除く全ステージ）。各ステージ＝自律＋枠組み対話の混合。feature-team/fleet 廃止し S5 を共通形で作り直す。ステージ間フィードバック（G2→S1 screen-specs 同期・S3→S1 価格/NFR/実現可否）
- ADR-0014 ステージ別職種ロスター（S1=8 / S3=6 / S4=4 / S5=8・S2 は無し）。dev-*/rev-* はエージェント廃止・スキルは存続し職種へ割当
- ADR-0015 S3/S4/S5 スキル設計（6観点）。アンカーは4独立ドキュメント（提供形態は別）。S4 は index.md=repo-native＋Linear 維持・HITL/AFK は粗いヒントで残す。S5 は QA を置かず dev がテスト・E2E（方針は S3 テスト戦略）
- ADR-0016 サービス repo の出力構成（discovery/tech/decomposition/src）。AGENTS.md 正本＋CLAUDE.md ポインタ、DESIGN.md は S3 配置

## ターゲット・パイプライン

```
アンカー(人間/G1)
  → [自律] オーケストレーターが deriver を起動 → 導出 corpus（完全・端折らない）＋ Claude Design ブリーフ
  → Claude Design でプロトタイプ → プロトタイプゲート(人間/G2、並列デュアル訂正)
  → [自律] tech-designer が self-grill → 技術設計 corpus → アーキ/インフラゲート(人間/G3)
  → [自律] 分解 → issue 一括リスト → 分解リストゲート(人間/G4、要否タグ) → 自動起票
  → [自律] feature-team が各 issue を self-grill → 停止ゼロで ticket→PR
  → PR レビュー(人間/G5、根幹のみ) ＋ merge
```

非根幹の細かい判断・操作（起票・精緻化・push・PR open・自動 merge）はすべて自律。

## 着手順序

1. **上流ループの実証**（最初の一手・下記）
2. Claude Design ハンドオフ → **feature-team/fleet を廃止し S5 実装ステージを共通形（ディレクター＋実装/レビュー職種＋評価）で作り直す**（停止ゼロ ticket→PR）、1スライスで実証
3. **tech-designer を自律 self-grill 導出**化（G3 corpus を人間に書かせない）
4. **G4 分解リスト**ゲート＋自動起票（要否タグ＝旧 HITL/AFK の後継）
5. 全ステージを繋ぐ**オーケストレーター**（＝このリポジトリの本体）

1〜2 が回れば価値は出ている。3〜5 は「指揮者業務ゼロ」の仕上げ。

## 最初の一手：上流ループの実証

**企画→ブリーフ段を「多職種エージェント編成」で作る**（ADR-0011）。当初の「`service-derivation` スキルを 1 つ作る」は誤り——この段は service-designer（固定 15 ページ）＋ prototype-designer（5 成果物・約 25 画面）が対話で作っていた corpus を、**対話なしの自律 self-grill** で同じ深さで生成する**多エージェントのチーム**である。

- 編成：**ディレクター（オーケストレーター＝スキル本体）＋ 専門 6 ＋ 評価 1＝8 体**（現実の職種に束ねる。ADR-0011 のロスター参照）。
- 入力：アンカー4点（PRFAQ／デザイン原則／提供形態／マネタイズ。Obsidian 執筆可）＋任意で参考リポ。
- 動作：各職種が **self-grill で**担当 corpus を導出（端折り禁止／一問一答なし／decide-record-proceed）→ 評価職種が答え合わせ・差し戻し → **画面一覧はドラフト後に人間が枠組みレビュー（軽い関所）** → 以降自律で **screen-specs（＝期待値）／design-system／design-tokens／ブリーフ** を生成。
- 出力：サービス repo の `docs/design/` に repo-native Markdown（ADR-0010）。**画面の最終仕様は先行導出した screen-specs（期待値）を Claude Design に渡し、プロトタイプ往復で育てる**（ADR-0011／0003／0006）。moodboard は廃止。
- 品質バー：**お粗末なプロトタイプは不可**。質は対話でなく self-grill の徹底度から出す。

**実証**：socialcoffeenote の既存アンカー → 本編成 → ブリーフ＋トークン → Claude Design → プロトタイプ。
**合否**：「既存アンカー → 触れるプロトタイプ」が数時間で、読める決定ログ付きで到達できるか。

> 未確定（grill 継続中）：評価職種の差し戻し protocol、`docs/design/` のファイル構成、機能別詳細素材の置き場、マネタイズ境界＝G2 繰り越しの扱い。既存の薄い実装（`skills/service-derivation` ＋ `agents/service-deriver`）は ADR-0011 で作り直し対象。

## 残る実装レベルの論点

- fleet（dotfiles）廃止の移行手順と、agents からの配送（symlink/inject、remote 対応）
- オーケストレーターの実装（ステージ連結・ゲート制御・状態管理）
- 信頼度ダイヤル（自動 merge ゾーン拡大）の運用基準と critical surface のパス/モジュール定義
- アンカーの DoD（PRFAQ がターゲットと中核シナリオを鋭く名指す）の明文化

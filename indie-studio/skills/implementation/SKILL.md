---
name: implementation
description: 起票済みの実装チケット(Linear)と技術設計 docs を起点に、垂直スライスを実装してテストを書き PR まで自走させたいときに使う、AI 自律開発ハーネスのステージ5(実装)スキル。旧 feature-team の後継。分解は上流(decomposition)、レビュー&merge は G5。停止ゼロで ticket→PR を回す。
maintainer: gotomts
---

# implementation

AI 自律開発ハーネスの **ステージ5（実装）** スキル。実行環境は **Claude Code**。旧 feature-team の後継を共通ステージ形（ADR-0013）で作り直したもの。ディレクターが束ね親（capability）単位で開発職種を並列起動し、各垂直スライスを実装＋テストし、評価3観点を経て **PR まで停止ゼロで自走**する。

到達点：**起票済みチケット → PR**を、実装途中で人間に聞かず（停止ゼロ・ADR-0004）、受入条件を満たして回す。人間は G5（根幹 PR のレビュー＋merge）だけ。

## いつ使うか

- 分解（decomposition）で起票済みのチケットを実装する段階に入ったとき。
- capability 束ね単位で垂直スライスを実装し PR を作りたいとき。
- ハーネス4スキル（ADR-0017）の4番目として人間が起動するとき。

**ここで扱わないこと**：分解・起票（上流 decomposition）。

## 入力

- **チケット**：Linear issue（依存順・受入条件・参照リンク・冪等キー `S-{nn}`）。
- **技術設計 docs**：同 repo の `AGENTS.md`/`CLAUDE.md`・`docs/adr/`・`CONTEXT.md`・`docs/indie-studio/tech/`・`docs/indie-studio/discovery/design/screen-specs/`・`DESIGN.md` を直読み。

## ロスター（8体・ADR-0014）

| エージェント | 役割 |
|---|---|
| `frontend-engineer` / `backend-engineer` / `mobile-engineer` | スタック別の実装（**S3 のスタックに応じて該当分のみ並列起動**） |
| `infrastructure-engineer` | 器構築・CI/CD・IaC 実装（S3 と同じ職種・S5 では実装側） |
| `code-reviewer` / `security-engineer` / `performance-engineer` | 評価3観点（品質 / セキュリティ / 性能。S3 の security-engineer を S5 ではレビュー観点で再利用） |

**QA は置かない**：開発エンジニアが unit/widget/受入/E2E を書く（垂直スライス＝test を貫く）。網羅性は評価3観点が見る。E2E 方針はスタック依存で **S3 テスト戦略**が決める（Web=Playwright／モバイル=Maestro・integration_test+patrol で主要フローに絞る）。

## ディレクター制御フロー

1. **束ね親（capability）単位で起動**：依存順に capability を取り、該当スタックの開発職種を**並列**で起動。独立スライスは並列、同一ファイル群は直列。
2. **評価ループ**（ADR-0018）：各スライス実装 → 評価3観点（code-reviewer/security/performance）が round1 fresh→凍結 continuation で評価・差し戻し（最大3R）。**performance-engineer は性能影響時のみ**。
3. **完全性ガード**：受入条件（チケット）を充足したか ✅/➖/⚠️ で決着。
4. **PR 組み上げ**：評価合格後、**ディレクターが push＋PR open**（1スライス=1PR・pr-publisher 吸収・ADR-0015）。開発職種は実装＋テスト＋ローカル commit まで（push/PR はしない）。

## 停止ゼロ・自走規律

- **実装途中は停止しない**（ADR-0004）。曖昧点は **decide-record-proceed**＝根拠ある仮定を置き、**仮定を PR に明記**して進む。
- 設計の穴・screen-specs の曖昧が出たら：仮定を PR に明記。**ADR 候補は ADR を書いて PR で晒す**。重大なら S3/S1 へ差し戻し（ディレクター判断）。
- 専用の決定ログ file は作らない。実装知見は `docs/adr/`・`CONTEXT.md` に追記（ADR-0016/0019）。

## 出力

- コード＋テスト＋ **PR**（GitHub・1スライス=1PR）。
- 実装知見を `docs/adr/`・`CONTEXT.md` に追記（docs は副産物・主成果はコードと PR）。

## G5（人間ゲート）

- **根幹 PR のみ人間がレビュー＋merge**。非根幹（G4 でタグ付け・ADR-0008）は green で自動 merge。精度向上に応じ自動 merge ゾーンを手で広げる。
- 実装途中は停止しない。人間が関わるのは G5 だけ。

## 破壊的操作の扱い

- **push / PR open は自律**（ADR-0007・スキル起動が ticket→PR フローの承認）。**ディレクターのみ**が行い、開発職種は行わない。
- **merge は G5 の人間**（根幹）または自動（非根幹）。**force-push・merge を勝手にしない**。課金・外部送信はしない。

## 関連 ADR

ステージ全体＝ADR-0013/0017。ロスター＝ADR-0014。スキル設計（テスト戦略・停止ゼロ）＝ADR-0015。評価ループ＝ADR-0018。適応 PR ゲート＝ADR-0008。自走設計＝ADR-0004。

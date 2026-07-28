---
name: implementation
description: 確定済みの実装詳細設計(5 成果物)と技術設計 docs を起点に、垂直スライスを実装してテストを書き、AC 検証・コードレビュー・PR まで自走させたいときに使う (実装中の設計判断は人間に聞かない)、AI 自律開発ハーネスのステージ5後半(実装)スキル。設計は上流(implementation-design)、レビュー&merge は G5。設計済みのスライスを実装だけ回すケースにも、一気通貫の後半としても使える。
argument-hint: "--slice=S-{nn}  # 対象スライスの冪等キー (省略時は plan.md ありかつ PR 未作成のものを提示して 1 問確認)"
maintainer: gotomts
---

# implementation

AI 自律開発ハーネスの **ステージ5後半（実装）** スキル。実行環境は **Claude Code**。ディレクターが **`enhance-superpowers:enhance-executing-plans` を chain invoke する薄いアダプタ**として動く（ADR-0032 D1）。以降 `gwt-test` → `write-review-response` → `finish-spec-pr` が自動連鎖して PR まで到達する。

到達点：**確定済み設計 → PR**を、**実装中の設計判断を人間に聞かずに**（decide-record-proceed・ADR-0004）、受入条件を満たして回す。人間が関与するのは **PR 作成前後の確認**（下記「人間が関与する点」）と **G5（根幹 PR のレビュー＋merge）**。

## いつ使うか

- `implementation-design` で実装詳細設計（5 成果物）が確定したスライスを実装する段階。
- **以前に設計だけ済ませておいたスライスを、実装から回したい**とき。
- 一気通貫の後半として `implementation-design` から chain されたとき。

**ここで扱わないこと**：分解・起票（S4 decomposition）。実装詳細設計（上流 implementation-design）。

## 前提（plugin 依存）

`enhance-superpowers` と `shared` の 2 plugin に依存する（root ADR-0009 / ADR-0032）。

## 入力

- **実装詳細設計（必須）**：`docs/indie-studio/implementation/S-{nn}-*/` の 5 成果物。**欠ければ停止**し `indie-studio:implementation-design` を促す。
- **チケット**：Linear issue（`S-{nn}`・受入条件・レビュー要否タグ）。
- **技術設計 docs**：`AGENTS.md`/`CLAUDE.md`・`docs/adr/`・`CONTEXT.md`・`docs/indie-studio/tech/`・screen-specs・`DESIGN.md`。

## 動作

### Step 0: 状態判定

1. `enhance-superpowers` / `shared` plugin が解決できるか確認。できなければ error 中断（install 手順を案内）。
2. 対象スライスを確定：`--slice=S-{nn}` 指定があればそれ、無ければ `docs/indie-studio/implementation/` 配下で **plan.md はあるが PR 未作成**のものを提示して 1 問確認。`{slug}` の導出規則とディレクトリ解決は `indie-studio:implementation-design` と同一（index.md のスライス見出し由来・glob 前方一致）。
3. **設計成果物の可視性を解決する**（`implementation-design` の 2 経路のどちらで来ても動く）。`docs/indie-studio/implementation/S-{nn}-*/` を冪等キー前方一致 glob で探す：
   - **(a) 現 branch にある** → そのまま使う（経路 A = 一気通貫、または設計 branch に戻ってきた場合）。**新しい branch を切らない**
   - **(b) 現 branch に無い** → base（既定 `main`）に merge 済みか確認（`git cat-file -e origin/main:<path>` 等）。あれば **base から新 branch を切って**実装する（経路 B = 設計だけ先に merge した場合）
   - **(c) どちらにも無い** → 停止：「実装詳細設計がありません。`indie-studio:implementation-design --slice=S-{nn}` を先に実行してください。設計済みの場合は、その branch に checkout するか設計 PR を merge してください」
4. **5 成果物が揃っているか確認**。`summary` / `design` / `gwt` / `pr-description` / `plan` の **1 つでも欠けていれば停止**し、欠けている file 名を挙げて `indie-studio:implementation-design --slice=S-{nn}` を促す（部分生成状態で実装連鎖を始めない）。
5. **設計完了 marker を確認**（`implementation-design` が plan.md 末尾に記録する `設計承認済み` marker）。無ければ「設計承認が未完了です」と報告し、`indie-studio:implementation-design --slice=S-{nn}` で Step 2 から再開するよう促して停止（承認ゲートの迂回を防ぐ）。
6. 判定結果（どの経路で成果物を解決したか・branch をどうするか）を user に明示。

### Step 1: branch 準備（Step 0 の判定に従う）

- **経路 A（現 branch に設計成果物がある）** → **branch を切らない**。その branch でそのまま実装する。設計 docs と実装が 1 PR にまとまる。
- **経路 B（base に merge 済み）** → `shared:start-stage-branch` を invoke して **base から**本スライス用の branch（＋必要なら worktree）を用意する。

いずれも **1 スライス = 1 PR**。経路 A では設計 commit も同じ PR に含まれる。

### Step 2: `enhance-superpowers:enhance-executing-plans` を chain invoke

`Skill` tool で次の引数を渡して invoke（ADR-0014 の E1/E3）：

```text
--output-dir=docs/indie-studio/implementation/{S-nn}-{slug}
--gate-mode=aggregate
```

`--gate-mode=aggregate` により、slice ごとの code-review 課金確認と chain 起動確認 (計 4 箇所) が自動化される。**PR 作成前後の確認は残る**（下記「自走規律と、人間が関与する点」・ADR-0032 D4）。引数は下流へ伝播する（**`--output-dir` は `finish-spec-pr` まで、`--gate-mode` は `write-review-response` まで**）。

dispatch prompt に次を明示する（enhance-superpowers 側は中立語彙のため・ADR-0031 の規律を skill 間 invocation にも適用）：

- **architecture 規約**：S3 確定の monorepo ＋ モジュラーモノリス ＋ クリーンアーキ ＋ DDD（`AGENTS.md` / `CONTEXT.md` を読ませる）
- **進行 protocol**：**実装中の設計判断で人間に聞かない**（ADR-0004）。曖昧点は decide-record-proceed ＝根拠ある仮定を置き**仮定を PR に明記**。設計の穴・screen-specs の曖昧も仮定明記。ADR 候補は ADR を書いて PR で晒す
- **差し戻し protocol**（ADR-0018・enhance-superpowers 側に無いため必ず渡す）：round1 は fresh で完全な findings マニフェスト → round2-3 は continuation で解消のみ検証（スコープ凍結）。成果物ごと**最大 3R**。finding ごとに ✅解消／➖省略(理由)／⚠️未達(理由) で決着
- **テスト戦略**：S3 が決めた値（Web=Playwright／モバイル=Maestro・integration_test+patrol で主要フローに絞る）
- **参照 docs**：`docs/indie-studio/tech/`・`docs/adr/`・`CONTEXT.md`・該当 screen-specs・`DESIGN.md`
- **権限分離**：executor は実装＋テスト＋ローカル commit まで。**push / PR open はしない**

### Step 3: 自動連鎖の完走を確認

`enhance-executing-plans` から `gwt-test`（AC 検証 + `shared:qa-engineer` + STOP POINT 2 の code-review + `shared:security-engineer`）→ `write-review-response`（指摘の採用/Skip 判定）→ `finish-spec-pr`（`shared:finish-stage-pr` 経由で push + PR）まで自動で走る。

ディレクターは連鎖が途切れていないかを確認し、途切れていれば該当 skill を直接 invoke して復帰させる（silent failure 回避）。

### Step 4: G5 タグの引き渡し

PR 作成後、**レビュー要否タグ（根幹/非根幹・ADR-0008）**が PR に反映されているか確認する。

- **根幹** → 人間がレビュー＋merge（G5）
- **非根幹** → green で自動 merge

タグは S4 `decomposition` が index.md で付け、`implementation-design` が pr-description に引き継いだもの。欠けていれば index.md を参照して補う。

### Step 5: 実装知見の還元

実装で得た知見を `docs/adr/`・`CONTEXT.md` に追記する（docs は副産物・主成果はコードと PR）。専用の決定ログ file は作らない（ADR-0019）。設計の穴が重大なら S3 / S1 へ差し戻す（ディレクター判断）。

## 自走規律と、人間が関与する点（実態・ADR-0032 D4）

**自走するのは実装中の設計判断**である。曖昧点は **decide-record-proceed** ＝根拠ある仮定を置き、**仮定を PR に明記**して進む（ADR-0004）。設計の穴・screen-specs の曖昧も同様。ADR 候補は ADR を書いて PR で晒す。

一方、**PR 作成の前後には委譲先の必須確認が残る**。`--gate-mode=aggregate` が自動化するのは slice ごとの code-review 課金確認と chain 起動確認の 4 箇所であり、以下は集約されない。「人間は G5 だけ」ではない。

**無条件（毎回発生）**：

- `enhance-executing-plans` Step 0 の状態判定確認
- `write-review-response` の**採用分反映確認**と **push 前承認**
- `finish-spec-pr` の **PR title 確認**（同 skill が「必須」と明記）
- `shared:finish-stage-pr` Step 8 の **PR 作成最終確認**
- **G5**（根幹 PR のレビュー＋merge。非根幹は green で自動 merge）

**条件付き（該当時のみ）**：

- slice の対象領域が自動推定できない場合の 1 問確認
- review 指摘が出た場合の修正方針確認
- AC 未達時の差し戻し確認
- dev server の port 重複 / `chrome-devtools-mcp` 使用可否（環境要因）

**評価の委譲**：評価は enhance-superpowers 側の review dispatch に寄せる（`shared:security-engineer` / `shared:performance-engineer` / `code-review:code-review` skill）。**indie-studio 側の自前評価 3 観点ループは廃止**（重複するため・ADR-0032 D5）。差し戻し protocol は Step 2 の prompt で渡す。

## 出力

- コード＋テスト＋ **PR**（GitHub・1 スライス = 1 PR）。
- 実装知見を `docs/adr/`・`CONTEXT.md` に追記。
- 5 成果物のレビュー履歴に dispatch log（ADR-0007・enhance-superpowers 側が追記）。

## 破壊的操作の扱い

- **push / PR open は自律**（ADR-0007・スキル起動が ticket→PR フローの承認）。実行は `shared:finish-stage-pr` 経由。開発職種エージェントは行わない（権限分離）。
- **merge は G5 の人間**（根幹）または自動（非根幹）。**force-push・merge を勝手にしない**。

## 失敗時の挙動

| 状況 | 挙動 |
|---|---|
| `enhance-superpowers` / `shared` 未 install | error 報告 + install 手順を案内して中断（Step 0） |
| plan.md が無い | 停止 +「`indie-studio:implementation-design --slice=S-{nn}` を先に実行してください」 |
| 連鎖が途中で止まった | 途切れた箇所の skill を直接 invoke して復帰（`enhance-executing-plans` / `gwt-test` / `write-review-response` / `finish-spec-pr` はいずれも Step 0 状態判定で再開できる） |
| review の差し戻しが 3R で収束しない | ⚠️未達として PR に明記し、G5 で人間に晒す（黙って通さない） |
| 設計の穴が重大でスライス境界の問題と判明 | S4 `decomposition` へ差し戻しを提案（ディレクター判断） |

## 関連 ADR

S5 分割と委譲＝ADR-0032（D1 アダプタ / D2 粒度対応 / D4 人間ゲートの範囲 / D5 評価ループ）。自走設計＝ADR-0004（実装中の設計判断について維持）。issue 精緻化・push・PR open の自律＝ADR-0007。適応 PR ゲート＝ADR-0008。評価ループ＝ADR-0018。決定記録＝ADR-0019。ステージ全体＝ADR-0013/0017。plugin 依存＝root ADR-0009。委譲先の引数＝enhance-superpowers ADR-0014。

---
name: implementation-design
description: 起票済みの実装チケット(Linear)と技術設計 docs を起点に、1 スライス分の実装詳細設計(5 成果物 = summary/design/gwt/pr-description/plan)を確定し、Linear issue へ書き戻して精緻化したいときに使う、AI 自律開発ハーネスのステージ5前半(実装詳細設計)スキル。設計だけ先に済ませて後日実装するケース、設計と実装を一気通貫で回すケースの両方に対応する。分解は上流(decomposition)、実装は下流(implementation)の責務。
argument-hint: "--slice=S-{nn}  # 対象スライスの冪等キー (省略時は index.md の依存順から未着手の先頭を提示して 1 問確認)"
maintainer: gotomts
---

# implementation-design

AI 自律開発ハーネスの **ステージ5前半（実装詳細設計）** スキル。実行環境は **Claude Code**。ディレクターが indie-studio の corpus とチケットから context を組み立て、**`enhance-superpowers:enhance-brainstorming` を chain invoke する薄いアダプタ**として動く（ADR-0032 D1）。

到達点：**起票済みチケット → 実装可能な詳細設計（5 成果物）＋ 精緻化された Linear issue**を、設計承認 1 回で作る。

## いつ使うか

- 分解（decomposition）で起票済みのチケットに、実装の詳細設計を付けたいとき。
- **設計だけ先に進めて issue を精緻化しておきたい**とき（実装は後日・別セッション）。
- 一気通貫で実装まで回したいとき（末尾の 1 問で `indie-studio:implementation` へ chain）。

**ここで扱わないこと**：分解・起票（上流 decomposition）。実装・テスト・PR（下流 implementation）。サービス全体のアーキ設計（S3 tech-design）。

## 前提（plugin 依存）

本スキルは `enhance-superpowers` と `shared` の 2 plugin に依存する（root ADR-0009 / ADR-0032）。未 install なら chain invoke が失敗するため、Step 0 で存在を確認する。

## 粒度の対応（ADR-0032 D2）

「スライス」の語が両コレクションで別の意味を持つため、対応を固定する。

| indie-studio | enhance-superpowers |
|---|---|
| 垂直スライス = 1 チケット（`S-{nn}`）= 1 PR | **1 Spec セット（5 成果物）** |
| （該当なし） | plan.md 内の slice = その Spec 内の実装ステップ（PR を割らない） |

本スキルは indie-studio スライス **1 つ**を enhance-superpowers に渡す。capability（束ね親）単位で回す場合は、ディレクターが capability 内のスライスを依存順にループする。

## 入力

- **チケット**：Linear issue（`S-{nn}`・受入条件・参照リンク・依存順）。
- **分解骨格**：`docs/indie-studio/decomposition/index.md`（スライス定義・F-ID 対応・HITL/AFK タグ・レビュー要否タグ）。
- **技術設計**：`docs/indie-studio/tech/`（architecture / domain-model / perf-budget / security / compliance / risk-register）。
- **画面仕様**：`docs/indie-studio/discovery/design/screen-specs/`。
- **repo 規約**：`AGENTS.md`（正本）・`CLAUDE.md`・`CONTEXT.md`（ユビキタス言語）・`docs/adr/`・`DESIGN.md`。

## 出力先とディレクトリ解決（ADR-0032 D3）

```text
docs/indie-studio/implementation/{S-nn}-{slug}/
├── {YYYY-MM-DD}-{slug}-summary.md
├── {YYYY-MM-DD}-{slug}-design.md
├── {YYYY-MM-DD}-{slug}-gwt.md
├── {YYYY-MM-DD}-{slug}-pr-description.md
└── {YYYY-MM-DD}-{slug}-plan.md
```

**branch ではなく冪等キー `S-{nn}` 基準**。設計時と実装時で branch が変わっても成果物を発見できるようにするため。

- **`{slug}` の導出元は `index.md` のスライス見出し**（唯一の真実源）。見出しを小文字 kebab-case 化し、英数字とハイフン以外を除去して最大 40 文字で切る。Linear の issue title は使わない（編集されうるため）。
- **ディレクトリ解決は冪等キーの前方一致 glob `docs/indie-studio/implementation/S-{nn}-*/`** で行う。`{slug}` の再導出結果が過去と食い違っても既存ディレクトリを発見できる。
- glob が **2 件以上**ヒットしたら、どれを使うか user に 1 問確認する（slug 変更で重複が生まれた可能性を報告）。

## 動作

### Step 0: 状態判定

1. `enhance-superpowers` / `shared` plugin の skill・agent が解決できるか確認。解決しなければ error 中断（「`/plugin install enhance-superpowers@claude-collections` と `shared@claude-collections` が必要」と案内）。
2. 対象スライスを確定：`--slice=S-{nn}` 指定があればそれ、無ければ `index.md` の依存順から**未着手の先頭**を提示して 1 問確認。
3. `docs/indie-studio/implementation/S-{nn}-*/` を glob して 5 成果物の有無を確認：
   - ディレクトリ未存在 or 全て未存在 → Step 1 から
   - 一部存在 → Step 2 で委譲する（`enhance-brainstorming` の Step 0 が Phase を判定するので**ここでは重複判定しない**）
   - 5 成果物揃い済み → 「設計は完了しています。Linear 書き戻し（Step 3）から再開しますか / 実装（`indie-studio:implementation --slice=S-{nn}`）に進みますか」と 1 問確認
4. 判定結果を user に明示。

### Step 1: context 組み立て

Linear issue と上記「入力」の docs を Read し、`enhance-brainstorming` に渡す context を組み立てる。**中立語彙で書かれた enhance-superpowers 側に indie-studio 固有値を prompt で明示的に渡す**（ADR-0031 の規律を skill 間 invocation にも適用）。

- **topic**：チケットのタイトル + 受入条件
- **architecture 規約**：S3 で確定した monorepo ＋ モジュラーモノリス ＋ クリーンアーキ ＋ DDD（`AGENTS.md` / `CONTEXT.md` を読ませる）
- **参照 docs のパス**：`docs/indie-studio/tech/` 一式・該当 screen-specs・`DESIGN.md`・`docs/adr/`
- **スコープ境界**：**本スライス（1 PR）に限る**。他スライスへはみ出さない
- **F-ID**：本スライスが被覆する `F-{MODULE}-{連番}`（index.md 由来）
- **テスト戦略**：S3 が決めた値（Web=Playwright／モバイル=Maestro・integration_test+patrol で主要フローに絞る）
- **タグ**：レビュー要否（根幹/非根幹・ADR-0008）。G5 の merge 判断に使うため pr-description に残させる
- **一括提示に載せる indie-studio 観点の補足材料**（設計ゲートで人間が見る材料。**先渡しして Step 6-A の提示に含めさせる**）：
  - 本スライスが被覆する F-ID と index.md の受入条件との対応
  - S3 技術設計（architecture / domain-model / perf-budget / security）との整合確認結果
  - screen-specs との整合、`⚠️繰り越し` マーカーの有無
  - レビュー要否タグ（根幹/非根幹）

### Step 2: `enhance-superpowers:enhance-brainstorming` を chain invoke（設計ゲートを含む）

`Skill` tool で次の引数を渡して invoke（ADR-0014 の E1/E2/E3）：

```text
--output-dir=docs/indie-studio/implementation/{S-nn}-{slug}
--no-chain
--gate-mode=aggregate
```

- `--no-chain`：実装への自動遷移を止める。実装は本スキルの Step 4 で判断する
- `--gate-mode=aggregate`：Phase 2 / 3 / 4 の承認 3 回を自動通過させ、**Step 6-A の一括提示で設計承認 1 回**にまとめる（ADR-0032 D4）

**設計ゲート（人間・1 回）は `enhance-brainstorming` の Step 6-A で成立する。** 本スキルは Step 1 で補足材料を先渡ししているため、Step 6-A の一括提示に indie-studio 観点が含まれた状態で人間がレビューする。**本スキル側で再提示・再承認はしない**（二重ゲートを作らない）。

**差し戻し時の再入経路**：Step 6-A で差し戻しが出たら、`enhance-brainstorming` 内部の差し戻し protocol（該当 file 再生成 → 5 成果物を揃えて再提示）で収束させる。制御が本スキルに戻った後に追加修正が必要になった場合は、**`enhance-brainstorming` を同一引数で再 invoke** する（Step 0 の中間状態判定が該当 Phase から再開する）。本スキルが 5 成果物を自前で書き直すことはしない（薄いアダプタの責務外）。

### Step 3: Linear issue への書き戻し（自律・ADR-0007）

設計承認後、Linear issue を精緻化する。**issue 精緻化は自律操作**（ADR-0007 / `CONTEXT.md` の大枠ゲート定義「起票・精緻化・push・PR open は自律」）。停止しない。

入力は **`{出力先}` の 5 成果物**（Step 2 の設計ゲートを通った経路でも、Step 0 の「5 成果物揃い済み」経路でも同じ）。

- design.md / gwt.md への参照リンク
- gwt.md の AC を issue の受入条件へ反映（**既存 AC は置換せず追記し、差分を明示する**）
- 実装手順の要約（plan.md 由来）

### Step 4: 停止 or 実装へ chain

1. user に「設計フェーズ完了。実装に進みますか / ここで止めますか」**1 問確認**
2. 止める → 「実装は `indie-studio:implementation --slice=S-{nn}` で再開できます」と案内して終了（**ケース 1**）
3. 進む → `Skill` tool で `indie-studio:implementation` を **`--slice=S-{nn}` を渡して** chain invoke（**ケース 3**）

## 人間が関与する点（実態・ADR-0032 D4）

「ゲート 1 回」は**設計承認**についての話であり、設計フェーズで人間が一切関与しないという意味ではない。実際に関わるのは次の通り。

**無条件**：

- Step 0 の状態判定確認（誤検出の catch。本スキルと `enhance-brainstorming` の Step 0 で各 1 回）
- `enhance-brainstorming` Phase 1 の要件詰め対話（一問一答。設計の入力を作る工程そのもの）
- **設計承認 1 回**（Step 6-A の一括提示）← 本命ゲート
- Step 4 の chain 判断 1 問

**条件付き（該当時のみ。コンプライアンス trigger であり承認 gate ではない）**：

- 機微情報チェック（個人情報 / 決済 / 医療 / 認証情報を扱う設計の場合）
- ライセンスチェック（制限ライセンスの依存を追加する場合）

`--gate-mode=aggregate` が集約するのは **Phase 2 / 3 / 4 の承認 3 回**であり、上記のコンプライアンス trigger と状態判定確認は集約対象外（enhance-superpowers ADR-0014 E3）。

## 自走規律

- 曖昧点は decide-record-proceed（根拠ある決定を下し設計 docs に inline で残す・ADR-0019）。未決は `⚠️繰り越し` マーカー＋候補を inline。
- ADR-0008 の適応ゲート（根幹/非根幹による自動 merge 振り分け）は **G5 でのみ**使う。設計ゲートには適用しない（根幹/非根幹を問わず設計承認を取る・ADR-0032 D4）。

## 破壊的操作の扱い

- push / PR / merge / 課金はしない（実装フェーズの責務）。
- Linear への書き戻しは**自律**（ADR-0007。可逆・内部的な書き込み）。

## 失敗時の挙動

| 状況 | 挙動 |
|---|---|
| `enhance-superpowers` / `shared` 未 install | error 報告 + install 手順を案内して中断（Step 0） |
| 対象スライスが index.md に無い | 上流 `indie-studio:decomposition` へ差し戻しを提案 |
| glob が 2 件以上ヒット | どれを使うか user に 1 問確認（slug 変更による重複を報告） |
| Linear issue が見つからない | index.md の骨格だけで設計を進めるか 1 問確認（起票漏れの可能性を報告） |
| S3 技術設計に F-ID 機能一覧が無い | 上流 `indie-studio:tech-design` へ差し戻し（decomposition と同じ停止条件） |
| `enhance-brainstorming` が `--output-dir` を無視して `docs/superpowers/{branch}/` に出力 | 成果物を正しい出力先へ移動 → user に報告。再発するなら enhance-superpowers ADR-0014 E1 の実装を見直す |
| 設計ゲートで根本的なスコープ相違が発覚 | 上流 `indie-studio:decomposition`（スライス粒度）へ差し戻しを提案 |

## 関連 ADR

本スキルの新設と S5 分割＝ADR-0032。停止ゼロの部分改定＝ADR-0032 D4（ADR-0004 を改定）。出力先＝ADR-0032 D3（ADR-0016 / 0028 のレイアウトを S5 について更新）。issue 精緻化の自律＝ADR-0007。適応 PR ゲート＝ADR-0008（G5 のみ）。決定記録＝ADR-0019。中立 agent への context 受け渡し＝ADR-0031。スキル分割境界＝ADR-0017。plugin 依存＝root ADR-0009。委譲先の引数＝enhance-superpowers ADR-0014。

---
name: implementation-spec
description: 起票済みの実装チケット(Linear)と技術設計 docs を起点に、1 スライス分の実装仕様(summary/spec/gwt/pr-description/plan)を確定し、issue を精緻化してから実装以降を enhance-superpowers へ委譲したいときに使う、AI 自律開発ハーネスのステージ5スキル。上流の確定物(tech / screen-specs / index.md)から起こすので要件を会話で作り直さない。分解・起票は上流(decomposition)、実装・検証・PR は enhance-superpowers の責務。
argument-hint: "--slice=S-{nn}  # 対象スライスの冪等キー (省略時は index.md の依存順から未着手の先頭を提示して 1 問確認)"
maintainer: gotomts
---

# implementation-spec

AI 自律開発ハーネスの **ステージ5** スキル。実行環境は **Claude Code**。1 スライス分の**実装仕様を確定し、issue を精緻化し、実装以降を `enhance-superpowers` へ委譲する**（ADR-0032）。

到達点：**起票済みチケット → 実装仕様 5 成果物 ＋ 精緻化された issue**。そこから先（実装・AC 検証・コードレビュー・PR）は委譲先が担う。

## いつ使うか

- 分解（`decomposition`）で起票済みのチケットを実装に移す段階。
- S4 を通していない単発作業（割り込みのバグ修正・小改修）に仕様を付けたいとき。

**ここで扱わないこと**：骨格作成・issue 起票（上流 `decomposition`）／**実装・テスト・AC 検証・コードレビュー・PR 作成**（`enhance-superpowers` に委譲）／サービス全体のアーキ設計（S3 `tech-design`）。

## 前提（plugin 依存）

`enhance-superpowers` と `shared` の install が必須（root ADR-0009 / ADR-0032）。未 install なら Step 0 で error 中断する。

## 担当範囲

```text
S4 decomposition        骨格 → issue 起票
  ↓
本スキル
  summary → [spec + gwt + pr-description] → issue 精緻化 → plan
  ↓
enhance-superpowers:enhance-executing-plans
  → gwt-test → write-review-response → finish-spec-pr（PR まで自動連鎖）
```

**`issue 精緻化` を plan の前に挟む**のが本スキルの独自点。`enhance-brainstorming` は Phase 3 の直後に制御を返さないため、この順序は委譲では実現できない（ADR-0032 Context）。

## 出力先とディレクトリ解決

```text
docs/indie-studio/implementation/{S-nn}-{slug}/
├── {YYYY-MM-DD}-{slug}-summary.md
├── {YYYY-MM-DD}-{slug}-spec.md
├── {YYYY-MM-DD}-{slug}-gwt.md
├── {YYYY-MM-DD}-{slug}-pr-description.md
└── {YYYY-MM-DD}-{slug}-plan.md
```

- **`{slug}` の導出元は `index.md` のスライス見出し**。小文字 kebab-case 化し、英数字とハイフン以外を除去して最大 40 文字。Linear の issue title は使わない（編集されうるため）。
- **ディレクトリ解決は冪等キーの前方一致 glob `docs/indie-studio/implementation/S-{nn}-*/`**。`{slug}` の再導出が過去と食い違っても既存を発見できる。2 件以上ヒットしたら user に 1 問確認。

## ⚠️ 委譲先の入力契約（勝手に変えない・ADR-0032 D2）

**成果物の形式は `enhance-superpowers` 側の仕様**である。ただし**全てが必須なわけではない** — 実際に崩すと連鎖が壊れるのは次の 2 つで、他は緩い。

- **`*-plan.md` の存在と `## レビュー履歴` セクション**（`enhance-executing-plans` Step 0 は存在を前提として要求し〔無ければ error 中断〕、さらに末尾の `## レビュー履歴` を Read して再開位置を判定する。**存在するだけでは足りない**）
- **`*-gwt.md` の checklist と履歴セクション**（`gwt-test` が読んで判定に使う）

| 項目 | 契約 |
|---|---|
| ファイル名 | `{YYYY-MM-DD}-{slug}-{suffix}.md`。suffix は `summary` / **`spec`** / `gwt` / `pr-description` / `plan` |
| **suffix は `spec`** | 実装の詳細設計は **`spec.md`**。`design` は UI デザイン仕様に明け渡す（`design-direction` / `DESIGN.md` と衝突するため）。**委譲先はこれを要求しない** — 検証したところ `gwt-test` / `write-review-response` / `finish-spec-pr` は `design` に一切言及せず、`enhance-executing-plans` のハード要件も `*-plan.md`（存在＋`## レビュー履歴`）のみ（ADR-0034） |
| `plan.md` | `## レビュー履歴` セクション必須（`enhance-executing-plans` の状態判定が読む） |
| `gwt.md` | `- [ ] AC-N: ...` 形式の checklist、`## 変更履歴`（`{YYYY-MM-DD HH:MM}` 逆時系列）、`## レビュー履歴` 必須（`gwt-test` が読む） |
| `pr-description.md` | `## やったこと` / `## 動作確認方法` は必須。**`## 補足` は内容が無ければセクションごと削除してよい**（`finish-spec-pr` 自身が「内容がなければセクションごと削除」と規定しているため、空で残すほうが契約違反） |

## 動作

### Step 0: 状態判定

1. `enhance-superpowers` / `shared` plugin が解決できるか確認。できなければ error 中断（install 手順を案内）。
2. **対象スライスと入力の確定**（`--slice=S-{nn}` 指定があればそれ、無ければ `index.md` の依存順から未着手の先頭を提示して 1 問確認）：

   | 状況 | 挙動 |
   |---|---|
   | Linear issue **あり** | 正規。それを起点にする |
   | issue 無し・**`index.md` にスライスあり** | **起票漏れ**。ただし起票は外部書き込みなので、**`index.md` が G4 承認済みであることを確認**してから起票する（G4 承認は S4 の前提・ADR-0008）。承認済みか判定できなければ user に明示承認を取る。起票後は正規フローに乗せる |
   | issue 無し・**`index.md` にも無し** | S4 を通さない単発作業。**ヒアリングで要件を聞き取り Spec を書く。issue は作らず Step 3（issue 精緻化）をスキップ**。骨格作成・起票は行わない（S4 の責務・ADR-0032 D1） |

3. 出力先を glob して既存成果物を確認：
   - 未存在 → Step 1 から
   - 一部存在 → 欠けている成果物から再開
   - 5 つ揃い済み → **spec.md の `## レビュー履歴` にある `設計承認済み` marker**（Step 3-a）を確認。**あり** → Step 5（委譲）へ／**なし** → Step 2 の承認から（marker は Step 3-a 時点で plan.md が未生成のため spec.md に書く）
4. 判定結果を user に明示。

### Step 1: summary 生成

**上流の確定物から起こす。会話で要件を作り直さない**（ADR-0032 D3）。

材料＝issue 本文／`decomposition/index.md` のスライス定義と F-ID／受入条件。

- 何を作るか・どの方式か・効いている設計判断を書く
- スコープは**本スライス（= 1 PR）に限る**
- 不足・矛盾があれば user に確認するが、確定済みの要件は問い直さない

### Step 2: spec + gwt + pr-description を一括生成 → 承認 1 回

3 つまとめて生成し、**揃ってから人間の承認 1 回**（enhance-superpowers ADR-0011 と同型）。

**spec.md**（実装詳細仕様）
- 材料＝`tech/`（architecture / domain-model / perf-budget / security）・該当 screen-specs・`DESIGN.md`・`CONTEXT.md`
- モジュール配置・型・関数分割・データフロー・エラー処理を具体で書く
- architecture 規約は S3 確定の monorepo ＋ モジュラーモノリス ＋ クリーンアーキ ＋ DDD
- `shared:software-architect` を能動 dispatch（SOLID / モジュール境界）
- `shared:security-engineer` を能動 dispatch（認証 / 認可 / データ取扱 / 外部入力）

**gwt.md**（受入条件）
- 材料＝**S4 `qa-engineer` が作った受入条件**と screen-specs。ゼロから作らない
- `- [ ] AC-N: ...` 形式の checklist（委譲先 `gwt-test` が読む）
- `## 変更履歴` と `## レビュー履歴` セクションを置く
- `shared:qa-engineer` を能動 dispatch（異常系 / 境界値 / 空状態の網羅性）

**pr-description.md**
- `## やったこと`（spec のスコープ）／`## 補足`（無ければセクションごと削除）／`## 動作確認方法`（gwt の AC 由来）

**承認（人間ゲート）**：3 file 揃えて提示する。あわせて次を添える。

- 本スライスが被覆する F-ID と `index.md` の受入条件との対応
- `tech/` との整合、`⚠️繰り越し` マーカーの有無
- レビュー要否タグ（根幹/非根幹・ADR-0008）

差し戻し時は該当 file のみ再生成して 3 file を揃えて再提示（承認単位は一括を維持）。

### Step 3: 設計承認 marker ＋ issue 精緻化

**3-a. marker を記録**

plan.md はまだ無いので、**spec.md 末尾の `## レビュー履歴`** に記録する：

```text
{YYYY-MM-DD HH:MM} - 設計承認済み (implementation-spec Step 2 / gwt-hash: sha256:xxxx)
```

**5 成果物が揃っているだけでは完了と見なさない。** この marker が唯一の完了判定（Step 0 が確認する）。

**3-b. issue 精緻化**（自律・ADR-0007）

**issue 精緻化は自律操作**（`CONTEXT.md` の大枠ゲート定義「起票・精緻化・push・PR open は自律」）。停止しない。

- spec.md / gwt.md への参照リンク
- gwt.md の AC を issue の受入条件へ反映（**既存 AC は置換せず追記し差分を明示**）

**冪等性**：issue 本文末尾に `<!-- indie-studio-sync: S-{nn} gwt-hash:sha256:xxxx -->` を埋める。書き戻し前に読み、**同じ hash があれば no-op**。hash が違う場合のみ差分を追記して marker を更新する。

**issue が無い場合**（Step 0 の 3 つ目のケース）は本 Step をスキップし、その旨を spec.md のレビュー履歴に記録する。

### Step 4: plan 生成

材料＝spec.md と F-ID。実装手順を書く。

- **`## レビュー履歴` セクション必須**（委譲先の状態判定が読む）
- テスト戦略は S3 が決めた値（Web=Playwright／モバイル=Maestro・integration_test+patrol で主要フローに絞る）
- `shared:engineering-manager` を能動 dispatch（手順の妥当性・依存順）

### Step 5: 実装以降を委譲

`Skill` tool で invoke：

```text
enhance-superpowers:enhance-executing-plans --output-dir=docs/indie-studio/implementation/{S-nn}-{slug}
```

以降 `gwt-test` → `write-review-response` → `finish-spec-pr` が自動連鎖して PR まで到達する。**本スキルは実装・検証・レビュー・PR のロジックを持たない**（ADR-0032 D4）。

- `--gate-mode=aggregate` を渡すかは運用判断（enhance-superpowers ADR-0014 E3）。渡さなければ従来どおり各 Phase で承認を取る
- **invocation 時に「実装の詳細仕様は `*-spec.md`」と明示する。** `enhance-executing-plans` は executor へ渡す「参照 docs」を `design.md` と名指ししているため（同 skill の Step 3）、伝えないと executor が spec.md を読み落とす。**これは prompt での context 提供であり、enhance-superpowers 側の変更ではない**
- **`enhance-superpowers` 側には引数以外の要求をしない**（変更を加えない・ADR-0032 D5）
- 連鎖が途切れたら該当 skill を直接 invoke して復帰させる（`--output-dir` を同じ値で渡すこと）

## 人間が関与する点

- Step 0 の状態判定確認
- **Step 2 の承認 1 回**（本スキル唯一の設計ゲート）
- issue が無い単発作業の場合はヒアリング
- 委譲後は `enhance-superpowers` 側の gate に従う（PR title 確認・push 前承認・`shared:finish-stage-pr` の最終確認）
- **G5**：根幹 PR のレビュー＋merge（非根幹は green で自動 merge・ADR-0008）

## 自走規律

- 曖昧点は decide-record-proceed（根拠ある決定を下し docs に inline で残す・ADR-0019）。未決は `⚠️繰り越し` マーカー＋候補を inline。
- issue 精緻化・push・PR open は自律（ADR-0007）。

## 失敗時の挙動

| 状況 | 挙動 |
|---|---|
| `enhance-superpowers` / `shared` 未 install | error 報告 + install 手順を案内して中断 |
| glob が 2 件以上ヒット | どれを使うか user に 1 問確認（slug 変更による重複を報告） |
| `tech/` に F-ID 機能一覧が無い | 上流 `tech-design` へ差し戻し |
| 承認時にスコープ相違が発覚 | 上流 `decomposition`（スライス粒度）へ差し戻しを提案 |
| 委譲先が成果物を見つけられない | **入力契約（上記）違反を疑う**。ファイル名 suffix・必須セクションを確認する |
| 委譲先の連鎖が途中で止まった | 途切れた skill を直接 invoke（いずれも Step 0 状態判定で再開可・`--output-dir` を渡す） |

## 関連 ADR

本スキル＝ADR-0032（D1 担当範囲 / D2 入力契約 / D3 上流由来 / D4 委譲 / D5 enhance-superpowers 不変）。**ファイル名 suffix ＝ADR-0034**（ADR-0032 D2 を改定し `design` → `spec`）。ステージ全体＝ADR-0013/0017。評価ループ＝ADR-0018。決定記録＝ADR-0019。適応 PR ゲート＝ADR-0008。issue 精緻化の自律＝ADR-0007。出力レイアウト＝ADR-0016/0028。中立 agent への context 受け渡し＝ADR-0031。plugin 依存＝root ADR-0009。委譲先の引数＝enhance-superpowers ADR-0014。

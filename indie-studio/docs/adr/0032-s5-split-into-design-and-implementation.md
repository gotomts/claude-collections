# S5 を「実装詳細設計」と「実装」の 2 スキルに割り、enhance-superpowers へ委譲する

S5（実装）を `implementation-design`（実装詳細設計）と `implementation`（実装）の 2 スキルに割り、いずれも **enhance-superpowers の skill を chain invoke する薄いアダプタ**として実装する。両者は独立起動でき、連続実行もできる。あわせて S5 の設計フェーズに**承認ゲートを 1 回置く**（ADR-0004 の部分改定）。

## Status

accepted（2026-07-28）。S5 に限って次を更新する — **ADR-0015**（S5 スキル設計）／**ADR-0013**（共通ステージ形）／**ADR-0017**（スキル分割境界。S5 が 1→2 スキルになりハーネスは計 7 スキルへ）／**ADR-0016**（「S5 はコードと PR が成果物・docs を出さない」を改め、S5 も設計 docs を出す）／**ADR-0028**（出力レイアウトに `implementation/` を追加）。**ADR-0004**（自走設計）は S5 設計フェーズについて部分改定する（D4）。**ADR-0007**（起票・精緻化は自律）は改定せず従う（D6）。root ADR-0009（shared plugin 化）を前提とする。

## Context

S5 の現行 `implementation` skill は、Linear チケットと S3 技術設計 docs を入力に、開発職種を並列起動して実装 → 評価 3 観点 → PR まで回す。ここには **スライス単位の実装詳細設計が無い**：

- S3 `tech-design` はサービス全体のアーキ設計であって「このスライスをどう実装するか」ではない
- S4 `decomposition` の受入条件は BDD レベルで、型・関数分割・テストケース・動作確認手順を含まない
- 結果、実装職種は詳細設計なしにいきなりコードを書く

一方 enhance-superpowers は、まさにこの層を 5 成果物（summary / design / gwt / pr-description / plan）として持ち、実装フェーズ（`enhance-executing-plans`）と後工程連鎖（`gwt-test` → `write-review-response` → `finish-spec-pr`）、Step 0 状態判定まで備えている。**S5 に無いものが enhance-superpowers に丸ごとある。**

さらにユーザーの運用実態として、S5 の使い方は 3 通りある：

1. 先に設計だけ終えて Linear issue を精緻化しておく
2. 設計済みのものを実装以降だけ回す
3. 一気通貫で回す

現行の単一 skill ではこの 3 通りを表現できない。

## Decision

### D1. S5 を 2 スキルに割り、enhance-superpowers へ委譲する

| skill | 責務 | 委譲先 |
|---|---|---|
| `implementation-design` | 1 スライス（= 1 チケット = 1 PR）の実装詳細設計を 5 成果物として確定し、Linear issue を精緻化する | `enhance-superpowers:enhance-brainstorming` |
| `implementation` | 確定済み設計を入力に実装 → 検証 → レビュー → PR | `enhance-superpowers:enhance-executing-plans`（以降 `gwt-test` → `write-review-response` → `finish-spec-pr` へ自動連鎖） |

両者は **薄いアダプタ**とする。indie-studio 固有の橋渡し（Linear チケット読み書き・`docs/indie-studio/` corpus のパス・G4 タグ・G5 ゲート・ADR-0018 差し戻し protocol）をアダプタ側に閉じ込め、enhance-superpowers 側には indie-studio 語彙を持ち込まない（CONTEXT.md の禁止語彙を維持）。

起動パターン：ケース 1 = `implementation-design` のみ／ケース 2 = `implementation` のみ／ケース 3 = `implementation-design` 末尾の 1 問で `implementation` へ chain。

### D2. 粒度の対応を固定する

「スライス」が両コレクションで別の意味を持つため、対応を明示する：

- **indie-studio のスライス** = 垂直スライス = 1 チケット（`S-{nn}`）= 1 PR = **enhance-superpowers の 1 Spec セット（5 成果物）**
- **enhance-superpowers の plan.md 内 slice** = その Spec 内の実装ステップ（PR を割らない）

アダプタは indie-studio スライス 1 つを enhance-superpowers に渡す。capability（束ね親）単位で回す場合は、アダプタが capability 内のスライスを依存順にループする。

### D3. 成果物は冪等キー基準のディレクトリに置く

enhance-superpowers 既定の `docs/superpowers/{branch}/` は**使わない**。ケース 1（設計だけ先行）では設計時と実装時で branch が変わり、成果物を発見できなくなるため。S4 の冪等キーを使った次を出力先とする：

```text
docs/indie-studio/implementation/{S-nn}-{slug}/
```

enhance-superpowers 側に出力先の引数化が必要（enhance-superpowers ADR-0014 の E1）。

**冪等キー基準の命名が解くのは「発見性」だけで「可視性」は解かない。** 設計成果物が設計 branch にしか commit されていなければ、別 branch の実装セッションからは見えない。そこで **2 経路を両方サポート**し、`implementation-design` の Step 4 で人間が選ぶ：

| 経路 | 内容 | 用途 |
|---|---|---|
| **A. そのまま実装** | branch を切り替えず実装へ chain。設計 docs と実装が 1 PR にまとまる | ケース 3（一気通貫） |
| **B. 設計だけ先に merge** | 設計成果物だけの PR を出し base（既定 `main`）に merge。以後どの branch からでも見える | ケース 1（設計先行・複数スライスの設計をまとめて進めたい場合） |

`implementation` は Step 0 で **現 branch → base の順に探し、A / B どちらで来ても動く**。どちらにも無ければ停止する。

**設計の完了判定は「5 成果物が揃っていること」ではなく、plan.md のレビュー履歴に記録される「設計承認済み」marker とする。** file が揃っていても承認前に中断していれば marker が無く、実装へ進めない（承認ゲートの迂回を構造的に防ぐ）。Linear への書き戻しは gwt.md の hash を同期 marker として issue 本文に埋め、同一 hash なら no-op にして冪等性を担保する。

### D4. 実装詳細設計に承認ゲートを 1 回置く（ADR-0004 の部分改定）

**根幹 / 非根幹を問わず、設計フェーズ完了時に人間の承認を 1 回挟む。** ADR-0004 の「実装途中は停止しない・人間は G5 のみ」を、S5 の**設計フェーズに限って**改定する。

理由：運用してみると、実装詳細設計を人間が見ないと精度が足りない。設計ミスが実装完了後まで検出されず手戻りが大きくなる。ケース 1「設計だけ先に終えて issue を精緻化したい」という要求自体が、人間が設計を見たいという要求である。

- **設計フェーズ**：**承認ゲート 1 回**。enhance-superpowers 側の Phase 2 / 3 / 4 の承認 3 回は `--gate-mode=aggregate` で 1 回に集約する（enhance-superpowers ADR-0014 の E3）。アダプタは indie-studio 観点の補足材料を invocation 時に**先渡し**し、集約された一括提示に載せる。**アダプタ側で再提示・再承認はしない**（二重ゲートを作らない）。
- **実装フェーズ**：**実装中の設計判断では停止しない**（ADR-0004 の decide-record-proceed を維持）。

**「人間は G5 だけ」ではない。** 集約されるのは承認 gate に限られ、次は残る。誤解を避けるため実態を列挙する。

| フェーズ | 無条件に残る人間の関与 |
|---|---|
| 設計 | 各 skill の Step 0 状態判定確認／Phase 1 の要件詰め対話／**設計承認 1 回**／実装へ進むかの chain 判断 |
| 設計（条件付き） | 機微情報チェック・ライセンスチェック（コンプライアンス trigger であって承認 gate ではないため集約対象外） |
| 実装 | Step 0 状態判定確認／採用分反映確認／**push 前承認**／**PR title 確認**／`shared:finish-stage-pr` の PR 作成最終確認 |
| 実装（条件付き） | slice 領域の推定不能時／review 指摘時／AC 未達差し戻し時／port 重複・`chrome-devtools-mcp` 可否（環境要因） |

PR 作成系の確認まで自動化する案は採らない（下記 Alternatives）。**両スキルの SKILL.md はこの表と同じ粒度で実態を明記する**こと。「停止ゼロ」という語は S5 では使わない（実装中の設計判断に限った性質であり、フェーズ全体の性質ではないため）。

ADR-0008 の適応 PR ゲート（根幹 / 非根幹タグによる自動 merge 振り分け）は **G5 でのみ**使い、設計ゲートには適用しない。

### D5. 評価ループは prompt で補う

ADR-0018 の差し戻し protocol（round1 fresh → 凍結 continuation・成果物ごと最大 3R・上流再オープン深さ 1）は enhance-superpowers 側に無い。アダプタが `enhance-executing-plans` へ渡す prompt で明示指定して補う。indie-studio 側の自前評価ループ（評価 3 観点の独自 dispatch）は廃止し、enhance-superpowers 側の review dispatch に寄せる（重複するため）。

### D6. Linear issue の書き戻し（精緻化）は自律とする

`implementation-design` の Linear 書き戻しに承認を置かない。ADR-0007 の Consequences と `CONTEXT.md` の大枠ゲート定義が「起票・**精緻化**・push・PR open は自律」と決めており、真実源に従う。ADR-0007 は「issue-decomposer の『起票前に必ず人間承認（省略不可）』は G4 のリストレビューに置き換え、起票自体の停止は廃止」とも明記しているため、書き戻しに承認を足すことは同 ADR の明示的な決定に反する。

ただし**既存 AC は置換せず追記し、差分を明示する**規律は残す（人間が後から差分を追える形にする）。

## Consequences

- **indie-studio は enhance-superpowers に依存する。** `shared` と合わせて 3 plugin の install が前提になる。marketplace description / README に明記する。
- S5 に実装詳細設計の層が入り、実装職種が詳細設計・AC・動作確認方法・実装手順を持った状態でコードを書くようになる。
- Step 0 状態判定（enhance-superpowers ADR-0012）が S5 にも効き、中断・別セッション再開ができるようになる。
- gwt-test（AC 検証）・CodeRabbit レビュー・review-response の連鎖が S5 に入る。現行 S5 には無かった。
- ADR-0015 の S5 記述（「ディレクターが束ね親単位で開発職種を並列起動 → 評価 3 観点 → PR」）は D1 / D5 で置き換わる。ロスター（ADR-0014 の S5 = 8 体）は enhance-superpowers 側の dispatch matrix に吸収される。
- **「停止ゼロ」「人間は G5 だけ」は S5 について成り立たない。** 設計フェーズに承認ゲートが 1 回入り、実装フェーズにも PR 作成系の必須確認（push 前承認・PR title・finish-stage-pr 最終確認）が残る。ADR-0004 の思想（自走設計）は「実装中の設計判断で停止しない」という形で維持されるが、フェーズ全体の性質としての停止ゼロは主張しない。D4 の表が実態の正本。

## Alternatives Considered

- **`--gate-mode=aggregate` を PR 作成系の確認（push 前承認・PR title・`shared:finish-stage-pr` 最終確認）まで拡張して真に停止ゼロにする**：主張と実態は一致するが、`shared:finish-stage-pr` に auto-confirm mode を足すことになり他 consumer にも影響する。かつ PR 作成が完全無確認になるのは、D4 の理由（人間が目を通さないと精度が足りない）と逆方向。却下し、代わりに実態を明記する方針を採った。
- **shared/skills/ に中立化した設計・実装 skill を切り出し、両コレクションが参照する**：依存方向が対等になり自己完結性を保てるが、`enhance-brainstorming` は「5 成果物 / `docs/superpowers/` / superpowers 公式への Y 方式委譲 / templates」が body に焼き付いており、中立化すると enhance-superpowers 側が空洞化する。却下。
- **indie-studio 側に等価な 2 skill を独自実装する**：自己完結を保てるが二重メンテになり、enhance-superpowers 側の改善が伝播しない。却下。
- **設計ゲートを根幹スライスのみに置く（ADR-0008 のタグを再利用）**：適応ゲートの思想と一貫し gate 回数を減らせるが、非根幹スライスの設計ミスが実装後まで検出されない。運用上「人間が目を通さないと精度が微妙」という判断で却下（D4 の理由）。
- **一気通貫では全 gate を auto-approve する**：ADR-0004 を貫けるが、同じく設計ミスの検出が実装完了後にずれる。却下。

## 関連

- ADR-0007（五大枠ゲート）：D6 で従う。「起票・精緻化・push・PR open は自律」
- ADR-0016（サービス repo 出力レイアウト）：「S5 は docs を出さない」を D3 が S5 について更新
- ADR-0028（indie-studio 出力の docs 名前空間化）：レイアウト図に `implementation/` を追加
- ADR-0017（スキル分割は人間 handoff 境界）：S5 の 1→2 分割でスキル総数が 7 になる
- ADR-0004（自走設計）：D4 で S5 設計フェーズについて部分改定。実装フェーズでは維持
- ADR-0008（適応 PR ゲート）：G5 でのみ使用。設計ゲートには適用しない
- ADR-0013（共通ステージ形）／ADR-0014（ロスター）／ADR-0015（S5 スキル設計）：S5 部分を本 ADR が更新
- ADR-0018（評価ループ）：D5 で prompt 経由の指定に変える
- ADR-0031（中立 agent への invocation context）：アダプタが渡す context の規律として継続
- root ADR-0009（shared plugin 化）：plugin 間参照の前提
- enhance-superpowers ADR-0014：本 ADR が要求する E1 / E2 / E3 の後方互換改修

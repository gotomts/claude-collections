# S5 を「実装詳細設計」と「実装」の 2 スキルに割り、enhance-superpowers へ委譲する

S5（実装）を `implementation-design`（実装詳細設計）と `implementation`（実装）の 2 スキルに割り、いずれも **enhance-superpowers の skill を chain invoke する薄いアダプタ**として実装する。両者は独立起動でき、連続実行もできる。あわせて S5 の設計フェーズに**人間ゲートを 1 回置く**（ADR-0004 停止ゼロの部分改定）。

## Status

accepted（2026-07-28）。ADR-0015 の S5 スキル設計と ADR-0013 の共通ステージ形を、S5 に限って更新する。ADR-0004（自走設計）を S5 設計フェーズについて部分改定する。root ADR-0009（shared plugin 化）を前提とする。

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

```
docs/indie-studio/implementation/{S-nn}-{slug}/
```

enhance-superpowers 側に出力先の引数化が必要（enhance-superpowers ADR-0014 の E1）。

### D4. 実装詳細設計に人間ゲートを 1 回置く（ADR-0004 の部分改定）

**根幹 / 非根幹を問わず、設計フェーズ完了時に人間レビューを 1 回挟む。** ADR-0004 の「実装途中は停止しない・人間は G5 のみ」を、S5 の**設計フェーズに限って**改定する。

理由：運用してみると、実装詳細設計を人間が見ないと精度が足りない。設計ミスが実装完了後まで検出されず手戻りが大きくなる。ケース 1「設計だけ先に終えて issue を精緻化したい」という要求自体が、人間が設計を見たいという要求である。

- **設計フェーズ**：人間ゲート 1 回。ただし enhance-superpowers 側の承認 gate 5 箇所（Phase 2 / Phase 3 の 3-file / Phase 4 / slice ごと code-review / chain 起動）は**アダプタが集約して 1 回にまとめる**（enhance-superpowers ADR-0014 の E3）。gate を 5 回通させない。
- **実装フェーズ**：**停止ゼロを維持**（ADR-0004 のまま）。slice ごとの code-review は実行に固定、chain 起動確認は自動化する。
- 人間が関与するのは「設計レビュー 1 回」と「G5（根幹 PR の merge）」の 2 点。

ADR-0008 の適応 PR ゲート（根幹 / 非根幹タグによる自動 merge 振り分け）は **G5 でのみ**使い、設計ゲートには適用しない。

### D5. 評価ループは prompt で補う

ADR-0018 の差し戻し protocol（round1 fresh → 凍結 continuation・成果物ごと最大 3R・上流再オープン深さ 1）は enhance-superpowers 側に無い。アダプタが `enhance-executing-plans` へ渡す prompt で明示指定して補う。indie-studio 側の自前評価ループ（評価 3 観点の独自 dispatch）は廃止し、enhance-superpowers 側の review dispatch に寄せる（重複するため）。

## Consequences

- **indie-studio は enhance-superpowers に依存する。** `shared` と合わせて 3 plugin の install が前提になる。marketplace description / README に明記する。
- S5 に実装詳細設計の層が入り、実装職種が詳細設計・AC・動作確認方法・実装手順を持った状態でコードを書くようになる。
- Step 0 状態判定（enhance-superpowers ADR-0012）が S5 にも効き、中断・別セッション再開ができるようになる。
- gwt-test（AC 検証）・CodeRabbit レビュー・review-response の連鎖が S5 に入る。現行 S5 には無かった。
- ADR-0015 の S5 記述（「ディレクターが束ね親単位で開発職種を並列起動 → 評価 3 観点 → PR」）は D1 / D5 で置き換わる。ロスター（ADR-0014 の S5 = 8 体）は enhance-superpowers 側の dispatch matrix に吸収される。
- **停止ゼロが S5 全体では成り立たなくなる。** 設計フェーズに 1 ゲートが入る。ADR-0004 の思想（自走設計）は実装フェーズで維持されるが、「人間は G5 だけ」という記述は S5 について不正確になる。

## Alternatives Considered

- **shared/skills/ に中立化した設計・実装 skill を切り出し、両コレクションが参照する**：依存方向が対等になり自己完結性を保てるが、`enhance-brainstorming` は「5 成果物 / `docs/superpowers/` / superpowers 公式への Y 方式委譲 / templates」が body に焼き付いており、中立化すると enhance-superpowers 側が空洞化する。却下。
- **indie-studio 側に等価な 2 skill を独自実装する**：自己完結を保てるが二重メンテになり、enhance-superpowers 側の改善が伝播しない。却下。
- **設計ゲートを根幹スライスのみに置く（ADR-0008 のタグを再利用）**：適応ゲートの思想と一貫し gate 回数を減らせるが、非根幹スライスの設計ミスが実装後まで検出されない。運用上「人間が目を通さないと精度が微妙」という判断で却下（D4 の理由）。
- **一気通貫では全 gate を auto-approve する**：ADR-0004 を貫けるが、同じく設計ミスの検出が実装完了後にずれる。却下。

## 関連

- ADR-0004（自走設計）：D4 で S5 設計フェーズについて部分改定。実装フェーズでは維持
- ADR-0008（適応 PR ゲート）：G5 でのみ使用。設計ゲートには適用しない
- ADR-0013（共通ステージ形）／ADR-0014（ロスター）／ADR-0015（S5 スキル設計）：S5 部分を本 ADR が更新
- ADR-0018（評価ループ）：D5 で prompt 経由の指定に変える
- ADR-0031（中立 agent への invocation context）：アダプタが渡す context の規律として継続
- root ADR-0009（shared plugin 化）：plugin 間参照の前提
- enhance-superpowers ADR-0014：本 ADR が要求する E1 / E2 / E3 の後方互換改修

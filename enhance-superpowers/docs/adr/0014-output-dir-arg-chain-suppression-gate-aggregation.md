# 0014. 出力先の引数化・chain 抑止・承認 gate 集約 mode を追加する (外部 collection からの利用対応)

`enhance-brainstorming` / `enhance-executing-plans` に 3 つの後方互換な拡張を入れる — (E1) 成果物の出力先引数化、(E2) 実装フェーズへの chain 抑止、(E3) 承認 gate の集約 mode。いずれも引数省略時は従来挙動を維持する。

## Status

Accepted (2026-07-28)。ADR-0011（plan-last 順序）と ADR-0012（実装フェーズ skill 化・Step 0 状態判定）を extends する。生成順・Phase 定義・dispatch matrix は変更しない。

## Context

indie-studio コレクションが S5（実装ステージ）を本コレクションへ委譲する（indie-studio ADR-0032）。その際、現行仕様のままでは 3 点が成立しない。

**(1) 出力先が branch 固定** — 成果物は `docs/superpowers/{branch}/` に置かれ、branch 名から解決される。呼び出し元が「設計だけ先に済ませ、後日別 branch で実装する」運用をすると、実装時に設計成果物を発見できない。呼び出し元はチケットの冪等キーなど branch 非依存のキーで成果物を管理したい。

**(2) Spec フェーズ完了後に無条件 chain** — `enhance-brainstorming` Step 7 は「Spec フェーズが完了しました。次は実装です」と告げて `enhance-executing-plans` を chain invoke する。Spec だけ確定して止める分岐が仕様に無い。「設計だけ先に終えて issue を精緻化する」運用ができない。

**(3) 承認 gate が 5 箇所** — Phase 2（summary）／Phase 3（3-file 一括）／Phase 4（plan）／slice ごとの code-review 1 問／chain 起動 1 問。本コレクション単体では認識齟齬検出として機能する（3 重の関所）が、自走を前提とする呼び出し元から使うと gate が過剰になる。呼び出し元は「まとめて 1 回だけ人間に見せる」形にしたい。

これらは外部利用に限った要求ではなく、(2) は本コレクション単体でも「Spec レビューを挟んでから実装したい」場面で有用である。

## Decision

**3 つの引数を追加する。いずれも省略時は現行挙動と完全に同一とし、既存の呼び出しを壊さない。**

### E1. 出力先ディレクトリの引数化

`enhance-brainstorming` / `enhance-executing-plans` が `output-dir` 引数を受け取る。

- 指定時：5 成果物・`review-response.md`・`handoff.md` の配置先を指定ディレクトリにする。Step 0 の状態判定も同ディレクトリを走査する。
- 省略時：従来どおり `docs/superpowers/{branch}/`（branch 名は `/` → `-` にサニタイズ）。

ファイル命名規約（`{YYYY-MM-DD}-{slug}-{suffix}.md`）は変更しない。

### E2. chain 抑止

`enhance-brainstorming` が `no-chain` 引数を受け取る。

- 指定時：Step 7 で `enhance-executing-plans` を chain invoke せず、「Spec フェーズ完了。実装は `enhance-executing-plans` を invoke してください」と案内して終了する。
- 省略時：従来どおり chain invoke する。

あわせて、**引数を省略した場合も Step 7 冒頭で「実装フェーズに進みますか / Spec で止めますか」の 1 問確認を入れる**。無条件 chain は「Spec レビューを挟みたい」という素直な要求を潰していた。この 1 問は `no-chain` 指定時にはスキップする（意図が既に表明されているため）。

### E3. 承認 gate の集約 mode

両 skill が `gate-mode` 引数を受け取る（`per-phase` / `aggregate`、既定は `per-phase`）。

- `aggregate` 指定時（`enhance-brainstorming`）：Phase 2 / Phase 3 / Phase 4 の user 承認を自動通過させ、5 成果物が揃った時点で**一括提示して 1 回だけ承認を取る**。差し戻しがあれば該当 file を再生成し、再び一括提示する。agent の能動 dispatch・機微情報チェック・ライセンスチェックは**従来どおり全て実行する**（gate を減らすだけで、検証は減らさない）。
- `aggregate` 指定時（`enhance-executing-plans`）：slice ごとの code-review 1 問確認を **実行に固定**し、Step 5 の chain 起動 1 問確認を**自動 yes** にする。attempt marker / final marker の idempotent 制御は維持する。
- `per-phase`（既定）：従来どおり各 Phase で承認を取る。

**機微情報チェック（ADR-0008）とライセンスチェック（ADR-0009）の user 確認は `aggregate` でも省略しない。** これらは承認 gate ではなくコンプライアンス trigger であり、集約対象外とする。

## Consequences

- 外部 collection（indie-studio 等）が本コレクションを実装エンジンとして利用できるようになる。呼び出し元は成果物の配置と gate 回数を自分の運用に合わせられる。
- 本コレクション単体の既定挙動は一切変わらない。引数を渡さない既存の invoke はすべて従来どおり動く。
- E2 の「Step 7 で 1 問確認」だけは既定挙動の変更にあたる（従来は無条件 chain）。ただし chain を止める手段が無かった状態の是正であり、yes を選べば従来と同じ流れになる。
- `aggregate` は認識齟齬検出の関所を 3 箇所から 1 箇所に減らす。Spec フェーズの思想（ADR-0011 の 3 重分散）とトレードオフになるため、**呼び出し元が自走前提の運用を持つ場合に限って使う**ものとし、単体利用では `per-phase` を既定のまま使う。
- Step 0 の状態判定（ADR-0012 D2）は `output-dir` を見るようになる。呼び出し元が指定を忘れると別ディレクトリを走査して「未着手」と誤判定するため、引数は呼び出しごとに一貫して渡す必要がある。

## Alternatives Considered

- **enhance-superpowers を改修せず、呼び出し元が成果物を後から移動する**：Step 0 の状態判定が `docs/superpowers/{branch}/` を見続けるため再開が壊れる。却下。
- **gate を完全に廃止する mode を作る**：呼び出し元（indie-studio ADR-0032 D4）が「人間が目を通さないと精度が足りない」と判断しており、需要が無い。1 回に集約する `aggregate` で足りる。却下。
- **外部利用専用の別 skill を新設する**：`enhance-brainstorming` の本体ロジックを二重に持つことになり、改善が片方に伝播しない。引数追加で足りる。却下。

## 関連

- ADR-0011（plan-last-order-and-design-gwt-prd-merged）：生成順は変更しない
- ADR-0012（implementation-phase-skill-and-state-detection）：E1 が Step 0 の走査先に影響する
- ADR-0008（機微情報チェック）／ADR-0009（ライセンスチェック）：`aggregate` でも省略しない
- indie-studio ADR-0032：本 ADR の 3 拡張を要求する呼び出し元の決定

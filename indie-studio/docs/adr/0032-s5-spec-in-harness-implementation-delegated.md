# S5 は Spec フェーズと issue 精緻化をハーネス側に持ち、実装以降を enhance-superpowers へ委譲する

S5（実装ステージ）を skill 1 本にする。**Spec 4 成果物の生成 → issue 精緻化 → plan 生成**までを indie-studio が担い、**実装・検証・レビュー・PR は `enhance-superpowers:enhance-executing-plans` を呼んで丸ごと委譲**する。**enhance-superpowers には一切変更を加えない。**

## Status

accepted（2026-07-28）。ADR-0015（S3/S4/S5 スキル設計）の S5 部分と ADR-0013（共通ステージ形）を S5 に限って更新する。ADR-0017（スキル分割）は S5 が 1 本のままなのでスキル総数 6 を維持する。

## Context

S5 には**スライス単位の実装詳細設計が無かった**。S3 `tech-design` はサービス全体のアーキ設計、S4 `decomposition` の受入条件は BDD レベルで、実装職種が詳細設計なしにコードを書いていた。この層は `enhance-superpowers` が Spec 5 成果物として持っている。

当初、indie-studio 側に薄いアダプタ skill を 2 本置き `enhance-brainstorming` を chain invoke する設計を採ったが、**破棄した**。理由は 3 つ。

1. **上流成果物を捨てていた。** `enhance-brainstorming` の Phase 1 は「1 ターン 1 問で要件・制約・成功基準を詰める」「2-3 アプローチを提示して合意」から始まる。S1〜S4 で要件もアプローチも確定済みなのに、**会話で作り直す**ことになる。
2. **issue を扱えない。** `enhance-superpowers` は issue の入力も書き戻しも持たない。S5 に必須の「issue 精緻化」が抜ける。
3. **順序を満たせない。** ハーネスに必要な順序は `骨格 → issue → summary → [spec + gwt + pr-description] → issue 精緻化 → plan → 実装` だが、`enhance-brainstorming` は Phase 3 の直後に制御を返さずそのまま Phase 4（plan）へ進むため、**plan の前に issue 精緻化を挟めない**。

### enhance-superpowers を変更しないという制約

`enhance-superpowers` は**業務で稼働している**。既定挙動・成果物名・生成順を変える改修は、たとえ opt-in 引数であってもリスクを持ち込む。**本 ADR は enhance-superpowers を一切変更しない**ことを前提とする。

その結果、上記 3 の順序制約は「Spec フェーズを indie-studio 側で持つ」以外に解けない。

## Decision

### D1. S5 は skill 1 本。Spec フェーズと issue 精緻化を持つ

```text
S4 decomposition          骨格 → issue 起票（既存）
  ↓
S5 skill（本 ADR で新設）
  1. issue を起点に summary を生成
  2. spec + gwt + pr-description を一括生成
  3. issue 精緻化（AC と設計リンクを issue へ反映）
  4. plan を生成
  ↓
enhance-superpowers:enhance-executing-plans を invoke
  → gwt-test → write-review-response → finish-spec-pr（PR まで自動連鎖）
```

Spec の生成順は **enhance-superpowers の順序に合わせる**（`summary → [spec + gwt + pr-description] → plan`）。`spec` / `gwt` / `pr-description` は**まとめて生成し承認 1 回**（enhance-superpowers ADR-0011 と同型）。**issue 精緻化を plan の前に挟む**点だけが独自。

前回の 2 スキル分割（設計用・実装用）は採らない。実装以降を丸ごと委譲するため、indie-studio 側は Spec + issue 精緻化の 1 本で足りる。

### D2. 成果物は enhance-superpowers の入力契約に従う

委譲先が成果物を読むため、**形式は enhance-superpowers 側の仕様に合わせる**。これは**暗黙の契約**である。ただし**必須の強さは一様でない** — ハード要件は `*-plan.md` の存在（`enhance-executing-plans` Step 0 が無ければ error 中断）と `*-gwt.md` の checklist / 履歴セクション（`gwt-test` が判定に使う）の 2 つで、他は緩い。

| 項目 | 契約 |
|---|---|
| ファイル名 | `{YYYY-MM-DD}-{slug}-{suffix}.md`。suffix は `summary` / **`spec`** / `gwt` / `pr-description` / `plan` |
| 配置 | `--output-dir` で委譲先へ渡すディレクトリに 5 つ揃える |
| `plan.md` | `## レビュー履歴` セクション必須（`enhance-executing-plans` の状態判定が読む） |
| `gwt.md` | `- [ ] AC-N: ...` 形式の checklist、`## 変更履歴`（`{YYYY-MM-DD HH:MM}` 逆時系列）、`## レビュー履歴` 必須（`gwt-test` が読む） |
| `pr-description.md` | `## やったこと` / `## 動作確認方法` は必須。**`## 補足` は内容が無ければセクションごと削除**（`finish-spec-pr` 自身が「内容がなければセクションごと削除」と規定しているため、空で残すほうが契約違反） |

**suffix は `spec` を使う**（`design` にはしない）。成果物が生成されるのは**サービス repo 側**であり、そこには S1b `design-direction` が作る repo-root の **`DESIGN.md`（デザイン憲法）が常に存在する**（複数 repo で共通の運用）。同じ repo の実装フェーズに `design.md` を置くと読み違えを招くため、`design` の語は UI デザイン側に明け渡す。（本リポジトリ `claude-collections` は UI を持たないので `DESIGN.md` は無いが、衝突が起きるのは生成先の repo である。）

**委譲先はこれを妨げない**（検証済み）：`gwt-test` / `write-review-response` / `finish-spec-pr` は `design` に一切言及せず、`enhance-executing-plans` のハード要件も `*-plan.md` の存在のみ。同 skill の Step 0 は 5 成果物を glob 列挙するが、判定は `plan.md` のレビュー履歴だけで行い `design` の有無で分岐しない。

ただし `enhance-executing-plans` は executor へ渡す「参照 docs」を `design.md` と名指ししているため、**invocation 時に「詳細仕様は `*-spec.md`」と prompt で伝える**（引数ではなく context 提供なので D5 に反しない）。

### D3. 上流成果物を答え合わせ材料にする（会話で作り直さない）

Spec は**上流の確定物から起こす**。会話で要件を詰め直さない。

| 生成物 | 主な材料 |
|---|---|
| summary | issue 本文、`decomposition/index.md` のスライス定義、F-ID |
| spec | `tech/`（architecture / domain-model / perf-budget / security）、`screen-specs`、`DESIGN.md` |
| gwt | S4 `qa-engineer` が作った受入条件、`screen-specs` |
| pr-description | gwt の AC |
| plan | spec と F-ID |

### D3-a. issue が無い場合の分岐（契約）

issue が無いのは 2 通りあり、扱いを分ける。

| 状況 | 挙動 |
|---|---|
| `index.md` にスライス**あり** | **起票漏れ**。`index.md` が **G4 承認済みであることを確認**してから Linear へ起票し、正規フローに乗せる（起票は外部書き込みで、G4 承認が S4 の前提・ADR-0008）。承認済みか判定できなければ user に明示承認を取る |
| `index.md` にも**無し** | S4 を通さない単発作業（割り込みのバグ修正・小改修）。**ヒアリングで要件を聞き取り Spec のみ書く。issue は作らず issue 精緻化をスキップ**する。**骨格作成と issue 起票は行わない**（S4 の責務・D1） |

毎回 `decomposition` に差し戻さないのは、分解するほどでもない単発作業を正規フローに強制すると実運用に合わないため。ただし**骨格作成を本スキルが持つことはしない**（S4 と責務が二重になる）。

### D4. 実装以降は委譲。順序の制約が無いため触らない

`enhance-superpowers:enhance-executing-plans --output-dir=<dir>` を invoke する。以降 `gwt-test` → `write-review-response` → `finish-spec-pr` が自動連鎖して PR まで到達する。**indie-studio は実装・検証・レビュー・PR のロジックを持たない。**

`--gate-mode=aggregate` を渡すかは運用で決める（enhance-superpowers ADR-0014 E3。渡さなければ従来どおり per-phase）。

### D5. enhance-superpowers は変更しない

引数の追加も含め、**enhance-superpowers 側のファイルは編集しない**。既に入っている `--output-dir` / `--no-chain` / `--gate-mode`（ADR-0014）は利用するが、新たな引数は要求しない。

## Consequences

- **Spec フェーズのロジックが 2 箇所に存在する**（enhance-superpowers の `enhance-brainstorming` と indie-studio の S5 skill）。これは D5 の制約を受け入れた結果の意図的な重複であり、**enhance-superpowers 側の改善は自動では伝播しない**。
- D2 の入力契約は暗黙のため、**enhance-superpowers 側が形式を変えると indie-studio が壊れる**。S5 skill にこの依存を明記する。
- 実装以降（実装・AC 検証・CodeRabbit・review-response・PR）は enhance-superpowers に一本化されるため、そこは重複しない。
- issue 精緻化が plan の前に入り、issue には spec と gwt の情報が反映される（plan の情報は入らない）。
- ADR-0015 の S5 記述（ディレクターが束ね親単位で職種を並列起動 → 評価 3 観点 → PR）は D1 / D4 で置き換わる。ロスター（ADR-0014 の S5 = 8 体）は委譲先の dispatch matrix に吸収される。
- `enhance-superpowers` と `shared` の install が前提になる。

## Alternatives Considered

- **indie-studio に薄いアダプタ 2 本を置き `enhance-brainstorming` を chain invoke する**（当初案）：上流成果物を捨てて会話で要件を作り直し、issue を扱えず、plan の前に issue 精緻化を挟めない。却下（本 ADR が置き換える）。
- **enhance-superpowers に「Phase 3 で止める」opt-in 引数を足す**：既定挙動は変わらないが、業務稼働中のコレクションに変更を入れることになる。D5 の制約により却下。
- **issue 精緻化を plan の後に回す**：enhance-superpowers を触らずに済み二重実装も不要だが、要求された順序を満たさない。却下。
- **実装以降も indie-studio で実装し直す**：enhance-superpowers の 5 skill 全部（agent 能動 dispatch / 機微情報 / ライセンス / 状態判定 / CodeRabbit 連携）を複製することになり、保守が二重化する。実装以降には順序の制約が無いため不要。却下。

## 関連

- ADR-0013（共通ステージ形）／ADR-0014（ロスター）／ADR-0015（S5 スキル設計）：S5 部分を本 ADR が更新
- ADR-0016（出力レイアウト）／ADR-0028（docs 名前空間）：S5 の成果物置き場を追加する
- ADR-0007（五大枠ゲート）：issue 精緻化は自律操作
- ADR-0008（適応 PR ゲート）：G5 の merge 判断は委譲先の PR に対して適用する
- root ADR-0009（shared plugin 化）：plugin 間参照の前提
- enhance-superpowers ADR-0011（plan-last / Phase 3 まとめ生成）：D1 の生成順と D2 の形式契約の出所。**本 ADR は enhance-superpowers を変更しない**

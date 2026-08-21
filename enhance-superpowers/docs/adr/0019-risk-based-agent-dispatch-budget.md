# 0019. リスクベースの agent dispatch budget を導入し、chore/docs/カタログ整理の無条件 fan-out を止める

## Status

Accepted (2026-08-21)。ADR-0007 / ADR-0012 / ADR-0013 / ADR-0016 の dispatch 条件を **narrow する**（決定そのものは変えず、「常時」「必ず」という無条件語を「tier 条件付き」に絞る）。各 ADR には本 ADR を指す navigation 注記のみを追加し、本文の書き換えはしない。

## Context

軽量な Widgetbook story 削除（ロジック変更なし、カタログエントリの整理のみ）が `enhance-brainstorming` → `enhance-executing-plans` のフル実装フローに乗った際、以下が **無条件に** 起動し 5 並列レビューになった:

- Phase 3 (spec): `shared:software-architect` + `shared:security-engineer` + `shared:principal-engineer`
- Phase 4 (plan): `shared:qa-engineer` + `shared:security-engineer` + `shared:tech-lead` + `shared:engineering-manager` + `shared:principal-engineer`

CONTEXT.md の「agent dispatch matrix」表が示すとおり、これは設計ミスではなく **意図した挙動**だった。ADR-0001 / ADR-0005 の「各 skill ステップで agent を必ず使う (silent failure 回避)」という原則を字義通り実装した結果、**変更の大きさ・リスクに関わらず同じ密度でレビューする**設計になっていた。

silent failure 回避という目的自体は正しい。しかし「レビューを忘れる」と「レビュー密度を変更規模に合わせる」は別の軸で、後者を欠いたまま前者だけを追求すると、trivial な変更が重い変更と同じコストを払う。一方で `enhance-executing-plans` Step 4 の `security-engineer` / `performance-engineer` は既に「slice に auth/crypto/データ取扱/外部入力等の変更があれば」という条件付き dispatch になっており（2026-07-04 導入）、`write-review-response` Step 2 も判定迷い/セキュリティ系/大規模 refactor の 3 条件でのみ agent を dispatch する。**この 2 箇所は本 ADR が目指す形の既存の先例**であり、本 ADR は同じ考え方を他の無条件 dispatch 箇所へ広げる。

### なぜ「質問して分岐」ではなく「表で自律分岐」か

silent failure 回避の元々の動機は「AI が判断に迷って何もしない/確認せず進める」ことを防ぐことだった。分類のたびに user に 1 問確認する設計は、無条件 dispatch と同じ量の停止点を「dispatch するかどうか」の手前に移すだけで、fan-out 問題を解いていない。決定表に基づき **skill 自身が分類し、根拠 1 行をログに残して自律的に進む**（indie-studio の decide-record-proceed と同型の考え方）ことで、停止点を増やさずに budget を絞る。

### なぜ frontmatter 伝播に依存しないか

`enhance-brainstorming` は Phase 1 (トピック合意) の時点でまだ summary.md が存在しないため、最初の分類は「トピックの記述」からしか行えない。一方 `enhance-executing-plans` / `gwt-test` は indie-studio の S5 (indie-studio ADR-0032) から直接 invoke されることがあり、その場合 `enhance-brainstorming` を経由しないため、`enhance-brainstorming` が書く frontmatter に依存すると分類が欠落する。したがって **各 skill step は、その時点で読める成果物 (トピック文 / summary.md / spec.md / plan.md / 実際の diff) から都度自己判定する**。summary.md の frontmatter に記録するのは監査性のための副産物であり、単一の伝播経路として設計しない（無ければ標準 tier にフォールバックする、後述）。

## Decision

### D1: リスク tier を 4 段階で定義する

| Tier | 名前 | 判定基準（いずれか 1 つ該当で分類、複数該当時は最上位を採用） |
|---|---|---|
| **0** | chore/docs/catalog | 変更が次のいずれかに**限られる**: ドキュメント・コメントのみ / 未使用ファイル・story・fixture・生成物・カタログエントリの削除や整理 / フォーマッタ適用のみ / 依存の機械的な bump（挙動変更なし）/ typo・文言修正。**ロジック変更・公開 API 変更・新規依存追加を含まない** |
| **1** | local | 単一モジュール / 単一 slice に閉じる。モジュール境界・レイヤ境界・API 契約を跨がない。security trigger（D2）に該当しない |
| **2** | standard | 複数モジュール / 複数 slice に跨るが、境界の再設計・データ移行・後方互換破壊を伴わない。新規 user-facing 機能や API 追加を含みうる。security trigger（D2）に該当しない |
| **3** | high-impact | 次のいずれかに該当: security trigger（D2）該当 / モジュール境界の再設計 / データ・システム移行（不可逆マイグレーション含む）/ 複数 slice を束ねる大規模な依存順再設計 / 後方互換を破壊する変更・公開 API の破壊的変更 |

### D2: security trigger と architecture/EM/principal trigger を内容ベースで定義する

**security trigger**（該当したら tier に関わらず `shared:security-engineer` を dispatch し、tier は最低でも 3 として扱う）:

- 認証・認可 (auth/authz) の変更
- secrets・認証情報の取り扱い変更
- 外部システムとの新規・変更入出力（外部 API 連携・webhook 等）
- 決済処理
- 破壊的操作（データ削除・不可逆マイグレーション・force 系操作）

**architecture/EM/principal trigger**（tier 3 かつ次のいずれかで `shared:software-architect`（設計評価用途）/ `shared:engineering-manager` / `shared:principal-engineer` を dispatch）:

- モジュール境界の再設計
- データ・システム移行
- 複数 slice を束ねる分解・依存順の再設計
- 高影響（後方互換破壊・公開 API の破壊的変更・全社影響等）

この 2 つの trigger は tier 判定の**入力**であって tier とは独立の追加条件ではない — D1 の tier 3 の定義に内包される。表を分けているのは「何を見て判定するか」を skill 側が具体的に確認できるようにするため。

### D3: skill step ごとの max agent budget 決定表

対象は既存の「無条件」dispatch だった箇所のみ。既に条件付き dispatch だった箇所（`enhance-executing-plans` Step 4 の security/performance-engineer、`gwt-test` Step 5 の AC 未達時 qa-engineer、`write-review-response` の全箇所、`finish-spec-pr` の `/review`）は変更しない。

| dispatch 箇所 | Tier 0 (chore) | Tier 1 (local) | Tier 2 (standard) | Tier 3 (high-impact) |
|---|---|---|---|---|
| enhance-brainstorming Phase 1（アプローチ提示） | skip | skip | `software-architect` のみ | `software-architect` + `reviewer`（現行維持） |
| enhance-brainstorming Phase 2（summary） | skip | skip | `software-architect` のみ | `software-architect` + `reviewer`（現行維持） |
| enhance-brainstorming Phase 3（spec） | skip（機微情報チェックリストのみ常時） | skip（機微情報チェックリストのみ常時） | `software-architect` + `security-engineer`（trigger 時） | `software-architect` + `security-engineer` + `principal-engineer`（現行維持） |
| enhance-brainstorming Phase 3（gwt） | skip | `qa-engineer` | `qa-engineer`（現行維持） | `qa-engineer`（現行維持） |
| enhance-brainstorming Phase 4（plan） | skip（ライセンスチェックのみ常時） | `qa-engineer` のみ（ライセンスチェック常時） | `qa-engineer` + `security-engineer`（trigger 時） | `qa-engineer` + `security-engineer` + `tech-lead` + `engineering-manager` + `principal-engineer`（現行維持） |
| enhance-executing-plans Step 2（pre-flight architect） | skip | skip | dispatch | dispatch（現行維持） |
| enhance-executing-plans Step 4（slice review、implementation-reviewer） | 診断的 1 回（D4） | 常時（現行維持） | 常時（現行維持） | 常時（現行維持） |
| enhance-executing-plans Step 4（security/performance-engineer） | 既存の条件付きロジック不変（変更なし） | 不変 | 不変 | 不変（trigger 該当が前提のため実質常時） |
| gwt-test Step 6（AC 完了時 qa-engineer） | skip | dispatch（現行維持） | dispatch（現行維持） | dispatch（現行維持） |
| gwt-test Step 8（STOP POINT 2、implementation-reviewer） | 診断的 1 回（D4） | 常時（現行維持） | 常時（現行維持） | 常時（現行維持） |
| gwt-test Step 8（security-engineer / `/security-review`） | trigger 時のみ | trigger 時のみ | trigger 時のみ | 常時（現行維持） |

機微情報チェックリスト（ADR-0008）とライセンスチェック（ADR-0009）は tier に関わらず常時実施する。これらは agent dispatch ではなくコンプライアンス trigger であり、ADR-0014 E3 が gate 集約の対象から外した理由（見過ごすと規制違反のリスクを引き受ける）がそのまま当てはまる。

### D4: chore/local tier の implementation-reviewer は「診断的 1 回」に軽量化する

`shared:implementation-reviewer` は課金を伴わない（ADR-0016）ため、budget 0 の chore tier でも完全に 0 にはしない — ユーザーの要求どおり「原則 0（必要なら最終 review 1）」を実装する。具体的には:

1. 対象 diff のファイル一覧を確認し、宣言された chore/docs/catalog スコープ（Phase 1 で分類した理由）を超えるファイル（ロジックファイル・設定ファイルで挙動に影響しうるもの）が含まれるかを機械的に確認する
2. 超えていなければ、`implementation-reviewer` を**軽量 1 round**で dispatch する（fresh dispatch、continuation ラウンドは想定しない。findings があれば通常の差し戻しに従う）
3. 超えていれば、**tier を standard (2) に自己エスカレーション**し、D3 の tier 2 相当の budget で通常の review を行う（scope creep の検出、decide-record-proceed で理由をログに残す）

### D5: tier は自己判定し、判定できない/情報不足の場合は standard (2) にフォールバックする

各 skill step は、その時点でアクセス可能な成果物（トピック文 / summary.md / spec.md / plan.md / 実際の git diff）から D1 の基準で tier を判定する。summary.md の frontmatter に `risk-tier:` があればそれを起点にし、後続 Phase で判定材料が増えて D1 の基準に照らし高い tier が妥当と分かった場合は **上方エスカレーションのみ許可**する（一度 high-impact と判定されたものを後から chore に格下げしない）。

- `enhance-brainstorming` は Phase 2 (summary.md 生成) で `risk-tier:` を frontmatter に書き込む（D6）
- `enhance-brainstorming` を経由しない呼び出し（indie-studio S5 からの直接 invoke 等、indie-studio ADR-0032）では frontmatter が無いため、`enhance-executing-plans` / `gwt-test` は plan.md / spec.md / 実際の diff から自己判定する
- 判定に必要な材料が無い、または D1 のどの基準にも明確に一致しない場合は **standard (2) にフォールバック**する（chore へのフォールバックは無条件レビューを消す方向に倒れて安全側でないため避ける。high-impact への一律フォールバックは本 ADR の目的自体を無効化するため避ける）
- 判定根拠は dispatch log の該当行に 1 行で残す（D7）

### D6: risk-tier を summary.md frontmatter に記録する

`enhance-superpowers/templates/summary.md` の frontmatter に `risk-tier: {chore|local|standard|high-impact}` を追加する。Phase 2 で `enhance-brainstorming` が判定した tier を書き込み、後続 skill が読む際の起点にする（D5 のとおり唯一の伝播経路ではなく、欠落時は自己判定にフォールバックする）。

### D7: dispatch log の形式に tier と根拠を追加する

ADR-0007 が定める形式を拡張する:

```markdown
## レビュー履歴

- {YYYY-MM-DD HH:MM} - risk-tier={tier}（根拠: {1行}）→ dispatch: {実施した agent 一覧 or "skip（tier 条件不成立）"}
- {YYYY-MM-DD HH:MM} - `{agent-name}` を {Phase N / skill 名} で dispatch (目的: {目的}) → 「{回答要約}」
```

tier 行は各 skill step で dispatch 判定を行うたびに 1 行追記する（dispatch する/しないに関わらず）。エスカレーションが発生した場合は「risk-tier escalated {from}→{to}（理由: {1行}）」の形式にする。

### D8: 既存 lint/test/build/CI を agent dispatch より優先する

実装本体 (executor agent、`shared:{backend,frontend,mobile,infrastructure}-engineer`) は、担当 slice の実装完了時に **リポジトリ既存の lint/test/build コマンド**（`package.json` scripts、`Makefile`、CI 設定等から検出）を実行し、機械的に検出できる問題を先に解消してから review dispatch に進む。これは executor agent の入力契約（`shared:implementation-reviewer` が `Bash` を持ちテスト/型/lint の再実行を担う、ADR-0016 D1）の延長であり、**agent レビューは機械的チェックで拾えない観点（設計整合・可読性・網羅性）に絞る**という優先順位を明示する。tier に関わらず適用する（tier で変わるのは agent dispatch の量であって、機械的検証を省略してよい tier は無い）。

## Consequences

- **chore/docs/catalog tier の変更は budget 0（診断的 review 1 回まで）になる。** Widgetbook story 削除のような変更は、機械的に lint/test/build が通れば agent dispatch なしで完了できる
- **security/architecture/EM/principal の dispatch は内容ベースの trigger に紐づく。** 「常時」「必ず」という無条件語は残る箇所（implementation-reviewer の local 以上、tier 3 の各種 dispatch）に限定される
- **重い設計変更・security 変更の品質ゲートは維持される。** tier 3 の budget は現行と同一（無制限）で、本 ADR は narrow する方向にのみ働く
- **停止点は増えない。** tier 判定は skill 自身が行い、user への追加質問は発生しない（決定表による自律分岐）
- **indie-studio は無変更で恩恵を受ける。** indie-studio ADR-0032 の delegation は `enhance-executing-plans` / `gwt-test` を skill 名・引数契約のまま invoke するだけであり、本 ADR は dispatch 判定ロジックの内部だけを変える。frontmatter が無い場合の自己判定 + standard フォールバック（D5）により、indie-studio 側のアダプタ改修は不要
- **CONTEXT.md の「agent dispatch matrix」表を更新する。** 「常時」「必ず」の記述を tier 条件付きの記述に置き換え、本 ADR への参照を追加する
- **監査ログの行数が増える。** 各 dispatch 判定のたびに tier 行が追加されるため、レビュー履歴セクションはやや長くなる。tier 判定自体が監査対象（なぜこの密度で review したか）になるため、これは意図した増加

## Alternatives Considered

- **tier 判定のたびに user へ 1 問確認する** — silent failure ではなくなるが、無条件 dispatch と同じ数の停止点を「dispatch 前」に移すだけで fan-out (時間・ノイズ) は解決しない。ユーザーの要求「質問待ちにせず表で自律分岐」に反する。却下
- **budget を diff の行数・ファイル数だけで機械的に決める（内容を見ない）** — 「1 行だが auth ロジックの分岐条件を変える」ような high-impact な小変更を見逃す。security/architecture trigger は行数と独立した内容ベースの判定が要る。却下（行数・ファイル数は tier 判定の補助シグナルとしては使うが、単独の基準にはしない）
- **`--risk-tier` 引数を ADR-0014 の 3 引数に追加し、呼び出し元に明示指定させる** — indie-studio 等の外部呼び出し元がこの引数を渡す改修を要求することになり、ADR-0032 が避けた「呼び出し元への要求を増やす」方向に逆行する。自己判定 + フォールバック（D5）なら呼び出し元の改修なしに機能する。却下（将来 diff からの自己判定精度が不足すると分かった場合の拡張余地として引数追加は残すが、本 ADR の時点では導入しない）
- **implementation-reviewer も chore tier で完全に 0 にする** — ユーザーの要求は「原則 0（必要なら最終 review 1）」であり、完全 0 は scope creep（chore と称した変更が実はロジック変更を含む）を検出する手段を失う。D4 の診断的 1 回で「原則 0」と「必要なら 1」を両立させた

## 関連

- ADR-0001（collection-scope-and-naming）: silent failure 回避のコンセプト。本 ADR はこのコンセプトを維持しつつ密度を変更規模に合わせる
- ADR-0005（agent-vendoring）: dispatch 対象 agent の一覧
- [ADR-0007](0007-audit-trail-dispatch-log.md)（audit-trail-dispatch-log）: dispatch log の追記先とフォーマット。本 ADR の D7 が拡張する
- [ADR-0008](0008-sensitive-data-check-in-spec-phase.md)（sensitive-data-check-in-spec-phase）: 機微情報チェックリストは tier 不問で常時実施（D3）
- [ADR-0009](0009-license-check-in-plan-phase.md)（license-check-in-plan-phase）: ライセンスチェックは tier 不問で常時実施（D3）
- [ADR-0012](0012-implementation-phase-skill-and-state-detection.md)（implementation-phase-skill-and-state-detection）: 実装フェーズの Phase / Step 構造。本 ADR は Step の実行有無ではなく dispatch の有無を narrow する
- [ADR-0013](0013-gwt-test-qa-engineer-always-dispatch-and-code-review-auto-invoke.md)（gwt-test-qa-engineer-always-dispatch-and-code-review-auto-invoke）: 「常時」dispatch の初出。本 ADR が tier 条件を追加する
- [ADR-0014](0014-output-dir-arg-chain-suppression-gate-aggregation.md)（output-dir-arg-chain-suppression-gate-aggregation）: gate 集約の対象外としたコンプライアンス trigger の扱い（機微情報 / ライセンス）と同じ考え方を D3 で踏襲
- [ADR-0016](0016-local-review-to-implementation-reviewer-and-builtin-review-after-pr.md)（local-review-to-implementation-reviewer-and-builtin-review-after-pr）: 「必ず」dispatch する security-engineer / implementation-reviewer の宛先を定めた ADR。本 ADR が tier + trigger 条件を追加する
- indie-studio [ADR-0032](../../../indie-studio/docs/adr/0032-s5-spec-in-harness-implementation-delegated.md)（s5-spec-in-harness-implementation-delegated）: delegation 先の内部変更であり、indie-studio 側のアダプタ改修を要求しない（D5）
- enhance-superpowers CONTEXT.md「agent dispatch matrix」: 本 ADR に合わせて更新

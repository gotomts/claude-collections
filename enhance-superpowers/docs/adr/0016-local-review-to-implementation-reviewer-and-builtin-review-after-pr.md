# 0016. ローカルのコードレビューを shared:implementation-reviewer に一本化し、PR 作成後に builtin /review を置く

## Status

Accepted (2026-08-06)。[ADR-0013](0013-gwt-test-qa-engineer-always-dispatch-and-code-review-auto-invoke.md) を **extends** する。

ADR-0013 の Decision（D1 = gwt-test の qa-engineer 常時 dispatch / D2 = STOP POINT 2 で機械的レビューを auto-invoke して user 手動依存を廃止する）は**そのまま有効**で、本 ADR は D2 の**宛先**だけを変える。

ただし ADR-0013 の Status 行にある `Updated (2026-07-04)` の運用 —「コードレビュー activity 全体で `code-review` skill を default とし、`code-reviewer`（現 `implementation-reviewer`）は判定 aid 専用に予約する」— は、本 ADR が**置き換える**。ローカルでは `shared:implementation-reviewer` がコードレビュー活動の本体に戻る。

## Context

### 実測 1：bundled `/code-review` はモデルから起動できない

Claude Code の公式 docs（skills.md）は「Before v2.1.215, Claude could also run `/verify` and `/code-review` on its own.」と記す。v2.1.215 以降、`/code-review` は **user が明示的に打ったときだけ**動く。Skill tool 経由で呼べる built-in command として列挙されているのは `/init` / `/review` / `/security-review` の 3 つで、`/code-review` は含まれない。

加えて skills.md は「A skill at any of these levels also overrides a bundled skill with the same name.」と定める。personal skill として `~/.claude/skills/code-review/`（CodeRabbit CLI ラッパ、`name: code-review`）を置いている環境では、bundled `/code-review` は**完全にシャドウされて到達不能**になる。

### 実測 2：`/review` は PR 専用だが、Skill tool から起動できる

`/review [PR#]` は GitHub PR の read-only レビュー。PR 番号 / URL が必須で、ローカル diff には使えない。出力はターミナルに出るだけで PR へのコメント post は行わない。Skill tool 経由で起動できるため、skill の内部から auto-invoke できる。

### 実測 3：現行 3 サイトの呼び出しは動いていない

`enhance-executing-plans` Step 4 / `gwt-test` Step 8 / `write-review-response` Step 4 の 3 箇所は `code-review:code-review` skill を invoke している。これは Anthropic 公式 `code-review` plugin のコマンドで、**GitHub PR を対象とし PR にコメントを post する**。一方 SKILL.md の文言は 3 箇所とも「(CodeRabbit)」のままで、指しているつもりのもの（personal skill `code-review` = CodeRabbit CLI、ローカル diff 対象）とは別物である。

混入経路は PR #31（`9a72134`、2026-07-28、shared の plugin 化）の「dispatch は修飾名で行う」スイープ。`shared:<agent>` を修飾する作業のなかで、**plugin skill ではなく personal skill である `code-review` まで修飾**してしまい、宛先が公式 plugin に移った。

結果として 3 箇所とも成立しない。PR を作るのは chain 最後の `finish-spec-pr` なので、3 サイトはいずれも **PR がまだ存在しない時点**で走る（`write-review-response` Step 4 は文言自体が「再 push 前」）。仮に PR が存在する状況で動けば、SKILL.md が宣言していない外向き操作（PR への公開コメント）が発生する。

### 問題の構造

フェーズと道具が噛み合っていない。ローカル diff を見る道具と PR を見る道具は別物で、1 つに寄せられない。「レビュー経路を built-in の 1 つに置き換える」という発想自体が、この制約に反していた。

## Decision

### D1: ローカル 3 サイトの code-review 呼び出しを廃止し、`shared:implementation-reviewer` をローカルのコードレビュー担当に戻す

対象は `enhance-executing-plans` Step 4 / `gwt-test` Step 8 / `write-review-response` Step 4。

- **無修飾 `code-review`（CodeRabbit CLI）に戻すのではなく、呼び出しごと外す。** ローカルで CodeRabbit は使わない。CodeRabbit を使うのは GitHub 上の PR レビュー（GitHub App）だけとする
- 3 サイトのコードレビュー活動は `shared:implementation-reviewer` の能動 dispatch が担う。この agent は `Bash` を持ち、テスト / 型 / lint の再実行と、grep による前例確認を伴う読み取り検証ができる
- ADR-0013 `Updated (2026-07-04)` が置いた「判定 aid 専用に予約」を解除する。ただし判定 aid としての用途（`enhance-executing-plans` の blocker false positive 判定 / `write-review-response` Step 2 の採用判定補助）は**併存**する。同じ agent が、レビュー本体と判定補助の 2 用途を持つ
- `shared:security-engineer`（評価 mode）と `shared:performance-engineer` の起動条件は**変更しない**。implementation-reviewer はこれらを置き換えるのではなく、機械的レビューが抜けた穴を埋める
- 差し戻し protocol は agent 側に定義済み（round1 fresh で完全 findings マニフェスト → round2-3 continuation でスコープ凍結、最大 3 ラウンド、未達は decide-record-proceed）。呼び出し元 skill はこれを **use 宣言する**

### D2: PR 作成後に builtin `/review` を置く（`finish-spec-pr` に新 Step）

`finish-spec-pr` の Step 5（`shared:finish-stage-pr` 経由で PR 作成）の直後に、レビュー Step を新設する。

- Step 5 の出力である PR URL / 番号を引数に、`Skill` tool で `/review` を invoke する
- `/review` は read-only。**PR へのコメント post はしない**（`--comment` 相当の副作用を持たせない）
- **`/review` は cwd のリポジトリで PR 番号を解決する。** 別リポジトリの checkout から invoke すると同じ番号の別 PR を読む。`finish-spec-pr` は PR を作った worktree で走るため条件を満たすが、`gh repo view --json nameWithOwner` と PR URL の `owner/repo` を突き合わせて**明示的に検証**し、不一致なら skip する
- **CodeRabbit はこの Step では扱わない。** CodeRabbit の PR レビューは作成から数分〜十数分かかり、Step 5 の直後に走る Step 6 では**ほぼ常に未到着**である。「付いていれば読む」は事実上ほぼ常に偽になり、併読の設計が機能しない。CodeRabbit ラウンドは時間が経ってから `write-review-response` を直接 invoke して扱う（同 skill が 3 ラウンドを持つ形にする）
- 指摘があれば user に提示し **1 問確認**する。yes なら `write-review-response` に chain して採用 / Skip 判定へ回す。**自動 chain しない**
  - 自動 chain しない理由は 2 つ。(a) `write-review-response` → `finish-spec-pr` → `write-review-response` の循環になるため、人間ゲートをループ上限として置く。(b) PR 後の対応要否は D4 のとおり人間の判断領域である
- これに伴い `finish-spec-pr` の「agent dispatch しない（mechanical な操作のみ）」という規律は、「**agent は dispatch しないが `/review` は invoke する**」に改める

**`/review` の実行記録は `finish-spec-pr` 自身が `review-response.md` に書く**（ADR-0007 の mapping に 1 行足す形で extends する）。

| dispatch タイミング | 追記先 |
|---|---|
| finish-spec-pr Step 6（`/review`） | review-response.md（**file が無ければ「## レビュー履歴」のみを持つ file を新規作成**） |

- **指摘 0 件のときも、user が折り返さないと決めたときも、skip したときも省略しない。** ADR-0007 の目的は監査証跡であり、「回していない」と「回して 0 件だった」が区別できないことの方が問題になる。この 2 経路では `write-review-response` が起動しないため、そちらに集約させると記録が落ちる
- **`pr-description.md` には書かない。** ADR-0007 は pr-description を明示的に除外しており（`B 例外`、Alternatives Considered でも「pr-description にもレビュー履歴を追記」を却下している）、理由は GitHub PR description text としてそのまま投稿されるため肥大化すること。この例外は本 ADR でも維持する

### D3: bundled `/code-review` は採用しない

理由は 2 つあり、どちらか一方でも採用を否定する。

1. **モデルから起動できない**（実測 1）。採用すれば ADR-0013 D2 がわざわざ廃止した「user 手動 invoke 依存」に逆戻りし、D2 が解消した silent failure が復活する
2. **consumer 環境の skill 構成に依存する**。personal skill `code-review` を持つ環境ではシャドウされて到達不能になる。本リポジトリは plugin として配布される以上、consumer に特定の skill 名を空けておくことを要求するのは筋が悪い。root [ADR-0011](../../../docs/adr/0011-external-plugin-agent-name-collision.md) が「`feature-dev` plugin を無効化する」案を、回避が環境側の設定に依存するという**同型の理由**で却下している

### D4: `/review` は人間レビューの代替にしない

`/review` は AI による自己レビューである。indie-studio [ADR-0008](../../../indie-studio/docs/adr/0008-adaptive-pr-review-gate.md) は「PR 時点で実装エージェントが critical / 非 critical を自己認定する」案を**利益相反**として却下しており、`/review` を人間レビューの代替に据えることはこれと同型になる。

- `/review` は G5 の人間レビューを**補完するだけ**で、置き換えない
- 根幹チケット（セキュリティ・課金・PII・秘密情報・不可逆マイグレーション・公開 API・インフラ）の人間レビューと人間 merge は、`/review` の結果にかかわらず従来どおり必要
- この線引きにより indie-studio ADR-0008 は改訂を要さない

### D5: STOP POINT 2 に `/security-review` を追加し、`shared:security-engineer` は維持する

`gwt-test` Step 8 で `/security-review` を Skill tool から invoke する（未コミット変更のセキュリティ検査、Skill tool 経由で起動可能）。

`shared:security-engineer` の常時能動 dispatch は**廃止しない**。ADR-0013 D2 が security-engineer を「機械的レビューを補完する」目的で code-review の yes/no と**独立に**実行する設計にした経緯を維持する。機械的検査（`/security-review`）と設計文脈を持つ評価（security-engineer）は代替関係にない。

### D6: `--gate-mode` は `gwt-test` / `write-review-response` で無効になるが、引数の受理と伝播は維持する

[ADR-0014](0014-output-dir-arg-chain-suppression-gate-aggregation.md) が定義した `--gate-mode=aggregate` は、この 2 skill では「code-review の課金前 1 問確認を実行に固定する」ことが**唯一の効果**だった。D1 でその 1 問確認自体が消えるため、2 skill では効果を持たなくなる。

- **引数は従来どおり受理し、下流へ伝播する。** indie-studio ADR-0032 は「enhance-superpowers 側のファイルは編集しない」と定め、`implementation-spec` SKILL.md:166 が `--gate-mode` を渡す。引数を落とすとこのアダプタ契約が壊れる
- 2 skill の引数表には「本 skill では効果を持たない（受理と下流伝播のみ）」と明記する
- **削除条件**: 「受理するが何もしない引数」を恒久的に残さないため、削除してよい条件を先に定める。**indie-studio 側（`implementation-spec` SKILL.md）が `--gate-mode` を渡さなくなり、かつ本コレクションの他の呼び出し元も渡さなくなった時点で、2 skill の受理・伝播ごと削除してよい。** 確認は `grep -rn "gate-mode" .` で渡し手が `enhance-brainstorming` / `enhance-executing-plans`（効果が残る 2 skill）だけになっていること
- `enhance-executing-plans` の `--gate-mode` は Step 5 の chain 起動 1 問確認を自動 yes にする効果が残るため、**引き続き有効**。`enhance-brainstorming` の Phase 2/3/4 承認集約も無関係で不変
- 無効化した効果を「implementation-reviewer の差し戻し確認を自動 yes にする」等に**付け替えない**。それは本 ADR の射程外の挙動変更であり、必要になった時点で別 ADR で決める

## Consequences

- **ローカルの課金がゼロになる。** 3 サイトの「課金前 1 問確認」がすべて消える。停止点が 3 つ減り、`--gate-mode=aggregate` を渡す動機も 2 skill 分減る
- **`write-review-response` の入力契約が変わる。** 従来の「ローカル code-review 出力 or PR unresolved コメント」が、**3 ラウンド**（ローカル agent findings / PR 後の `/review` / PR 後の CodeRabbit）になる。skill の `description` と Phase 定義表の前提 file 記述を更新する。ID 体系（`M`/`Mi`/`T`）と 2 値判定（保留禁止）、上書き運用は不変
- **CodeRabbit の「指摘 0 件」と「レート制限」を区別する必要がある。** レート制限中の CodeRabbit は commit status が `state: success` / `description: "Review rate limited"` になり、**checks 上は成功に見える**。`description` まで見ないと弾かれたのか指摘が無いのか判別できない。`write-review-response` の PR 後ラウンドでこれを判定し、レート制限時は**自動で再 invoke せず** user に判断を返す（繰り返すと制限を悪化させるため）
- **CodeRabbit のチャネルが 1 本に減る。** CLI と GitHub App で異なる findings が返る二重チャネルが解消し、GitHub App のみになる
- **`shared/` は無変更。** 変更は `enhance-superpowers/` の 5 SKILL.md と本 ADR に閉じる。indie-studio は `implementation-spec` Step 5 で委譲するだけでコードレビューの起動点を 1 つも持たないため、**影響を受けない**
- **PR #31 の宛先ずれは修正不要になる。** 3 サイトとも呼び出しごと消えるため、`code-review:code-review` の参照が repo から無くなる
- **注記で足りる ADR が 2 つある**（決定の書き換えではなくナビゲーション注記のため immutable に反しない）:
  - ADR-0007 の dispatch log mapping 表 — 行ラベル `STOP POINT 2 (security-engineer + code-review skill auto-invoke、ADR-0013)` に本 ADR を指す inline 注記。追記先 file 自体は不変
  - ADR-0014 — `--gate-mode` が 2 skill で無効化されたことを指す inline 注記
- **`finish-spec-pr` が「mechanical のみ」でなくなる。** 完了報告の前にレビューと 1 問確認が挟まるため、chain の終端が 1 段伸びる

## Alternatives Considered

- **無修飾 `code-review`（CodeRabbit CLI）に戻して宛先ずれだけ直す** — 変更が最小で、ADR-0013 D2 の auto-invoke がそのまま成立する。却下したのは、ローカルでも PR でも CodeRabbit が走ると同じコードに二重で課金が乗り、かつ CLI と GitHub App で findings が食い違う二重チャネルが残るため。CodeRabbit を PR に一本化する判断を優先した
- **bundled `/code-review` を採用する** — D3 の 2 理由で却下
- **`shared:implementation-reviewer` を廃止して `/review` に一本化する** — `/review` は PR 専用でローカル diff を見られないため、実装中〜push 前が丸ごと無レビューになる。加えて root ADR-0011 が「`shared:code-reviewer` を廃止して `code-review` skill と `shared:reviewer` に一本化する」案を、`shared:reviewer` が `Bash` を持たず実装スライスの評価（テスト / 型 / lint の再実行を伴う）を引き受けられないという理由で既に却下している。却下
- **`/review` を `shared:finish-stage-pr` 側に置く** — PR 作成の直後という位置としては自然だが、`shared/skills/finish-stage-pr` の `allowed-tools` は `Bash, Read` のみで `Skill` tool を持たない。かつ `shared/` の変更は indie-studio を含む全 consumer に波及する。`finish-spec-pr`（enhance-superpowers 側、`Skill` を持つ）に置けば shared を無変更に保てる。却下
- **`/review` の結果を自動で `write-review-response` に chain する** — 停止点が減る利点はあるが、`write-review-response` → `finish-spec-pr` → `write-review-response` の循環にループ上限が無くなる。D2 のとおり 1 問確認を上限として置いた。却下

## 関連

- [ADR-0013](0013-gwt-test-qa-engineer-always-dispatch-and-code-review-auto-invoke.md) — 本 ADR が extends する。D1 / D2 は有効、Status 行の `Updated (2026-07-04)` 運用のみ置き換え
- [ADR-0007](0007-audit-trail-dispatch-log.md) — dispatch log の追記先。mapping 自体は不変、inline 注記のみ
- [ADR-0014](0014-output-dir-arg-chain-suppression-gate-aggregation.md) — `--gate-mode` の定義元。D6 で 2 skill での効果が消える
- [ADR-0012](0012-implementation-phase-skill-and-state-detection.md) — skill chain と Step 0 状態判定
- root [ADR-0011](../../../docs/adr/0011-external-plugin-agent-name-collision.md) — `implementation-reviewer` への改名と、環境依存の回避策を却下する判断
- indie-studio [ADR-0008](../../../indie-studio/docs/adr/0008-adaptive-pr-review-gate.md) — D4 の線引きにより改訂不要

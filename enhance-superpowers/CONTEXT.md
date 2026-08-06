# enhance-superpowers コレクション

superpowers (公式) を base に、ローカル開発フローの規律 (5 成果物 / Spec 先行 / GWT テスト運用 / code-review 採用Skip / 設計思想 / コメント方針) を skill+agent コレクション化したもの。中規模開発で Spec フェーズに認識齟齬検出を 3 重に分散する思想。

## Language

**5 成果物 (Five deliverables)**:
Spec フェーズで生成される 5 つの markdown ファイル — summary / spec / gwt / pr-description / plan。生成順は **plan-last** (`summary → spec → gwt → pr-description → plan`、ADR-0011)。suffix `spec` は ADR-0015 で `design` から改名した (実装仕様の意。UI デザイン側の `DESIGN.md` と読み違えないため)。spec / gwt / pr-description は Phase 3 で連続生成し、3 file 揃ってから user 承認 1 回 (認識齟齬検出 ② ③ 統合)。命名は `{YYYY-MM-DD}-{slug}-{suffix}.md`。配置は `docs/superpowers/{branch}/` (`--output-dir` 指定時はその値、ADR-0014 E1)。

**enhance-brainstorming**:
enhance-superpowers の起点 skill。`superpowers:brainstorming` の責任を拡張し、5 成果物の Spec フェーズ確定 + 後工程 sub-skill の連鎖駆動を担う。ユーザーが意識的に呼ぶ唯一の skill。

**STOP POINT**:
skill 連鎖の中で agent 能動 dispatch を強制する境目。本コレクションは 2 つ持つ:
- **STOP POINT 1 (実装フェーズ)**: ADR-0012 で `enhance-executing-plans` skill 化。実装前 software-architect + slice ごと executor 能動 dispatch + review (implementation-reviewer 常時 / security-engineer / performance-engineer) を強制 dispatch。ローカル diff のコードレビュー本体は `shared:implementation-reviewer` (ADR-0016 D1)。
- **STOP POINT 2 (セルフレビュー)**: ADR-0013 D2 で**停止せず能動 dispatch** し user 手動依存を廃止。宛先は `shared:implementation-reviewer` + `shared:security-engineer` + `/security-review` (ADR-0016 D1・D5)。いずれも課金を伴わないため課金前 1 問確認は廃止。write-review-response chain は独立 = 常時実行 (silent failure 回避)。**ローカルで CodeRabbit / `code-review` 系 skill は呼ばない**。

**skill 一覧** (6 skill、ADR-0012 で `enhance-executing-plans`、ADR-0017 で `pr-review` を追加):

implementer 側 (1〜5) — 自分が書くコードの Spec を決めて実装し、PR を出すまで:
1. `enhance-brainstorming` — 起点、Spec 5 成果物確定
2. `enhance-executing-plans` — 実装フェーズ (2026-07-04 redesign: skill 側から executor agent を直接 dispatch、superpowers 委譲は廃止 = silent failure の言い換えだった)
3. `gwt-test` — AC 検証 + qa-engineer 常時 dispatch (ADR-0013) + STOP POINT 2 実行 (implementation-reviewer 常時 + security-engineer + `/security-review`、ADR-0016 D1・D5)
4. `write-review-response` — CodeRabbit 指摘の採用/Skip 判定
5. `finish-spec-pr` — PR 作成 (mechanical)

レビュワー側 (6) — 他人の PR を受け取って理解し、検証し、レビューする:
6. `pr-review` — PR 番号を起点に summary (把握) + gwt (動作確認の土台) を生成 → crit で人間レビュー → 子セッション 2 本で動作確認 ∥ コードレビューを並走 → join (ADR-0017)

**レビュワー側**:
向きが implementer 側と逆になる作業領域 (ADR-0017)。implementer 側は設計を決めてから書くので理解が先にあるが、レビュワーは完成した差分から設計意図を逆算する。この向きの違いが最も出るのが gwt.md の出所で、implementer 側 (`gwt-test`) は Spec フェーズで先に書かれた gwt.md を読むのに対し、レビュワー側 (`pr-review`) は差分から gwt.md を起こす。したがって同じ skill には収まらない。`write-review-response` はレビューを**受ける**側なので implementer 側に属する (名前が似ているが向きが逆)。

**認識齟齬検出ポイント**:
Spec フェーズで設計の認識ズレを早期検出する 3 重の関所 — ① summary 合意 (大枠ズレ、Phase 2) / ② gwt 合意 (AC ズレ、Phase 3) / ③ pr-description 合意 (動作確認方法ズレ、Phase 3)。② と ③ は Phase 3 の 3 file 一括レビューに集約される (ADR-0011)。

**agent dispatch matrix** (2026-07-04 更新):
各 skill ステップで能動 dispatch する agent / skill と目的の一覧。`import するだけで使わない` silent failure pattern を回避するための明示的な対応表。engineering 系 13 agent は `shared` plugin が提供し、**dispatch は `shared:<agent>` の修飾名で行う** (bare name は解決されない・root ADR-0010。vendoring は廃止、ADR-0005 は supersede 済):

| skill / step | 能動 dispatch (agent / skill) | 目的 |
|---|---|---|
| enhance-brainstorming Phase 1 | shared:software-architect + shared:reviewer | アプローチの Clean Architecture / SOLID + 独立観点評価 (真実源整合 / 反証可能性) |
| enhance-brainstorming Phase 2 (summary) | shared:software-architect + shared:reviewer | SOLID / YAGNI + summary 反証可能性 |
| enhance-brainstorming Phase 3 (spec) | shared:software-architect + shared:security-engineer + shared:principal-engineer + 機微情報チェック | SOLID / モジュール境界 / セキュリティ / 独立技術設計評価 / 機微情報 (ADR-0008) |
| enhance-brainstorming Phase 3 (gwt) | shared:qa-engineer | AC 網羅性 |
| enhance-brainstorming Phase 4 (plan) | shared:qa-engineer + shared:security-engineer + shared:tech-lead + shared:engineering-manager + shared:principal-engineer + ライセンスチェック | テスト戦略 / セキュリティ / スタック判断 / slice 分解 / 分解評価 / ライセンス (ADR-0009) |
| enhance-executing-plans Step 2 (実装前) | shared:software-architect | 実装方針 pre-flight review (ADR-0012) |
| enhance-executing-plans Step 3 (実装本体) | shared:{backend,frontend,mobile,infrastructure}-engineer (slice 対応で選定) | executor 能動 dispatch (ADR-0012 D1 redesign) |
| enhance-executing-plans Step 4 (slice review) | **shared:implementation-reviewer (常時)** + shared:security-engineer + shared:performance-engineer | ローカル diff の code review activity は implementation-reviewer が担う (ADR-0016 D1) |
| gwt-test Step 5 (AC 未達時) | shared:qa-engineer | 差し戻し findings 言語化 |
| gwt-test Step 6 (AC 完了時) | shared:qa-engineer 常時 | AC 網羅性 review (ADR-0013 D1) |
| gwt-test Step 8 (STOP POINT 2) | **shared:implementation-reviewer (常時)** + shared:security-engineer 能動 + **`/security-review` invoke** | ローカル diff の code review + security-focused review 2 層 (ADR-0013 D2、宛先は ADR-0016 D1・D5)。課金なしのため 1 問確認は廃止 |
| write-review-response Step 2 (判定迷い / セキュリティ / 大規模 refactor) | shared:implementation-reviewer (判定 aid) / shared:security-engineer / shared:reviewer | 判定補助 |
| write-review-response Step 4 (再 push 前) | **shared:implementation-reviewer (常時)** | 採用分の解消検証と回帰チェック (ADR-0016 D1) |
| finish-spec-pr Step 6 (PR 作成後) | **builtin `/review` invoke** (CodeRabbit は扱わない) | PR レビュー。指摘があれば user 1 問確認のうえ write-review-response へ折り返す。**実行記録は 0 件・折り返し無し・skip でも review-response.md に残す** (ADR-0016 D2) |
| write-review-response 直接 invoke (PR 作成の数分〜十数分後) | GitHub 上の CodeRabbit unresolved | CodeRabbit ラウンド。PR 作成直後は未到着のため Step 6 から分離 (ADR-0016 D2) |
| pr-review Step 2 (summary) | shared:software-architect | 差分から読み取った設計意図の妥当性 / 見落とした構造変更 (ADR-0017) |
| pr-review Step 3 (gwt) | shared:qa-engineer | レビュワー視点 AC の網羅性 (異常系 / 境界値 / 既存機能への回帰) |
| pr-review Step 5 (子 `pr{N}-review` 内) | shared:implementation-reviewer + shared:security-engineer | 子セッションが dispatch。ローカル diff のコードレビュー本体 + セキュリティ観点 (ADR-0016 D1 の宛先に揃える) |

**レビューの宛先はフェーズで分かれる** (ADR-0016)。ローカル diff と GitHub PR は別の道具でしか見られないため、1 つに寄せない:

- **実装中〜push 前 (ローカル diff)**: `shared:implementation-reviewer` がコードレビュー本体。`shared:security-engineer` / `shared:performance-engineer` / `/security-review` が観点を足す。**ローカルで CodeRabbit / `code-review` 系 skill は呼ばない**
- **PR 作成後**: builtin `/review` (PR 専用・Skill tool から invoke 可・read-only)。**cwd のリポジトリで PR 番号を解決する**ので、対象 PR と同じ checkout で走る必要がある
- **PR 作成の数分〜十数分後**: GitHub 上の CodeRabbit。PR 作成直後は未到着なので `/review` と同じ Step では扱わない。「指摘 0 件」と「レート制限 (`state: success` / `description: "Review rate limited"`)」を必ず区別する
- `shared:implementation-reviewer` は**レビュー本体と判定 aid の 2 用途**を持つ。ADR-0013 が置いた「判定 aid 専用に予約」は ADR-0016 D1 が解除した
- bundled `/code-review` は採らない — モデルから起動できず (v2.1.215 以降)、かつ同名 personal skill にシャドウされて consumer 環境依存になるため (ADR-0016 D3)
- `/review` は AI の自己レビューであり、**根幹変更の人間レビュー / 人間 merge を代替しない** (ADR-0016 D4、indie-studio ADR-0008)

dispatch log の追記先 mapping は ADR-0007 参照。

**レビュー履歴セクション**:
5 成果物の末尾に追加される `## レビュー履歴` セクション。agent dispatch log (時刻 / agent / 目的 / 回答要約) をここに集約 (B = 監査ログ)。形式は ADR-0007 で定める。

**Y 方式**:
enhance-brainstorming Phase 3 で合意済み summary を context として `superpowers:brainstorming` に委譲し実装仕様 (`*-spec.md`) を生成させる実装方式。fallback (Z 方式 = 自前実装) は ADR-0006 に明記。**enhance-executing-plans は 2026-07-04 D1 redesign で委譲を廃止**、Y 方式は brainstorming (Phase 3) のみ継続。executing-plans は skill 側から executor 直接 dispatch (silent failure 回避)。

**状態判定 (Step 0)**:
全 skill 冒頭に配置される Step 0。出力先 (`--output-dir` 指定時はその値、省略時は `docs/superpowers/{branch}/`) の既存 file 有無から現在 Phase を判定し、適切な Step から再開する仕組み (ADR-0012 D2)。SKILL.md 冒頭の Phase 定義 table (ADR-0012 D3) を再開判定の仕様源とする。ハンドオフ再開 / 別セッション再 invoke 時のドキュメント生成順序破壊を構造的に防止。

## indie-studio との禁止語彙

indie-studio コレクションが使う以下の語彙は、enhance-superpowers では **使わない** (思想が異なるため、同じ語彙で混乱を生まない):

- `S1〜S5` (ステージ番号)
- ゲート / 大枠ゲート (G1〜G5)
- 繰り越し決定 (Deferred decision)
- アンカー (Anchor)
- 自走設計 / 補助設計
- self-grill / 導出エージェント / 評価エージェント
- Claude Design / ハンドオフバンドル / プロトタイプブリーフ
- ハーネス / オーケストレーター / ディレクター

enhance-superpowers は superpowers (公式) の直線フロー (brainstorming → writing-plans → executing-plans) を尊重しつつ、その上に「Spec フェーズの 5 成果物確定」「後工程連鎖」「agent 能動 dispatch」を被せる設計。

**外部 collection からの利用について (2026-07-28)**: indie-studio が S5 (実装ステージ) を本コレクションへ委譲する (indie-studio ADR-0032)。委譲は **indie-studio 側の薄いアダプタ skill が本コレクションの skill を chain invoke する**形で行い、ADR-0014 の 3 引数 (`--output-dir` / `--no-chain` / `--gate-mode`) で出力先と gate 回数を制御する。**依存の向きは indie-studio → enhance-superpowers の一方向**であり、上記の禁止語彙が本コレクションへ流入することはない。indie-studio 固有 context (参照 docs のパス / architecture 規約 / 差し戻し protocol 等) は、呼び出し元アダプタが invocation prompt で明示的に渡す。

## 設計思想

- **Clean Architecture + Modular Monolith** を採用 (既存プロジェクトに別規約があればそちら優先)
- **YAGNI / DRY / KISS / SOLID** を遵守、衝突時は **SOLID 最優先**
- **DRY はテストコードで一部許容** (Given/When は重複可、assertion helper / factory / fixture builder は共通化可)
- **コードコメントは WHY のみ**、JSDoc 抑制
- **agent 能動 dispatch**: 各 skill ステップで agent を必ず使う場面を織り込む (silent failure 回避)
- **コミット前提**: 設計ドキュメントは worktree 同居・main 退避なし。**ただし implementer 側の成果物に限る** — `pr-review` が他人の PR に対して書くレビューメモは commit しない (ADR-0017 D4)

## 配置

| ファイル | 配置先 |
|---|---|
| 5 成果物 (summary / spec / gwt / pr-description / plan) | `docs/superpowers/{branch}/` (**`--output-dir` 指定時はその値**、ADR-0014 E1) |
| review-response.md | 同上 |
| handoff.md (任意、状態判定の補助) | 同上 |
| pr-review 成果物 (summary / gwt / review-report) | **発動元リポジトリ**の `docs/superpowers/pr-{N}/` (**`--output-dir` 指定時はその値**)。レビュー用 worktree には置かず、**commit しない** (ADR-0017 D4) |
| コレクション固有 ADR | `enhance-superpowers/docs/adr/` |
| skill / template | `enhance-superpowers/{skills,templates}/` (固有 agent は 0 体、engineering 系は `shared` plugin) |

**SKILL.md から template を参照するときは `${CLAUDE_PLUGIN_ROOT}/templates/<name>.md` と書く。** repo 相対の `enhance-superpowers/templates/...` は cwd 基準で解決されるため、skill が実際に走るサービス repo では解決できない。上の table にある `enhance-superpowers/templates/` は**本リポジトリ内での物理配置**であって、実行時の解決先ではない。

## 関連

- 設計 doc: `docs/superpowers/feat-enterprise-superpowers-customization/2026-06-25-enhance-superpowers-collection-design.md`
- summary: 同 dir の `-summary.md`
- plan: 同 dir の `-plan.md`
- ADR 0001-0017 (コレクション固有): `enhance-superpowers/docs/adr/`
- root ADR: `docs/adr/` (リポジトリ全体の決定)

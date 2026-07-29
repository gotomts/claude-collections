# 0011. agent 名の重複禁止を外部 plugin まで拡張し、shared:code-reviewer を implementation-reviewer に改名する

## Status

Accepted (2026-07-29)。ADR-0010 (shared-as-plugin-agent-namespace) を **extends** する。ADR-0010 の決定（shared の plugin 化・vendoring 廃止・`plugin:agent` 修飾必須）はそのまま有効で、本 ADR はその「agent 名を重複させない」制約の**適用範囲**だけを広げる。

## Context

ADR-0010 は agent 名の重複禁止を「**コレクション間で** agent 名を重複させないこと」と書いた。この書き方は、衝突が本リポジトリの marketplace 内で閉じるかのように読める。実際には閉じない。

`shared/agents/code-reviewer.md` の `name: code-reviewer` は、Anthropic 公式 marketplace の **`feature-dev` plugin が持つ `code-reviewer`** と同名である。両者は別 marketplace の別 plugin だが、ユーザーの環境では同時に install されうるし、実際にされていた。

**ただし、この衝突はまだ発火していなかった。** 2026-07-29 に「`shared:*` の 13 agent がセッションに登録されない」という事象を調査した結果、原因は衝突ではなく `shared@claude-collections` が `enabledPlugins` に登録されていなかったこと（install ≠ enable）だった。衝突が表面化していなかったのは、負けた側が消える以前に shared 自体がロードされていなかったためにすぎない。enable すれば ADR-0010 が記録した失敗モード（同名 agent を持つ 2 plugin が共存すると、負けた側の agent セットが registry から丸ごと落ち、衝突していない agent まで巻き添えになる）に そのまま乗る。

つまり本 ADR が扱うのは、**実測済みの故障ではなく、ADR-0010 で実測済みのメカニズムに対する既知の未発火リスク**である。この区別を残しておかないと、後から「衝突で shared が消えた」という誤った因果が読み取られる。

## Decision

**agent 名の重複禁止を「同時に install されうる全 plugin」に対する制約として読む。あわせて `shared:code-reviewer` を `shared:implementation-reviewer` に改名する。**

- 重複禁止の対象は、本リポジトリのコレクション間だけでなく、**外部 marketplace の plugin を含む**。shared/ の agent は collection 非依存の中立語彙で書く（ADR-0004 から継承）が、中立であることと**ありふれた名前であること**は別で、後者は衝突の原因になる。
- `shared/agents/code-reviewer.md` を `shared/agents/implementation-reviewer.md` に改名し、frontmatter の `name` と本文の職種名（コードレビュアー → 実装レビュアー）を合わせる。役割定義（実装スライスを受入条件充足・テスト網羅・設計 docs 整合・可読性・規約で評価し、findings を返す）は変更しない。
- 新名は既存の `shared:reviewer`（要件・設計 doc の評価担当・`Bash` なし）との対比を名前で表す。`reviewer` = doc 評価、`implementation-reviewer` = 実装評価。
- 活きた参照（`CONTEXT-MAP.md`・`enhance-superpowers/CONTEXT.md`・SKILL.md・テンプレート）は新名に書き換える。**ADR と `docs/` 配下の過去成果物（specs / plans / superpowers）は当時の記録として書き換えない。**

## Consequences

- shared に新しい agent を足すときは、**ありふれた役割名を避けるか、install 済み plugin と突き合わせる**。確認は `find ~/.claude/plugins/cache -path "*/agents/*.md"` で全 plugin の agent 名を列挙して行う。
- **残存リスクは消えていない。** shared の他 12 体（`backend-engineer` / `qa-engineer` / `security-engineer` / `software-architect` 等）も一般的な名前で、将来 install する plugin 次第で同じ衝突を起こしうる。本 ADR は現に衝突している 1 件を解消するもので、名前空間の設計を根本から変えるものではない。
- enhance-superpowers ADR-0005 / ADR-0012 / ADR-0013 と indie-studio ADR-0031 の本文には旧名 `code-reviewer` が残る。ADR は immutable のため書き換えず、**inline 注記で本 ADR を指す**（root `AGENTS.md` が認めるナビゲーション注記）。ADR-0013 が定めた運用（コードレビュー activity は `code-review` skill を default とし、この agent は判定 aid 専用に予約する）は名前が変わるだけで有効。
- 公開済みリリースノートに旧名が載っている場合、それも当時の記録として残る。

## Alternatives Considered

- **`feature-dev` plugin を無効化する**：`enabledPlugins` から 1 行削除するだけで済み、コレクション側の変更はゼロ。しかし回避が**環境側の設定に依存する**ため、他マシン・他ユーザー・将来の再 install で再発する。本リポジトリは plugin として配布される以上、consumer の環境に「特定の公式 plugin を無効にしていること」を要求するのは筋が悪い。却下。
- **`shared:code-reviewer` を廃止し、`code-review` skill と `shared:reviewer` に一本化する**：ADR-0013 が既にこの agent を判定 aid 専用に格下げしている流れには沿う。しかし `shared:reviewer` は `Bash` を持たず「要件・設計 doc の評価」担当であり、実装スライスの評価（テスト / 型 / lint の再実行を伴う）を引き受けられない。穴が残るため却下。
- **`staff-engineer` / `maintainer` へ改名する**：どちらも実在する職種・ロール名だが、前者は等級名のため「レビュー 4 体」の分類に入れると役割がぼやけ `principal-engineer` との使い分けが不明瞭になり、後者は統括寄りのニュアンスで実装 5 / レビュー 4 / 設計・統括 4 の分類軸を崩す。却下。

## 関連

- ADR-0010 (shared-as-plugin-agent-namespace): 本 ADR が extends する。衝突時の失敗モード（負けた側の agent セットが丸ごと落ちる）の実測記録
- ADR-0004 (shared-agent-vendoring): 中立語彙原則。本 ADR は「中立 ≠ 衝突しない」を補足する
- enhance-superpowers ADR-0013 (gwt-test-qa-engineer-always-dispatch-and-code-review-auto-invoke): この agent を判定 aid 専用に予約した決定。名前のみ変更
- indie-studio ADR-0031 (skill-invocation-context-for-neutral-agents): 中立 agent への context 受け渡し規律。本 ADR 後も有効

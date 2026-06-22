# indie-studio 中間成果物を `docs/indie-studio/` 配下に namespace 化

ADR-0016 / 0021 で確定した service repo の出力レイアウトは、`docs/discovery/` ・ `docs/tech/` ・ `docs/decomposition/` を **`docs/` 直下に直接展開**する。実運用に投入したところ、service repo 自身のドキュメント（プロダクト readme・運用 guides・チーム向け notes 等）と物理的に混在し、**「indie-studio ハーネスが書いたもの／service repo 固有のもの」の出処が一目で判別できない**問題が出た。本 ADR で中間成果物 3 種を `docs/indie-studio/` 配下に namespace 化し、ハーネス由来の領域を 1 箇所に隔離する。

`docs/adr/` と repo-root の `AGENTS.md` / `CLAUDE.md` / `CONTEXT.md` / `DESIGN.md` は **「ハーネスが種まきするが以降は service repo 自身が育てる living な資産」** として root に残し、namespace 化対象から外す。

## Status

accepted（ADR-0016 のレイアウト図と ADR-0021 の `docs/discovery/` 表記を namespace prefix で更新。ADR-0016 / 0021 本文は immutable・inline 注記で本 ADR を指す。）

## 決定

1. **中間成果物 3 種を `docs/indie-studio/` 配下に移す**：

   | 旧 path | 新 path | 担当ステージ |
   |---|---|---|
   | `docs/discovery/` | `docs/indie-studio/discovery/` | S1 service-discovery |
   | `docs/tech/` | `docs/indie-studio/tech/` | S1a stack-direction / S3 tech-design |
   | `docs/decomposition/` | `docs/indie-studio/decomposition/` | S4 decomposition |

   `docs/indie-studio/discovery/` 配下の構造（`anchors/` / `planning/` / `design/` / `brief.md`）と `docs/indie-studio/tech/` 配下の構造（`stack-direction/` / 6 観点ファイル等）は ADR-0016 / 0021 / 0026 / 0027 の規定をそのまま namespace 下に保つ。

2. **namespace 化しないもの（root 維持）**：

   | path | 維持理由 |
   |---|---|
   | `<service-repo>/AGENTS.md` | https://agents.md 規約（複数 AI エージェント共通の正本）・root に置くのが慣習 |
   | `<service-repo>/CLAUDE.md` | `@AGENTS.md` ポインタ・root 配置が前提（ADR-0016） |
   | `<service-repo>/CONTEXT.md` | ユビキタス言語の生きた辞書・全エージェントが直読み（ADR-0016） |
   | `<service-repo>/DESIGN.md` | Claude Design への入力・root 配置が ADR-0020 で確定済み |
   | `<service-repo>/docs/adr/` | S3 で種まき後、S5 以降は service repo 自身が追記する全体共有 ADR 置き場（ADR-0016） |

3. **service repo の新レイアウト**（ADR-0016 を本 ADR で再定義）：

   ```plaintext
   <service-repo>/
   ├── AGENTS.md               # 規約正本（S3 生成・以降 service repo 資産）
   ├── CLAUDE.md               # @AGENTS.md ポインタ
   ├── DESIGN.md               # デザイン憲法（S1b 配置・living・ADR-0020）
   ├── CONTEXT.md              # ユビキタス言語（S3 種まき → S5 が育てる）
   ├── docs/
   │   ├── adr/                # 設計判断（S3 種まき → S5 追記・service repo 資産）
   │   └── indie-studio/       # ハーネス由来の中間成果物（本 ADR で導入）
   │       ├── discovery/      # S1
   │       │   ├── anchors/
   │       │   ├── planning/
   │       │   ├── design/
   │       │   └── brief.md
   │       ├── tech/           # S1a + S3
   │       │   └── stack-direction/
   │       └── decomposition/  # S4
   └── src/                    # S5 実装コード
   ```

4. **commit scope は namespace を反映**：従来 `docs(discovery):` / `docs(tech):` / `docs(decomposition):` で分離していた scope を、`docs(indie-studio/discovery):` 等の階層 scope に更新（任意・既存規約を守る repo は従来 scope のままで良い）。

5. **既存 service repo の migration**：手動で `git mv docs/discovery docs/indie-studio/discovery` 等を行う。各 service repo は少数（個人開発前提）なので一括スクリプトは用意しない。migration 後は inline で path 参照している commit history は自然に古いままになる（履歴は immutable）。

## Considered Options

### A. namespace 化する範囲

- **却下：root の `*.md`（AGENTS.md / CLAUDE.md / CONTEXT.md / DESIGN.md）も `docs/indie-studio/` 配下に動かす**。AGENTS.md は https://agents.md 規約で root 配置が他 AI エージェント（codex / copilot 等）の前提。動かすと multi-agent 互換が壊れる。CONTEXT.md / DESIGN.md は全エージェントが直読みする「生きた憲法」で、root 配置の方がパスが安定し参照側のメンテコストが低い。
- **却下：`docs/adr/` も `docs/indie-studio/adr/` に動かす**。S5 以降は service repo 自身が追記する全体共有 ADR 置き場で、indie-studio 限定の領域ではない。namespace 下に閉じ込めると service repo 固有の ADR との分離が起き、運用上の混乱を招く。
- **採用：中間成果物 3 種（discovery / tech / decomposition）のみ namespace 化**。「ハーネスが書く→ハーネスしか読まない中間物」と「ハーネスが種まき→以降 service repo 資産」の境界で切り、出処の判別性と root 配置の慣習を両立する。

### B. namespace 名

- **却下：`docs/harness/`**。汎用名で「どのハーネス由来か」が読めない。複数のハーネスを併用する将来（あり得る）に衝突する。
- **却下：`docs/_indie-studio/` のような prefix 付き**。alphabetical sort で上位に来るが、underscore prefix の慣習（hidden / internal）と意味が合わない。中間成果物は隠したいわけではなく**出処を明示したい**ので逆効果。
- **採用：`docs/indie-studio/`**。コレクション名と一致し、`.claude-plugin/plugin.json` の name とも揃う（root `CONTEXT-MAP.md` のコレクション索引と読み手の頭の中で 1:1 対応する）。

### C. ADR-0016 / 0021 の扱い

- **却下：ADR-0016 / 0021 を全面改訂（本文書き換え）**。ADR は決定の歴史で immutable が原則（ADR-0024 等の既存 ADR が「ADR-XX で再定義」の inline 注記を入れる先例を踏襲）。本文を書き換えると過去の判断経緯を失う。
- **採用：ADR-0028 を新規発行し、ADR-0016 / 0021 の該当箇所に「ADR-0028 で再定義」の inline 注記**。歴史を保ちつつ最新仕様を辿れる。

## Consequences

- **既存 ADR の inline 注記更新**：
  - `indie-studio/docs/adr/0016-service-repo-output-layout.md`：レイアウト図と Consequences に「ADR-0028 で `docs/indie-studio/` 配下に namespace 化」の注記
  - `indie-studio/docs/adr/0021-s1-discovery-layout-finalization.md`：`docs/discovery/` 表記に同注記
- **既存 SKILL.md 6 本の path 書き換え**：`indie-studio/skills/{service-discovery, stack-direction, design-direction, tech-design, decomposition, implementation}/SKILL.md` の `docs/discovery/` ・ `docs/tech/` ・ `docs/decomposition/` を `docs/indie-studio/` 配下に書き換え。`docs/adr/` ・ root `*.md` 言及は触らない。
- **既存 agent.md の path 書き換え（description frontmatter + body 両方）**：18 体の agent のうち path を言及している全 agent ファイルが対象。`description` は session 開始時の Agent type 登録に反映されるため漏らさない。
- **`indie-studio/CONTEXT.md` の path 言及更新**：line 88（`docs/discovery/{anchors,planning,design,brief.md,DECISIONS.md}` の例）と line 98（`docs/discovery/anchors/` 等の例）を `docs/indie-studio/discovery/` に更新。
- **ADR-0026 / 0027 の path 言及**：本文中の `docs/tech/stack-direction/` ・ `docs/tech/build-vs-buy-detail.md` 等の path は immutable な歴史。本 ADR では触らず、最新の path は SKILL.md / agent.md で示す（ADR は決定経緯の保存場所、運用 path は実行アーティファクト側で正本管理）。
- **既存 service repo の migration**：socialcoffeenote 等の既存 service repo は本 PR merge 後に手動 `git mv` で移行（個別 PR）。migration 完了までは新 / 旧 path の混在期間がある。
- **`docs/adr/` 維持の含意**：S5 で service repo 自身が ADR を追記するとき、indie-studio が種まきした初期 ADR と同居する。「indie-studio 由来 vs service repo 固有」の出処は ADR の commit author / commit message から辿る（ファイル配置では区別しない）。

## 未確定

- **multi-harness 共存時の namespace 切り**：将来 indie-studio とは別のハーネス（例：別の collection）を同じ service repo で使う場合の `docs/<harness-name>/` 共存ルール。本 ADR の `docs/indie-studio/` は単一ハーネス前提で決めた。複数ハーネス併用が現実になったら別 ADR で `docs/_harness/` のような meta namespace を検討するか、各ハーネスが自分の namespace を持つ素朴形を続けるか判断。
- **commit scope の階層表記**：`docs(indie-studio/discovery):` のようなスラッシュ入り scope を Conventional Commits の解釈系（CodeRabbit / release-please 等）が壊れずに扱うかは未検証。壊れる場合は `docs(discovery):` の従来 scope を続ける（namespace は path で表現済みなので scope の階層化は必須ではない）。

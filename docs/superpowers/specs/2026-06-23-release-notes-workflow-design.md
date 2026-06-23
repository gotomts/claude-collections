# Spec: claude-collections のリリースノート運用 (release-drafter + GitHub Releases)

- **Date**: 2026-06-23
- **Author**: gotomts (via Claude Code brainstorming)
- **Status**: approved (writing-plans フェーズ起動可)
- **Sources**: `$TMPDIR/handoff-claude-collections-docs-add-release-notes-workflow.md`
- **Related ADRs (existing)**: [ADR-0001](../../adr/0001-multi-collection-repo.md) (複数コレクション構造), [ADR-0003](../../adr/0003-plugin-marketplace-distribution.md) (plugin marketplace 配布 / version 戦略 2 段階移行)
- **Related ADR (to be drafted by writing-plans)**: ADR-0004 (本 spec の最終決定記録)
- **Branch**: `docs/add-release-notes-workflow`

---

## 1. 目的と読者

- **目的**: claude-collections の各 plugin (現状 `indie-studio`、将来追加分も同様) の変更履歴を、利用者 (含む自分) が後から追えるようにする
- **主読者**: install 利用者 (`/plugin marketplace update` 後に「何が変わったか」を読む人。テスト期は実質「自分」、安定化フェーズ以降は外部利用者も含む)
- **副次効果**: 「明日の自分」「他プロジェクトで使う未来の自分」も同じ release notes を読むことで作業ログとしても機能する

---

## 2. アーキテクチャ全体

```
┌──────────────────────────────────────────────────────────────┐
│ claude-collections (GitHub repo)                              │
│                                                               │
│ ┌────────────────────────────────────────────────────────┐  │
│ │ .github/                                                 │  │
│ │  ├─ release-drafter-indie-studio.yml   ◄─ config 1      │  │
│ │  │   (将来 release-drafter-<collection>.yml 追加)        │  │
│ │  └─ workflows/                                           │  │
│ │      └─ release-drafter-indie-studio.yml                 │  │
│ │          (push:main + paths:['indie-studio/**'])         │  │
│ └────────────────────────────────────────────────────────┘  │
│                                                               │
│ Conventional Commit な PR が main へ merge                    │
│              │                                                │
│              ▼                                                │
│  ① release-drafter@v6 が draft Release を更新                │
│              │                                                │
│              ▼                                                │
│  ② PR merge 直後の Claude Code セッションで判断              │
│     (AGENTS.md 規約で必須化)                                  │
│     Claude Code が gh release view で draft 確認              │
│     → 内容のまとまりを評価 → publish 推奨 or 待機             │
│              │                                                │
│              ▼                                                │
│  ③ ユーザー承認後、Claude Code が gh release edit で publish │
│              │                                                │
│              ▼                                                │
│  ④ GitHub Release tag: indie-studio/v0.0.x                   │
│  (テスト期は v0.0.x、安定化フェーズで v0.1.0 以降)             │
└──────────────────────────────────────────────────────────────┘
```

---

## 3. tag 命名規約と version 戦略

| 項目 | 規約 |
|---|---|
| tag format | `<collection>/v<semver>` (例: `indie-studio/v0.0.1`) |
| 区切り文字 | slash (`/`) — Go modules / nx 等 monorepo の業界標準 |
| テスト期 version | `0.0.x` 系で随時 publish。**version-resolver は全 label を patch に固定** (feat 含む。理由: `0.0.x → 0.1.0` の自動昇格は安定化フェーズへの意図せぬ突入を意味するため抑制する) |
| 安定化フェーズ version | `0.1.0` 以降 semver。version-resolver を kissasoft-mcp 同形に書き換え (feat→minor / fix・refactor・docs・test・chore→patch / major→major)。breaking = major / 新機能 = minor / 修正 = patch |
| plugin.json `version` field | テスト期は省略 (ADR-0003 通り、git SHA pin)。安定化フェーズで明示 |

**独立性の確認**: GitHub Release tag と plugin.json の `version` field は独立した軸。テスト期は「Release tag は積むが plugin.json version は省略」が成立する (consumer は main 追従、tag は履歴として独立)。ADR-0003 と矛盾しない。

---

## 4. publish ポリシー

| 項目 | 主体 | 詳細 |
|---|---|---|
| draft の自動更新 | release-drafter (GitHub Actions) | main マージごとに draft が自動更新される |
| publish 判断 | Claude Code | PR merge 直後の Claude Code セッションで `gh release view --tag=indie-studio/<latest-draft-tag>` で draft 内容を確認、内容のまとまり (e.g. 機能完成 / 数 PR 蓄積 / リファクタ完了 / docs まとめ) を評価して publish 推奨 or 待機を提案 |
| publish 操作 | Claude Code (ユーザー承認下) | ユーザーが OK と回答後、Claude Code が `gh release edit --tag=indie-studio/v0.0.x --draft=false` で publish 実行 |
| trigger 規約 | root AGENTS.md | 「PR merge 後の Claude Code セッションで publish 判断を必ず実行」を明記 |
| backup 1 (session 開始時) | Claude Code | root AGENTS.md に「セッション開始時に未 publish draft の有無を確認、溜まってたら publish 判断を提案」を明記。merge 後にセッション閉じた case の漏れを拾う |
| backup 2 (月次) | 人間 | `indie-studio/ROADMAP.md` に「月次 draft 状態レビュー」を 1 行追加。backup 1 でも漏れた case の最終 safety net |

---

## 5. label 運用

- **付与方式**: autolabeler で PR title から自動付与 (Conventional Commits prefix 検出)
- **categories** (見出しは kissasoft-mcp と完全同形、**version-resolver のみテスト期は patch 固定**):

| Label | Category | bump (テスト期) | bump (安定化フェーズ) |
|---|---|---|---|
| `feat` | ✨ Features | **patch** | minor |
| `fix` | 🐛 Fixes | patch | patch |
| `refactor` | ♻️ Refactor | patch | patch |
| `docs` | 📝 Docs | patch | patch |
| `test` | ✅ Tests | patch | patch |
| `chore` | 🔧 Chore | patch | patch |
| `major` | (手動付与のみ、category なし) | **patch** (テスト期は major bump 抑制) | major |

- **autolabeler pattern** (release-drafter config に同居):
  ```yaml
  autolabeler:
    - label: "feat"
      title: ["/^feat(\\(.+\\))?:/"]
    - label: "fix"
      title: ["/^fix(\\(.+\\))?:/"]
    - label: "refactor"
      title: ["/^refactor(\\(.+\\))?:/"]
    - label: "docs"
      title: ["/^docs(\\(.+\\))?:/"]
    - label: "test"
      title: ["/^test(\\(.+\\))?:/"]
    - label: "chore"
      title: ["/^chore(\\(.+\\))?:/"]
  ```
- **ブートストラップ**: 導入 PR は autolabeler が動かない (release-drafter は config を main から読むため) → 導入 PR のみ手動 label 付与

---

## 6. 成果物リスト (writing-plans フェーズで生成するファイル)

| ファイル | 種別 | 内容 |
|---|---|---|
| `docs/adr/0004-release-notes-workflow.md` | 新規 | ADR (本 spec の最終決定記録、ADR-0003 を参照) |
| `.github/release-drafter-indie-studio.yml` | 新規 | release-drafter config (categories / autolabeler / tag-template / version-resolver) |
| `.github/workflows/release-drafter-indie-studio.yml` | 新規 | GitHub Actions workflow (push:main + paths:['indie-studio/**'] + workflow_dispatch) |
| `AGENTS.md` (root) | 追記 | 「## リリースノート運用」節を追加。内容: collection 単位 release / tag 命名 / PR merge 後の publish 判断 trigger 規約 / セッション開始時の未 publish draft 確認 / 月次 draft レビュー |
| `indie-studio/ROADMAP.md` | 追記 | 「月次 draft レビュー」「安定化フェーズ移行時の TODO」を追記 |

---

## 7. ADR-0004 の位置付け

- **配置**: root `docs/adr/0004-release-notes-workflow.md` (横断決定)
- **ADR-0003 との関係**: ADR-0003 を **参照** (extends ではない — version 戦略は変更しない)
- **記録内容 (writing-plans で詳細化)**:
  - **採用**: release-drafter + GitHub Releases、collection 単位 config、slash tag (`<collection>/v<semver>`)、テスト期 `v0.0.x` で publish (version-resolver 全 patch 固定)、Claude Code 判断 + ユーザー承認下 publish、autolabeler 自動付与、kissasoft-mcp 同形 6 categories
  - **却下**: 単一 CHANGELOG.md / 手書き運用 / 集約 1 config / hyphen tag / draft 維持厳守 (publish しない) / 完全自動 publish / 完全人間 publish / autolabeler 見送り / version-resolver を kissasoft-mcp 同形にする (テスト期に minor bump で 0.1.0 突入リスク) / GitHub Actions + claude-code-action 半自動化 (Phase 2 候補として保留)
  - **Consequences**: 安定化フェーズ移行時に ADR-0004 を extends する形で別 ADR を起こす (version-resolver を kissasoft-mcp 同形に書き換え / Breaking category 追加 / plugin.json semver 明示 / autolabeler の major 検出パターン追加)

---

## 8. 未決事項 / 将来拡張 (本 spec のスコープ外)

| 拡張項目 | 契機 | 記録方法 |
|---|---|---|
| plugin.json に `version` field 明示 | ADR-0003 の 2 段階移行 | ADR-0003 を extends する新 ADR |
| version-resolver を kissasoft-mcp 同形 (feat→minor / major→major) に書き換え | 安定化フェーズ移行 | ADR-0004 を extends する新 ADR (上 row と同タイミングで実施) |
| `💥 Breaking` category 追加 | 安定化フェーズで意味を持つ | ADR-0004 を extends する新 ADR |
| autolabeler の major 検出パターン追加 | 同上 | 同上 |
| GitHub Actions + claude-code-action による半自動化 (D-b) | session 漏れが頻発 / 外部 contributor 増加 | ADR-0004 を extends する新 ADR (cost / API key / 承認フロー設計含む) |
| SessionStart hook で draft 状態を自動 context 注入 | AGENTS.md 規約だけでは漏れる場合 | settings.json (per-repo) で設定、ADR 不要 |

---

## 9. 設計判断のトレースログ (brainstorming Q1〜Q9)

| Q | 確定 | 主な却下案 |
|---|---|---|
| Q1 主読者 | install 利用者 | リポジトリ作業者 (自分) の作業ログ |
| Q2 配置 / ツール | GitHub Releases + release-drafter のみ | collection 単位 `<collection>/CHANGELOG.md` |
| Q3 tag 命名 | slash 区切り (`indie-studio/v0.0.1`) | hyphen 区切り (`indie-studio-v0.0.1`) |
| Q4 publish 方針 | テスト期も `v0.0.x` で実 publish | draft 維持厳守 / 定期自動 publish |
| Q5 publish 頻度 | 区切りで手動 publish | 毎マージ自動 publish / 定期スケジュール |
| Q6 config 構造 | collection ごと config 分離 | 集約 1 config + タグ手動書き換え (kissasoft-mcp 方式) |
| Q7 label 付与 | autolabeler 自動付与 | 手動付与 |
| Q8 categories | kissasoft-mcp 同形 6 カテゴリ | Breaking / Architecture 独立 category 追加 |
| Q9 publish 主体 | Claude Code 判断 + ユーザー承認下、PR merge 後トリガー (D-a) | ユーザー完全手動 / skill 化 (B) / cron 自動化 (C) / GitHub Actions 半自動化 (D-b) |

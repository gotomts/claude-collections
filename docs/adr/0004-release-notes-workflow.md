# claude-collections のリリースノート運用 (release-drafter + GitHub Releases)

`claude-collections` リポジトリの各 plugin (現状 `indie-studio`、将来追加分も同様) の変更履歴を、install 利用者 (含む自分) が後から追えるようにする。配置は GitHub Releases のみ (リポジトリ内 `CHANGELOG.md` ファイルは持たない)、ツールは [release-drafter@v6](https://github.com/release-drafter/release-drafter) を採用、collection 単位に config (`.github/release-drafter-<collection>.yml`) と workflow を分離、tag は slash 区切り (`<collection>/v<semver>`)、テスト期も `v0.0.x` で実 publish する (version-resolver は全 patch 固定で `0.1.0` 自動突入を抑制)、publish 判断と操作は Claude Code が担い、ユーザー承認下で `gh release edit` 実行、PR merge 後トリガー (AGENTS.md 規約で必須化)。autolabeler を有効化し PR title から Conventional Commits prefix で自動 label 付与 (kissasoft-mcp は autolabeler を見送ったが、claude-collections では導入 PR の手動 label で bootstrap を回避)。categories の見出しは kissasoft-mcp と同形 6 つ (✨ Features / 🐛 Fixes / ♻️ Refactor / 📝 Docs / ✅ Tests / 🔧 Chore)、ただし version-resolver の bump はテスト期は全 patch・安定化フェーズで kissasoft-mcp 同形に書き換える 2 段階移行。

## Status

accepted

## 関連 ADR

- [ADR-0001](0001-multi-collection-repo.md) — 複数コレクション構造 (自己完結原則の根拠)
- [ADR-0003](0003-plugin-marketplace-distribution.md) — plugin marketplace 配布 + version 戦略 2 段階移行 (本 ADR は ADR-0003 を **参照**、extends ではない — version 戦略を変更しない)

## Considered Options

### 配置 / ツール

- **却下：単一 root `CHANGELOG.md`** — install 利用者が自分の plugin の更新だけ追いたい時に他 collection の更新がノイズ。コレクション増加で肥大化。ADR-0001 の自己完結原則と齟齬。
- **却下：collection 単位 `<collection>/CHANGELOG.md`** — ファイル管理コスト、kissasoft-mcp で確立した release-drafter ノウハウを活かせない、安定化フェーズで GitHub Releases に切り替える / 併用するかを再判断必要。
- **却下：手書き運用** — Conventional Commits 採用済みなので自動生成系ツールが使える前提条件は揃っており、手書きは過小自動化。
- **採用：GitHub Releases + release-drafter@v6 のみ** — kissasoft-mcp で動作実績あり、monorepo 複数 app パターン (tag prefix で分離) も実装済み、ADR-0003 の 2 段階移行と同じツール内でシームレス (テスト期 = `v0.0.x` で publish、安定化フェーズ = `v0.1.0` 以降に semver 移行)。

### config 構造

- **却下：集約 1 config (kissasoft-mcp 方式)** — 「publish 前にタグを手動書き換え」運用が必要、collection 2 つ目が増えた瞬間に draft 混在問題が発生、後で分離に移行する二度手間。
- **採用：collection ごとに config 分離 (`.github/release-drafter-<collection>.yml`)** — AGENTS.md / CONTEXT-MAP.md で「複数コレクション」は確定設計。collection 増加は仮定でなく予定。最初から拡張前提の構造。

### tag 命名

- **却下：単一 semver (`v0.1.0`)** — collection 増加で衝突。
- **却下：hyphen 区切り (`indie-studio-v0.1.0`)** — collection 名自体に hyphen を含むと境目が視覚的に判別しにくい (`indie-studio-v…` で `studio` と `v` の区切りが弱い)。
- **採用：slash 区切り (`indie-studio/v0.1.0`)** — Go modules / nx 等 monorepo の業界標準、視覚的に階層が明確、collection 名が hyphen 含んでも誤読しない。

### publish ポリシー

- **却下：完全自動 publish (毎マージで release 積む)** — publish の judgment が消える、release 単位が「1 PR = 1 release」でノイズ多。
- **却下：draft 維持厳守 (テスト期は publish しない)** — テスト期に履歴として残らない、draft 一覧が「いびつ」な体験になる、GitHub の Releases タブの可視性が活かせない。
- **却下：定期スケジュール publish (cron)** — 「先週から変わってないのに publish」のような空 release リスク。
- **採用：区切りで publish、判断と操作は Claude Code がユーザー承認下で実行 (PR merge 後トリガー)** — judgment ポイントが残り release notes の質が上がる、kissasoft-mcp と運用同形 (脳内一貫性)、Claude Code が `gh release` で draft 確認 → 評価 → ユーザー承認後 publish。

### publish 主体

- **却下：人間が完全手動** — claude-collections は AI ハーネス系プロジェクトなので、判断と操作を Claude Code に委ねるのが dogfooding として自然。
- **却下：skill 化 (`/release-publish-check`)** — claude-collections の置き場 (どの collection に属するか) が別 brainstorming 必要で scope creep。
- **却下：cron 自動化** — publish 事故リスク (WIP draft を public 化)、judgment 消失。
- **却下：GitHub Actions + claude-code-action 半自動化** — 今回 spec のスコープを超過、cost / API key / 承認フロー設計が別 spec 必要 (Phase 2 候補として保留)。
- **採用：Claude Code 判断 + ユーザー承認下、PR merge 後トリガー (AGENTS.md 規約化)** — 追加実装ゼロ、Claude Code セッションが PR ブランチ作業中に開いてる前提と整合、publish 承認が人間に残り事故リスク最小、後から GitHub Actions 半自動化に発展可能。

### autolabeler

- **却下：手動付与 (kissasoft-mcp 流)** — kissasoft-mcp はブートストラップ問題 (config を main から読むため導入 PR で autolabeler が動かない) で見送ったが、これは導入 PR 1 回限りの制約で永続採用しない理由にならない。手動は付け忘れリスク常時あり。
- **採用：autolabeler で PR title から自動付与** — Conventional Commits 採用済みなので追加の人間操作なし、付け忘れゼロ、唯一の制約 (導入 PR は autolabeler が動かない) は導入 PR で手動 label 1 回付与すれば回避。

### version-resolver bump

- **却下：kissasoft-mcp 同形 (feat→minor / major→major)** — テスト期 (`v0.0.x` 厳守) で `feat` ラベル含む PR が出ると `0.0.x → 0.1.0` に minor bump し、意図せず安定化フェーズへ突入。
- **採用：テスト期は全 label patch 固定、安定化フェーズで kissasoft-mcp 同形に書き換え** — テスト期は `v0.0.x` 系を厳守、安定化フェーズへの移行は ADR-0003 の境界判断に乗せ、その時点で本 ADR を extends する新 ADR で `feat→minor` 等の bump rule を有効化。

### categories

- **却下：Breaking / Architecture など固有 category 追加** — テスト期 (常に main 追従 = 常に breaking 可能性あり) では Breaking category が機能しない、ADR 用 category は `docs:` prefix と autolabeler パターンが衝突する。
- **採用：kissasoft-mcp 同形 6 categories (見出しのみ流用)** — `feat / fix / refactor / docs / test / chore`。bump rule のみテスト期は全 patch に固定 (上記)。安定化フェーズで Breaking category 追加を別 ADR で記録。

## Consequences

- `.github/release-drafter-indie-studio.yml` + `.github/workflows/release-drafter-indie-studio.yml` の 2 ファイルが追加される。将来 collection 増加時は同形の 2 ファイル追加で拡張 (`release-drafter-<collection>.yml`)。
- root `AGENTS.md` に「## リリースノート運用」節が加わる。内容: PR merge 後の Claude Code セッションで publish 判断を必ず実行 / セッション開始時の未 publish draft 確認 / 月次 draft レビュー (backup) / 導入 PR の bootstrap 手順。
- `indie-studio/docs/ROADMAP.md` に「## リリース運用 (ADR-0004)」セクションが加わる。月次 draft 状態レビューと安定化フェーズ移行 TODO を記録。
- 安定化フェーズ移行時に本 ADR を **extends する新 ADR** を起こす。記録内容: version-resolver を kissasoft-mcp 同形 (`feat→minor` / `major→major`) に書き換え / `💥 Breaking` category 追加 / autolabeler の major 検出パターン追加 / plugin.json semver 明示 (ADR-0003 を extends する形と併せて 1 ADR にまとめても可)。
- 「Phase 2 として GitHub Actions + claude-code-action による半自動化」は session 漏れが頻発 / 外部 contributor 増加で検討。本 ADR を extends する新 ADR で記録。
- 本 ADR は repo 横断の決定 (全 collection 共通の運用ルール) であるため root `docs/adr/` に置く (ADR-0001 「横断決定は root」原則に従う)。
- GitHub Repository Settings → Actions → General → Workflow permissions を **「Read and write permissions」** にする必要がある (release-drafter が draft Release を作成するため `contents: write` が要る。read-only だと 403 で失敗)。

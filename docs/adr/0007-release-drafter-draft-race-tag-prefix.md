# 0007. release-drafter の draft race を tag-prefix で隔離する

## Status

Accepted (2026-07-08)。ADR-0006 (release-drafter-auto-discovery) を extends する。ADR-0006 が導入した「単一 workflow + matrix + テンプレ config」構造は維持したまま、matrix job 間で発生する draft race を tag-prefix 設定で塞ぐ。

## Context

ADR-0006 で release-drafter を **単一 workflow + collection 数だけ matrix 並列** する構造にした。各 draft job は自 collection の per-collection config (`.github/release-drafter-<collection>.yml`) を渡し、`include-paths` で「どの PR を集約するか」を collection 別に絞っている。

しかし release-drafter@v6 の `findPreviousReleases` は、**更新対象の既存 draft / 直近 published release を `tag-prefix` で filter して探す**。ADR-0006 のテンプレ config には `name-template` / `tag-template` / `include-paths` はあったが **`tag-prefix` が無かった**。結果:

- `include-paths` は「集約する PR 内容」のフィルタであって、「どの draft を更新対象に選ぶか」は制御しない (両者は別レイヤ)
- tag-prefix 未設定だと、各 matrix job は repo 内の draft を collection で区別できず「最初に見つかった draft」を existing draft として拾う
- 複数 collection の job が並列走行すると、同じ draft を互いに上書きし合う **draft race** が起きる (issue #22)

再現 (PR #21 merge 時): `indie-studio/v0.0.3` の空 draft が既存の状態で enhance-superpowers 専用 PR を merge したところ、`enhance-superpowers/v0.0.3` draft が生成されず、両 job が `indie-studio/v0.0.3` draft を奪い合い、最終的に indie-studio job の `No changes` で上書きされた。対症策 (空 draft を delete + `gh workflow run` で rerun) を複数回手動適用していた (memory `project_release_drafter_draft_race.md`)。

## Decision

テンプレ config (`.github/release-drafter-template.yml`) に **collection 別の tag-prefix** を追加する:

```yaml
tag-prefix: "{{COLLECTION}}/v"
```

`scripts/regen-drafter-configs.sh` が `{{COLLECTION}}` を置換するので、各 per-collection config は自 collection 固有の prefix (`indie-studio/v` / `enhance-superpowers/v`) を持つ。これで:

- 各 matrix job の draft 探索が自 collection の tag-prefix に一致する draft / release のみに絞られ、collection 間の draft 取り違えが構造的に消える
- tag-prefix は version parse 時に strip される。既存 published tag `indie-studio/v0.0.4` から prefix `indie-studio/v` を strip すると `0.0.4` となり、正しい semver として version-resolver に渡る (version 解決の挙動は不変)

再生成・drift 検知は ADR-0006 の仕組み (`make regen-drafter-configs` / `make verify-drafter-configs` / CI guard) をそのまま流用する。テンプレを変えて regen → commit するだけで全 collection に波及する。

## Consequences

- matrix job が並列走行しても draft race が起きない。空 draft の手動 delete + rerun の運用が不要になる
- draft/release 探索が tag-prefix で正しく scope されるため、直近 published release の判定 (last release) も collection 別に正確になる (従来は全 collection 混在で拾う余地があった)
- ADR-0006 の auto-discovery + matrix 構造は一切巻き戻さない。新 collection 追加時の「drafter 設定手作業ゼロ」も維持
- テンプレ config に 1 項目増えるが、regen script / verify / CI guard は既存のまま drift を検知できる

## Alternatives Considered

- **matrix を serialize (`needs` 順序化 or `max-parallel: 1`)**: race は消えるが、draft 探索の collection 混同という根本原因は残る (対症療法)。かつ draft 更新が直列化して遅くなる。却下
- **workflow を collection 別に分割 (per-collection workflow file)**: state を完全隔離できるが、ADR-0006 の auto-discovery を巻き戻し「collection 追加時の手作業ゼロ」を失う。過剰。却下
- **release-drafter を別 action (release-please / git-cliff 等) に置換**: 根本刷新だが学習 + 移行コストが大きく、tag-prefix 1 行で解決する問題には過剰投資。却下

## 関連

- ADR-0006 (release-drafter-auto-discovery): 本 ADR の親。単一 workflow + matrix + テンプレ config 構造を継承し、draft 探索の scope 欠落を補う
- ADR-0004 (release-notes-workflow): tag 命名 (`<collection>/v<semver>`) の規律。tag-prefix はこの命名と 1:1 対応
- issue #22: 本 ADR で対応する draft race の issue
- memory `project_release_drafter_draft_race.md`: 対症策と `Draft release: X` log の解釈を記録。本 ADR で恒久解決

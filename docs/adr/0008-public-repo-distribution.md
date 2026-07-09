# 0008. 配布経路を private repo から public repo へ切り替える

## Status

Accepted (2026-07-09)。ADR-0003 (plugin-marketplace-distribution) を extends する。ADR-0003 が定めた「リポジトリ = 1 marketplace、各コレクション = 1 plugin」の配布構造と「local path + repo marketplace の併用」という二経路方針は維持したまま、repo 経路の前提を **private → public** に更新する。version 戦略の 2 段階移行 (テスト期 git SHA pin → 安定化 semver) も ADR-0003 のまま据え置く。

## Context

ADR-0003 は配布経路として **local path + private repo の併用**を採用し、public 化は以下の理由で却下していた:

> 却下：public repo として公開（marketplace add で誰でも install 可）。`indie-studio` は現状テスト段階で、外部利用を想定したドキュメント整備（README install 手順・ライセンス・破壊的変更通知）が未成熟。

その後リポジトリを public 化したため、この却下理由の前提（外部非公開でよい）が消えた。private を前提にした運用記述が実態と食い違う:

- README の「別マシン・別環境から使う」節が `private repo` 見出し + `gh auth login` 必須という private 前提の手順になっている
- ADR-0003 本文 (Considered Options / 配布経路) も private repo 前提で書かれている

ADR-0003 本体は過去の判断記録として保持し (immutable + extends 規律)、本 ADR で決定を上書きする。

## Decision

配布経路を **local path + public repo の併用**に更新する:

- **local path marketplace**：ADR-0003 のまま。同 Mac 内の別プロジェクトには絶対パスで登録し、git push を介さず即反映（反復開発向け）。
- **public repo marketplace**：別マシン・別環境からは GitHub 経由（`/plugin marketplace add gotomts/claude-collections`）。**public repo なので `gh auth login` 等の事前認証は不要**。手動 install/update・auto-update いずれも認証なしで動く。`GITHUB_TOKEN` / `GH_TOKEN` は必須ではなく、GitHub API の未認証レート制限を避けたい場合の**任意**設定に格下げする。

version 戦略は ADR-0003 の 2 段階移行を継続する。**現時点はテスト期のまま**（`plugin.json` の `version` 省略 → git SHA pin、main 追従）。public 化それ自体は semver 明示への切り替え trigger ではない。安定化フェーズ（semver 明示・breaking change 通知）への移行判断は、従来どおり ADR-0003 を extends する**別 ADR**で記録する。

## Consequences

- README の別マシン手順から private 前提（`private repo` 見出し・`gh auth login` 必須・認証文脈の `GITHUB_TOKEN`）を除去し、認証不要の public 手順に書き換える。
- `marketplace.json` の description も含め、外部利用者向けドキュメントを public 前提で整える余地が生まれる（ADR-0003 が挙げた「ライセンス・破壊的変更通知」は今後の課題として残る）。
- 誰でも `marketplace add` / `install` 可能になる。テスト段の破壊的変更が外部 consumer に波及しうる点は、version 戦略の安定化フェーズ移行（別 ADR）で吸収する。
- ADR-0003 の配布構造（marketplace + per-collection plugin）・local path 経路・version 2 段階移行は一切巻き戻さない。

## Alternatives Considered

- **private repo のまま継続**：public 化が済んだ実態と食い違う。却下。
- **ADR-0003 本体を直接書き換え**：手数は最小だが immutable + extends 規律に反し、public を却下した過去の判断根拠が失われる。却下。
- **public 化と同時に semver 明示へ移行**：version 戦略の切り替えは配布経路とは独立の判断軸（テスト期の反復頻度・bump 忘れリスク）で決めるべきで、ADR-0003 は専用の別 ADR での記録を求めている。本 ADR のスコープ外とし据え置く。

## 関連

- ADR-0003 (plugin-marketplace-distribution): 本 ADR の親。配布構造・二経路方針・version 2 段階移行を継承し、repo 経路の private 前提のみ public に更新する
- ADR-0004 (release-notes-workflow): tag 命名・リリースノート運用。public consumer 向けの変更追跡はこの運用に連なる

# 0008. リポジトリ visibility を public にする（配布構造は不変）

`claude-collections` リポジトリの visibility を **public** にする。ADR-0003 が「却下：public repo として公開／採用：local path + **private** repo の併用」と決めた配布経路のうち、**repo の visibility 部分のみ**を変更する。marketplace 宣言・per-collection plugin・2 経路併用・version 2 段階移行という配布**構造**の decision は一切変更しない。

## Status

accepted（2026-07-28）。[ADR-0003](0003-plugin-marketplace-distribution.md) を **extends** する（supersede ではない — ADR-0003 の構造 decision は全て有効なまま）。

> **番号について**：本 ADR は ADR-0009 より後に書かれたが番号は 0008 である。旧 ADR-0008（public-repo-distribution）は非-decision の誤記録として PR #30 で削除され、その際「後続 feature ADR が 0008 を継ぐ」と明記されていた。しかし PR #31 が 0009 を取ってしまい 0008 に gap が生じたため、本 ADR が 0008 を埋めて連番を回復する（`AGENTS.md`「末尾番号を削除した場合は後続 ADR を詰めて連番を保つ」）。**採番は作成順ではなく連番維持を優先する。**

## Context

ADR-0003 は配布経路の検討で **public 化を明示的に却下**し、`local path + private repo の併用` を採用した。却下理由は「`indie-studio` は現状テスト段階で、外部利用を想定したドキュメント整備（README install 手順・ライセンス・破壊的変更通知）が未成熟」。

その後、リポジトリは **public になった**。動機は「個人実験を気軽に見せたい（private は共有が面倒）」であって、外部 consumer をサポートする決意ではない。

この事実は一度 ADR 化されたが（旧 ADR-0008 `public-repo-distribution`）、**存在しない外部 consumer サポート制約を捏造した非-decision** と判断され PR #30 で削除された。その判断自体は妥当である — 当時の ADR は「外部利用者向けに配布経路を整備する」という決意を記録しており、実態と食い違っていた。

**しかし削除の結果、ADR-0003 の decision が実態と矛盾したまま残った。** accepted な ADR が「private を採用」と記録しているのに repo は public、という状態である。

**動機が何であれ、accepted な decision の反転は decision である。** 旧 ADR-0008 の問題は「記録したこと」ではなく「捏造した framing」だった。よって framing を正した最小限の ADR で、事実だけを記録する。

## Decision

**リポジトリ visibility = public。** ADR-0003 の以下は**すべて有効なまま維持**する：

- marketplace 宣言（root `.claude-plugin/marketplace.json`）
- 各コレクション = 独立 plugin（`<collection>/.claude-plugin/plugin.json`）
- **配布経路は 2 つ併用**（local path marketplace + repo marketplace）
- version 戦略の 2 段階移行（テスト期 git SHA pin → 安定化で semver）

visibility 変更に伴う差分は次の 2 点のみ：

1. **ADR-0003 の「private repo marketplace」は「repo marketplace 経路」と読む**（visibility 非依存）。経路そのものは不変で、GitHub 経由で marketplace を登録する点も変わらない。
2. **事前認証が不要になる。** public なので `gh auth login` 等は不要で、手動 install/update・auto-update いずれも認証なしで動く。`GITHUB_TOKEN` / `GH_TOKEN` は必須ではなく、**GitHub API の未認証レート制限を避けたい場合の任意設定**に格下げする。

**外部利用者向けのサポートは約束しない。** ADR-0003 が public を却下した理由（外部利用を想定したドキュメント整備が未成熟／ライセンス・破壊的変更通知が未整備）は**今も解消していない**。public であることは「誰でも見られる・install できる」という事実にすぎず、互換性維持・変更通知・サポートの義務を伴わない。テスト期の破壊的変更が外部 consumer に波及しうる点は、version 戦略の安定化フェーズ移行（ADR-0003 を extends する別 ADR）で扱う。

実際の install 手順は **`README.md` を正本**とする（ADR は判断の記録であり、手順の正本ではない）。

## Consequences

- ADR-0003 と実態の矛盾が解消する。ADR-0003 本文は immutable のまま保持し、本 ADR へのポインタを 1 行だけ inline 注記として置く。
- 誰でも `/plugin marketplace add gotomts/claude-collections` で install できる。ただし上記のとおりサポートは約束しない。
- README / `marketplace.json` の description が public 前提で書かれている状態が、ADR に裏付けられる。
- root ADR の連番が回復する（0001-0009 が連続）。

## Alternatives Considered

- **却下：記録しない（ADR-0003 を実態と乖離させたまま残す）**。immutable は守れるが、accepted な ADR が事実と矛盾したまま残り、次に読む人が同じ混乱に陥る。実際に本 ADR を書く直前、`shared` plugin 化（ADR-0009）の Status が削除済みの旧 ADR-0008 を参照する dangling リンクを生んでいた。
- **却下：ADR-0003 に注記を入れて「private を visibility 非依存に読み替える」と書く**。本 PR の初版がこれだったが、ADR 本文が「却下：public／採用：private」と記録したままなので、**同一 ADR 内で decision と注記が矛盾**する。これは誤記訂正ではなく decision の適用範囲の変更であり、immutable 原則に反する（外部レビューで指摘され撤回）。
- **却下：ADR-0003 を supersede する**。変更するのは visibility だけで、配布構造の decision は全て有効。supersede は過剰。

## 関連

- ADR-0003 (plugin-marketplace-distribution): 本 ADR が extends する親。配布構造・2 経路・version 2 段階は継承
- ADR-0009 (shared-as-plugin-agent-namespace): marketplace に配る plugin を 3 個に増やした決定。配布構造は ADR-0003 を継承
- PR #30: 旧 ADR-0008（public-repo-distribution）を非-decision として削除。本 ADR はその判断を踏襲しつつ、framing を正して事実のみ記録する

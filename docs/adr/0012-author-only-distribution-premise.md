# 0012. 配布は作者のインストール利便のためであり、consumer 環境依存は単独では却下理由にならない

## Status

Accepted (2026-08-06)。[ADR-0009](0009-repository-visibility-public.md) を **extends** する。ADR-0009 の decision（visibility = public / 外部利用者向けのサポートは約束しない）はそのまま有効で、本 ADR はその前提を**内部の設計判断で使うときの規則**として書き下ろす。

## Context

**このコレクションの利用者は作者のみである**（2026-08-06 ユーザー確認）。配布（root `.claude-plugin/marketplace.json` + 各コレクションの plugin、[ADR-0003](0003-plugin-marketplace-distribution.md)）は、**作者が自分の環境へ楽にインストールするための手段**であって、他の利用者を想定したものではない。

この前提はどこにも書かれていない。その結果、「consumer 環境に依存するから」という理由で案を却下した箇所が 2 つある。

| ADR | 却下した案 | 却下理由（本文引用） |
|---|---|---|
| [ADR-0011](0011-external-plugin-agent-name-collision.md) | `feature-dev` plugin を無効化する | 「回避が**環境側の設定に依存する**ため、他マシン・他ユーザー・将来の再 install で再発する。本リポジトリは plugin として配布される以上、consumer の環境に『特定の公式 plugin を無効にしていること』を要求するのは筋が悪い」 |
| enhance-superpowers [ADR-0016](../../enhance-superpowers/docs/adr/0016-local-review-to-implementation-reviewer-and-builtin-review-after-pr.md) D3 理由 2 | bundled `/code-review` を採用する | 「**consumer 環境の skill 構成に依存する**。personal skill `code-review` を持つ環境ではシャドウされて到達不能になる。（略）consumer に特定の skill 名を空けておくことを要求するのは筋が悪い」 |

両者は同じ論法（「plugin として配布される以上、consumer に○○を要求するのは筋が悪い」）を使っている。**consumer が存在しない以上、この論法は前提が成り立たない。**

ADR-0009 は既に近いことを書いている — 「外部利用者向けのサポートは約束しない。public であることは『誰でも見られる・install できる』という事実にすぎず、互換性維持・変更通知・サポートの義務を伴わない」。ただし ADR-0009 が記録しているのは**対外的な義務の不在**であって、**内部の設計判断で consumer 環境依存をどう扱うか**というルールではない。その差が埋まっていないため、設計判断のたびに同じ議論が再発する（実際に 2 回起きている）。

## Decision

**配布は作者が自分の環境へインストールする利便のためであり、他の利用者を想定しない。したがって consumer 環境依存は、それ単独では案を却下する理由にならない。**

- 「本リポジトリは plugin として配布される以上、consumer に○○を要求するのは筋が悪い」という論法は使わない。**要求される相手が作者しかいない**ため、この論法は何も否定できない。
- ただし「**作者自身の環境で再発する**」（他マシン・将来の再 install で作者が同じ問題を踏む）は、consumer 環境依存とは別の、依然として有効な却下理由である。使うときは consumer への要求ではなく**作者が踏む不便**として書くこと。
- 本 ADR は却下理由の 1 つを無効化するだけで、**既存の decision の結論は変更しない**（下記「適用範囲」）。

### 適用範囲：既存 2 ADR の結論は別理由で維持される

本 ADR は上表の 2 ADR の**却下理由の一部を無効化する**が、**どちらの結論も変わらない**。

- **[ADR-0011](0011-external-plugin-agent-name-collision.md)** — 「`feature-dev` plugin を無効化する」案の却下理由から consumer 環境依存が消えても、**agent 名の衝突そのもの**という別理由が残る。同名 agent を持つ 2 plugin が共存すると、負けた側の agent セットが registry から丸ごと落ち、衝突していない agent まで巻き添えになる（ADR-0010 で実測済みの失敗モード）。`shared:code-reviewer` → `shared:implementation-reviewer` の改名は有効なまま。
- **enhance-superpowers [ADR-0016](../../enhance-superpowers/docs/adr/0016-local-review-to-implementation-reviewer-and-builtin-review-after-pr.md) D3** — 本文が「理由は 2 つあり、**どちらか一方でも採用を否定する**」と明記している。無効になるのは理由 2 だけで、**理由 1（bundled `/code-review` はモデルから起動できない。v2.1.215 以降、user が明示的に打ったときだけ動く）が残る**。bundled `/code-review` は引き続き採用しない。

両 ADR には本 ADR を指す inline 注記のみを置き、Decision / Considered Options / 却下理由の本文は書き換えない（`AGENTS.md`「ADR は原則 immutable」・ナビゲーション注記の例外）。

### 判断が変わる条件

**外部利用者を想定する方針に転じたら、本 ADR を supersede する新 ADR で戻す。** 具体的には、作者以外の利用者が実在すると確認されたとき、または外部利用者向けの互換性維持・変更通知を約束したとき。その時点で consumer 環境依存は再び有効な却下理由になる。

## Consequences

- 今後の設計判断で、consumer 環境依存を単独の却下理由に使わない。規約行を `AGENTS.md`「構成規約」に置き、詳細は本 ADR に持たせる。
- **却下理由が 1 つに減った案は、残る理由が崩れた時点で再検討の対象になる。** enhance-superpowers ADR-0016 D3 は理由 1 のみで立っているため、bundled `/code-review` がモデルから起動できるようになれば再検討できる（その場合も判断は新 ADR で行う）。
- ADR-0009 との関係が整理される。ADR-0009 = 対外的な義務の不在、本 ADR = 内部の設計判断で使う規則、と役割が分かれる。
- 過去の ADR 本文には無効化された却下理由が残る。これは immutable の帰結であり、注記が本 ADR を指すことで解決する。

## Alternatives Considered

- **却下：`AGENTS.md` への規約追記だけで済ませ、ADR を起こさない**。ファイル 1 つで済むが、既存 2 ADR の却下理由を無効化するのは**適用範囲の変更**であり、`AGENTS.md` 自身が「注記で決定の適用範囲を変えるのも禁止（それは新 ADR で supersede／extends する）」と定めている。規約違反になる。
- **却下：ADR-0011 / enhance-superpowers ADR-0016 を supersede する**。両者の結論は別理由で維持されるため、supersede すると結論まで無効化したと読まれる。無効化するのは却下理由の一部であって decision ではない。
- **却下：既存 2 ADR の却下理由本文を書き換える**。immutable 違反。ADR が守るのは判断の根拠であり、当時 consumer 環境依存を理由に使ったという事実自体が根拠の一部である。
- **却下：前提を暗黙のまま置く**。書かなくても作者は知っているが、実際にこの前提を知らない状態で設計判断が 2 回行われた。次のセッションが同じ議論を繰り返す。

## 関連

- [ADR-0009](0009-repository-visibility-public.md) (repository-visibility-public): 本 ADR が extends する親。「外部利用者向けのサポートは約束しない」の内部規則版が本 ADR
- [ADR-0003](0003-plugin-marketplace-distribution.md) (plugin-marketplace-distribution): 配布構造の決定。構造そのものは不変で、本 ADR はその**目的**（作者のインストール利便）を明文化する
- [ADR-0011](0011-external-plugin-agent-name-collision.md) (external-plugin-agent-name-collision): 却下理由の 1 つが本 ADR で無効になる。結論（`implementation-reviewer` への改名）は agent 名衝突を理由に維持
- enhance-superpowers [ADR-0016](../../enhance-superpowers/docs/adr/0016-local-review-to-implementation-reviewer-and-builtin-review-after-pr.md) (local-review-to-implementation-reviewer-and-builtin-review-after-pr): D3 理由 2 が本 ADR で無効になる。結論（bundled `/code-review` を採用しない）は理由 1 で維持

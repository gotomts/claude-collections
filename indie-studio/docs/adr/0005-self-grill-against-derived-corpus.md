# 精緻化は導出ドキュメント群を答え合わせ材料にした self-grill（ティアは決定単位のランタイム判断）

要件精緻化を人間対話の grill/brainstorm ではなく **self-grill** で行う。エージェントが griller と answerer の両役を演じ、答え合わせ材料（corpus）＝ service-designer/prototype-designer の成果物・プロトタイプ（ハンドオフバンドル）・tech/infra の導出ドキュメントを読み込んで自答し、PR を出す。ティアリングは**決定単位のランタイム判断 (Y)**：全要件を self-grill し、個々の決定が「context から既約 かつ 不可逆/高ステークス」のときだけゲートで晒す。

## Status

accepted

## Considered Options

- **却下 (X): チケット単位の事前ラベル**。issue-decomposer が HITL/AFK を貼り分ける案。粒度が粗く、HITL チケットは結局「全体を人間対話」に戻り、膨大なやりとりを再発させる。ラベルは廃止せず self-grill への粗いヒントとして残す程度。

## Consequences

- self-grill の corpus は**自律導出**される必要がある。tech-designer が人間対話のままなら 3 週間の罠が下流に移るだけ。corpus 生成自体を自走化し、技術設計ゲートで人間がレビューする。
- corpus の**完全性は前提にしない**。ADR-0004 に従い、feature-team はギャップを decide-record-proceed（仮定を置き PR に明記）で埋め、停止しない。「すべて落とし込めているはず」は理想であって依存条件ではない。
- corpus の所在と transport（Obsidian vault 直読か repo/チケットへのスナップショットか）は未確定。ハンドオフバンドルは design を repo へ運ぶ前例。

# プロトタイプゲートの修正は人間駆動の並列デュアル訂正（Claude Design ∥ Claude Code）

プロトタイプが期待値以下のとき、人間は背景（導出ドキュメント＝正当化トレイル）を読んで認識齟齬を理解し、**ドキュメント修正指示を Claude Code に、プロトタイプ修正依頼を Claude Design に並列で**出す。Claude Design（claude.ai）と Claude Code は別環境で並行稼働する。逆伝播はシステムの自動同期ではなく、ゲートで人間が両面を同時に訂正することで担保する。人間が整合性の保持者。

## Status

accepted

## Considered Options

- **却下 (P) 前方再導出 / (R) ゲート出口逆同期**：いずれもシステムが docs ⇄ prototype を自動同期する案。ユーザーは「背景を理解した人間が両面を並列訂正する」方を選択。プロトタイプゲートは判断が集中する HITL であり、人間が能動的に駆動するのが自然。

## Consequences

- プロトタイプゲートは設計上**最も対話の多い HITL ゾーン**（"何度もやりとり"）。自動化は他フェーズへ寄せ、ここは人間の判断面とする。
- **背景ドキュメント（正当化トレイル）が読めること**が、人間が齟齬を指摘できる前提。docs as justification trail の要件をここで満たす。
- **リスク**：docs(Claude Code) と prototype(Claude Design) の 2 つの並列訂正が乖離しうる。人間が同一意図を両面に反映する規律と、訂正後の再ハンドオフ（Claude Design → バンドル → repo）で整合を回復する運用が要る。
- **含意**：docs は Claude Code から編集可能＝**repo-native か vault-via-MCP** である必要。corpus transport の未確定（所在）に圧をかける。

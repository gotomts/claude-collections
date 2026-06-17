# プロトタイプ段を Claude Design に置き換え（prototype-designer / prototype-builder を廃止）

Claude Design（プロンプト → HTML/CSS/JS の対話的プロトタイプ生成、Claude Code への native ハンドオフ）をプロトタイプ段の媒体に正式採用し、既存の prototype-designer（先行 27 画面仕様の手書き）と prototype-builder（HTML 手起こし）を廃止する。ハンドオフバンドルがプロトタイプ → コードの橋になり、画面仕様＝正当化トレイルが副産物として自動同梱されるため、速度とトレーサビリティが両立する。

## Status

accepted

## Considered Options

- **却下: prototype-builder（静的 HTML を手起こし）の維持**。生成が遅く、27 画面の仕様を先に書く前提が 3 週間停滞の震源だった。Claude Design が同等以上の出力を高速かつ対話的に行うため不要。
- **却下: prototype-designer（先行画面仕様）の維持**。仕様はハンドオフバンドルに機械可読 spec として自動同梱されるため、先行手書きは重複。

## Consequences

- **一方向（design → code）**。実装/技術設計でデザイン変更が要るときコード側で直すとデザイン真実源と乖離する。「デザイン変更は Claude Design に戻って再ハンドオフ」という往復規律が必要（別途 ADR で扱う）。
- **Claude Design はフロントエンド専用**。データモデル・バックエンド・アーキテクチャは tech-designer の責務として残る。ハンドオフバンドル（画面実体＋意図）はそのドメインモデリングの入力になる。
- 自律 deriver の出力＝**プロトタイプブリーフ**（Claude Design 用プロンプト）。これがハーネスの新しい中核部品。
- Claude Design は claude.ai 上の対話ツール。プロトタイプゲートの人間操作は claude.ai で行われ、ハンドオフで自動ハーネスへ復帰する（環境境界が 1 つ入るが、人間が居たい一点に一致する）。

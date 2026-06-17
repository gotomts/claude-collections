# DECISIONS.md 廃止——決定記録は inline/git/ADR、繰り越し決定は inline マーカー＋ゲート提示

ADR-0011/0016 は S1 出力に `docs/discovery/DECISIONS.md` を挙げていたが役割は未定義だった。全決定を載せる決定ログは (a) 各 corpus ページが自分の根拠を inline で持つ・(b) 変更履歴は git・(c) アーキ判断は ADR、と三重に重複する。よって **DECISIONS.md を廃止**し、決定記録を既存の3経路に委ねる。ROADMAP の合否「読める決定ログ付き」は、corpus の自己正当化＋ゲートでのディレクター提示で満たす（網羅ログ file は要求していない）。

## Status

accepted（ADR-0011 の出力レイアウトと ADR-0016 のレイアウト tree から DECISIONS.md を除く部分を supersede）

## 決定

1. **DECISIONS.md を廃止**（discovery 出力から除外）。
2. **自律判断の根拠＝担当ページに inline**。瑣末な判断は git に委ね、別ログに転記しない（AGENTS.md「git が authoritative・重複させない」と整合）。
3. **アーキ判断＝ADR**（サービス repo では S3 種まき以降・ADR-0016）。grill-with-docs の「ADR は sparingly」を守り、企画判断で ADR を埋めない。
4. **繰り越し決定**（アンカーでも導出でもない第三カテゴリ・CONTEXT）＝**所有ページに ⚠️繰り越し マーカー＋候補を inline** で記す（repo 永続なので Claude Code→claude.ai のハンドオフを跨ぐ）。ディレクターがゲートで ⚠️繰り越し マーカーを走査して提示。該当ゲート（G2 等）で人間が確定 → 所有ページに書き戻し、マーカーを外す。
5. **ゲートでのディレクター提示は2種**：①**ギャップレポート**（➖省略／⚠️未達＝完全性ガード・ADR-0011）②**繰り越し決定一覧**（⚠️繰り越し マーカー走査）。いずれもゲート時に生成する **transient な提示**で、standing な log file ではない。

## Considered Options

- **却下：全決定ログ DECISIONS.md**。inline 根拠＋git＋ADR と三重重複。「読める決定ログ」合否は corpus 自己正当化＋ゲート提示で足りる。
- **却下：繰り越し決定だけの小 register file**。所有ページの inline ⚠️マーカーで repo 永続が足り、ディレクター走査で列挙できる。別 file は二重管理。
- **却下：企画判断を ADR に統合**（バーを下げる）。ADR の希少性を失い、後続エンジニア向けの設計判断台帳がゴミ箱化する。

## Consequences

- **ADR-0011 / ADR-0016 改訂**：出力レイアウトから `DECISIONS.md` を除去（本 ADR が該当部を supersede）。
- スキル1（アンカー対話＋導出）は **DECISIONS.md を作らない**。繰り越しは inline ⚠️繰り越し マーカー、ゲート提示はディレクターが走査して生成する。
- **用語**：ゲート提示は「ギャップレポート（成果物カバレッジの欠落）」と「繰り越し決定一覧（未決の判断）」の別物2種。混同しない。

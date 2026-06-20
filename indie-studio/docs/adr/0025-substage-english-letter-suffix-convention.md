# サブステージは英字 suffix 命名規約（S1a / S1b ...）

ADR-0023 で追加した `design-direction` を `S1.5` と命名した結果、小数点記法のサブステージが harness 内に混入し、「S1.6 はあるのか」「S1.5 と S1.7 の間に何か入れるのか」型の曖昧さを抱えた。今後サブステージが増える前提（本 ADR と並行して ADR-0026 で `S1a stack-direction` を追加）で、**サブステージは英字 suffix（`S1a`, `S1b`, ...）／ alphabetic 順 = 実行順**に統一する。main stages（S1〜S5）と gates（G1〜G5）は不変。これにより ADR-0007/0013 の「5 stages × 5 gates」アイデンティティを保ったまま、小数点記法の曖昧さを取り除く。

## Status

accepted（ADR-0013 を extends。ADR-0023 の `S1.5 design-direction` を `S1b` に rename）

## 決定

1. **サブステージは英字 suffix**：main stage `S<n>` の中に挟まる autonomous なサブ工程は `S<n>a`, `S<n>b`, `S<n>c`, ... と命名する。**alphabetic 順 = 実行順**を不変条件とする。

2. **main stages / gates は不変**：S1〜S5 / G1〜G5 のフレーミング（ADR-0007/0013）は保持する。サブステージは新規ゲートを生まない（次の人間ゲートは下流の main stage の境界で発生する）。

3. **既存 `S1.5` を `S1b` に rename**：本 ADR と同時に、ADR-0026 で追加される `S1a stack-direction` を S1b の前に挿入するため、既存 `design-direction` の番号を `S1.5` → `S1b` に変更する。

4. **順序担保は documentary discipline で行う**（機械強制は orchestrator が立ち上がってから別 ADR で別途検討）：
   - **CONTEXT.md** に命名規約セクションを 1 行追加（「サブステージは英字 suffix、alphabetic 順 = 実行順」）
   - **各 SKILL.md description** に「上流＝XXX、下流＝YYY」を明示
   - **各 SKILL.md 本文**に「前提・後段」セクションで明示
   - **agent description / 本文**も同じ規約で参照
   - 規約自体は本 ADR で確定

5. **置換対象の inline 参照**：`S1.5` の literal を含む箇所を `S1b` に一括置換する。対象は SKILL.md / agent.md。ADR-0020 / 0023 の本文は ADR 群の immutable + extends 運用（indie-studio のドキュメント規律）により**触らない**（本 ADR が extends 関係を持つ）。

## Considered Options

- **却下：整数連番シフト**（G1 → S1 service-discovery → S2 stack-direction → S3 design-direction → S4 prototype → S5 tech-design → S6 decomposition → S7 implementation）。曖昧さは消えるが「5 stages × 5 gates」アイデンティティが崩れ、ADR-0007/0013 を extends する新 ADR で再定義が必要。影響範囲は 40 ファイル / ~273 箇所と巨大。indie-studio の identity を再構築するコストが、得られる明快さを上回る。

- **却下：decimal 据え置き**（S1.5 / S1.7 / 必要なら S1.6 を後付け）。「S1.6 はあるのか」「S1.5 と S1.7 の間に何か入れるのか」の曖昧さが残る。サブステージが追加されるたび小数点の隙間問題が再発する。

- **却下：numeric subindex（S1-1, S1-2）**。alphabetic と比較して桁数が増えるだけで明快さは同等。`S1-10` まで増えた場合の sort 順問題（lexicographic では `S1-10` < `S1-2`）を持つ。

- **採用：英字 suffix（S1a, S1b, ...）**。alphabetic 順は自明で曖昧さがない。lexicographic sort で実行順と一致する。サブステージ追加コストが最小。5×5 framing が保たれる。

## Consequences

- **ADR-0013 を extends**：共通ステージ形の枠組みは不変、サブステージの命名規約だけ確定。
- **ADR-0023 の `S1.5 design-direction` を `S1b` に rename**：ADR-0023 本文は触らず、本 ADR で extends 関係を持つ。後続 ADR / SKILL.md は `S1b` を正規参照名とする。
- **CONTEXT.md 更新**：「サブステージは英字 suffix、alphabetic 順 = 実行順」を 1 行追加（用語語彙ではなく規約節として配置）。
- **SKILL.md 一括置換**：`indie-studio/skills/service-discovery/SKILL.md`、`indie-studio/skills/design-direction/SKILL.md` の `S1.5` を `S1b` に置換。description / 本文の「上流＝、下流＝」表記を追加。
- **agent.md 一括置換**：`indie-studio/agents/product-designer.md`、`indie-studio/agents/visual-designer.md` の `S1.5` を `S1b` に置換。
- **将来サブステージ追加時の規約**：新規サブステージは**末尾の英字を進めて命名**する（既存 `a, b, c, ...` の連続性を保つ）。**既存のサブステージ間に挿入する場合は、後続の英字を順送り rename する**（`alphabetic = 実行順` の不変条件を維持するため。rename コストは documentary discipline の連鎖更新で吸収する。`grep` で literal 一括置換が可能）。orchestrator 立ち上げ後に機械可読 metadata で順序を表現する案が立てば、本 ADR を extends する別 ADR で運用を緩めうる。
- **影響範囲は documentary**：実行制御に変更なし（orchestrator 未実装のため、現状の human handoff 境界での起動規律は不変）。

## 未確定

- **frontmatter への `stage` / `requires` / `precedes` 機械可読フィールド追加**：orchestrator が立ち上がるタイミングで別 ADR で検討。先に投機的に入れると orchestrator の要求 schema と齟齬が出るため見送り。

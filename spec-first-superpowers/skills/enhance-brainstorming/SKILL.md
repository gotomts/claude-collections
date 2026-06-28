---
name: enhance-brainstorming
description: |
  spec-first-superpowers コレクションの起点 skill。superpowers:brainstorming + writing-plans を内部 invoke し、
  Spec フェーズで 5 成果物 (summary / design / plan / gwt / pr-description) を summary-first 順序で確定。
  各 Phase で specialist agent (software-architect / qa-engineer / security-engineer) を能動 dispatch、
  dispatch log は 5 成果物のレビュー履歴セクションに追記 (ADR-0007)。
  Phase 3 で機微情報チェック (ADR-0008)、Phase 4 でライセンスチェック (ADR-0009) を組み込む。
  Step 1 で .ai-restrictions.md を Read して AI 利用ポリシーを案内 (ADR-0010)。
  後工程 (gwt-test / write-review-response / finish-spec-pr) を連鎖駆動。
argument-hint: "[topic]  # 開発したい機能 / 課題のキーワード (任意、省略時は会話で詰める)"
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - Skill
maintainer: gotomts
---

# enhance-brainstorming

spec-first-superpowers コレクションの起点 skill。ユーザーが意識的に呼ぶ唯一の skill。superpowers:brainstorming の責任を拡張し、5 成果物の Spec フェーズ確定 + 後工程連鎖駆動を担う。

## 動作 (9 ステップ)

### Step 1: 前提確認 + AI 利用ポリシー案内 (ADR-0010)

1. `git rev-parse --show-toplevel` で git repo を確認、失敗なら error 中断
2. `git rev-parse --abbrev-ref HEAD` で現ブランチ取得 → サニタイズ (`/` → `-`)
3. `docs/superpowers/{branch}/` ディレクトリを作成 (commit 前提、worktree 退避なし)
4. **プロジェクトルートの `.ai-restrictions.md` を Read** (存在すれば内容を user に案内、無ければ skip)

### Step 2: Phase 1 — 会話で問題理解 + 2-3 アプローチ提示

1. user の topic (argument 経由 or 会話で取得) から議論を開始
2. 1 ターン 1 問の質問で要件・制約・成功基準を詰める
3. 2-3 アプローチを推奨案 + メリデメで提示
4. `software-architect` を能動 dispatch (ADR-0005) — アプローチ案の Clean Architecture + SOLID 整合性レビュー
5. dispatch log (時刻 / agent / 目的 / 回答要約) を保持 (Phase 2 の summary.md に追記する)

### Step 3: Phase 2 — summary.md 生成 (認識齟齬検出 ①)

1. user 合意済みアプローチを base に、`spec-first-superpowers/templates/summary.md` を Read
2. テンプレのプレースホルダー (`{機能名}` / `{slug}` / `{方式 1}` 等) を埋めて summary.md を生成
3. ファイル名: `{YYYY-MM-DD}-{slug}-summary.md`、配置: `docs/superpowers/{branch}/`
4. frontmatter の `design: ./{date}-{slug}-design.md` を先行記載 (実 design.md は Phase 3 で生成)
5. `software-architect` を能動 dispatch — 方式の要点 / 効いている設計判断を SOLID/YAGNI 観点でレビュー
6. **summary.md 末尾「## レビュー履歴」セクションに Phase 1 + Phase 2 の dispatch log を追記** (ADR-0007)
7. user 承認 → commit (Conventional Commits 形式)

### Step 4: Phase 3 — design.md 生成 + セキュリティレビュー + 機微情報チェック

1. 合意済み summary.md を context として `superpowers:brainstorming` を invoke (Y 方式 / ADR-0006)
2. superpowers:brainstorming に「以下が合意済み summary、design.md として詳細展開して」と委譲
3. design.md が生成されたら、`software-architect` を能動 dispatch — design 全体の SOLID / モジュール境界レビュー
4. 続けて `security-engineer` を **常時能動 dispatch** — design のセキュリティレビュー (認証 / 認可 / データ取扱 / 外部入力 / シークレット / 通信 / コード実行 等の観点)
5. **機微情報チェックリスト** (ADR-0008): 個人情報 / 決済データ / 医療データ / 認証情報を扱う設計か? 該当したら適用規制 (GDPR / 個人情報保護法 / PCI-DSS / HIPAA 等) を提示 → user に「適用規制を確認の上、本 PR スコープで対応 / 別 PR / Skip のいずれかを判断してください」と促す
6. design.md 末尾「## レビュー履歴」セクションに Phase 3 の dispatch log を追記 (機微情報チェック結果含む)
7. user 承認 → commit

### Step 5: Phase 4 — plan.md 生成 + ライセンスチェック

1. `superpowers:writing-plans` を invoke
2. plan.md が生成されたら、`qa-engineer` を能動 dispatch — plan のテスト戦略の段取り妥当性レビュー
3. 続けて `security-engineer` を **常時能動 dispatch** — plan のセキュリティ観点 (セキュリティテスト / 脅威モデリングの段取り / 機微データ取扱の手順) レビュー
4. **ライセンスチェック** (ADR-0009): plan で追加予定の依存ライブラリ一覧を抽出、各ライブラリのライセンスを確認 (license-checker 等を推奨案内)、制限ライセンス (GPL / AGPL / SSPL / 商用制限) が含まれる場合は user に警告 + 1 問確認
5. plan.md 末尾「## レビュー履歴」セクションに dispatch log を追記
6. user 承認 → commit

### Step 6: Phase 5 — gwt.md 生成 (認識齟齬検出 ②)

1. `spec-first-superpowers/templates/gwt.md` を Read
2. design + plan の内容から AC (Given-When-Then 形式) を生成
3. `qa-engineer` を能動 dispatch — AC の網羅性 (異常系 / 境界値 / 空状態) レビュー
4. gwt.md 末尾「## レビュー履歴」セクションに dispatch log を追記
5. user 承認 → commit

### Step 7: Phase 6 — pr-description.md 生成 (認識齟齬検出 ③)

1. `spec-first-superpowers/templates/pr-description.md` を Read
2. 「## やったこと」を plan.md 由来の計画スコープで下書き、「## 補足」を既知の判断理由で下書き、「## 動作確認方法」を gwt.md の AC を base に user 確認しながら確定
3. **pr-description はレビュー履歴セクションを追加しない** (B 例外、ADR-0007、最小構造維持のため)
4. user 承認 → commit

### Step 8: Phase 1 / 2 / 5 / 6 の任意セキュリティ dispatch

各 Phase でセキュリティ箇所が検出されたら `security-engineer` を任意 dispatch (Phase 3/4 の常時 dispatch とは別)。dispatch log は該当 Phase の成果物 (summary / gwt) のレビュー履歴に追記。

### Step 9: STOP POINT 1 (実装フェーズ) の案内

1. user に「Spec フェーズが完了しました。次は実装です」と明示
2. **実装中の推奨 agent 利用パターンを案内**:
   - 実装方針が大きく変わるとき → `software-architect` を dispatch
   - コード書く前後でレビューが要るとき → `code-reviewer` を dispatch
   - セキュリティ箇所を実装するとき → `security-engineer` を dispatch
3. 実装完了後の再開方法を案内: 「(a) enhance-brainstorming を再 invoke (状態判定して続きから)、または (b) `gwt-test` skill を直接 invoke」

## 規律明示

- 5 成果物の命名: `{YYYY-MM-DD}-{slug}-{suffix}.md`、配置: `docs/superpowers/{branch}/`
- 設計思想: Clean Architecture + Modular Monolith / YAGNI/DRY/KISS/SOLID / SOLID 最優先 / テスト DRY 一部許容
- コードコメント方針: WHY のみ、JSDoc 抑制
- pr-description Spec フェーズ先行作成の意義 (動作確認方法を Spec で確定 = 認識齟齬を実装後に検出する手戻りを防ぐ)
- 各 Phase で agent を能動 dispatch (silent failure 回避、取り込むだけで使わない pattern を作らない)
- agent dispatch log は該当 5 成果物の「## レビュー履歴」セクションに必ず追記 (ADR-0007)
- Phase 3 で機微情報チェックリスト + 適用規制 trigger を提示 (ADR-0008)
- Phase 4 で依存ライブラリのライセンスチェックを実施 (ADR-0009)
- Step 1 で `.ai-restrictions.md` を Read して AI 利用ポリシーを案内 (ADR-0010、ファイル無ければスキップ)

## 失敗時の挙動

| 状況 | 挙動 |
|---|---|
| git repo 外 | error 報告 + 中断 (Step 1 で検知) |
| Phase 1 で情報不足 | 1 問ずつ追加質問 → 情報揃ったら Phase 2 へ |
| Phase 2 で大枠ズレ発覚 | Phase 1 に戻って再議論 → summary 書き直して再合意 |
| Phase 3 で superpowers:brainstorming が summary context を無視して会話を再開 | 「合意済みです」を再伝達 → なお続行なら受け入れる。dogfood で運用上の問題があれば Z 方式 (自前実装) に移行 (ADR-0006 を update) |
| 5 成果物の整合性チェックで矛盾発覚 | 矛盾点を user に提示 → 修正対象 1 問確認 → 修正 → 再提示 |

## 関連

- ADR-0001 (collection-scope-and-naming)
- ADR-0002 (five-deliverables-and-order)
- ADR-0003 (skill-chain-and-stop-points)
- ADR-0005 (agent-vendoring)
- ADR-0006 (superpowers-brainstorming-context-delegation, Y 方式)
- ADR-0007 (audit-trail-dispatch-log)
- ADR-0008 (sensitive-data-check-in-spec-phase)
- ADR-0009 (license-check-in-plan-phase)
- ADR-0010 (ai-utilization-policy-loading)
- CONTEXT.md (ユビキタス言語、indie-studio 禁止語彙)

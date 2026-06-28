---
name: gwt-test
description: |
  enhance-brainstorming で生成された gwt.md の AC (受け入れ条件) を agent-browser で検証し、
  チェックリスト更新 + 変更履歴追記する skill。dev server / docker は AI が起動・停止する。
  AC 未達発覚時は qa-engineer を能動 dispatch して差し戻し findings を言語化。
  STOP POINT 2 (code-review skill 手動実行 + security-engineer による security-focused
  コードレビュー) を user に案内。
  Step 1 で .ai-restrictions.md を Read (ADR-0010)。
argument-hint: "[gwt-file-path]  # 検証対象 gwt.md のパス (省略時は docs/superpowers/{branch}/ から自動検出)"
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

# gwt-test

実装完了後に呼び出し、gwt.md の AC を実機 (agent-browser) で検証する skill。enhance-brainstorming からの連鎖、または user が直接 invoke のどちらでも動作。

## 動作 (7 ステップ)

### Step 1: 前提確認 + AI 利用ポリシー案内 (ADR-0010)

1. `git rev-parse --show-toplevel` で git repo 確認、失敗なら error 中断
2. プロジェクトルートの README.md を Read (テストアカウント / 起動コマンド / 前提サービス把握)
3. プロジェクトルートの `.ai-restrictions.md` を Read (存在すれば user に案内)
4. argument 経由 or `docs/superpowers/{branch}/*-gwt.md` から検証対象 gwt.md を確定

### Step 2: dev server / docker 起動

1. README から起動コマンドを把握 (例: `npm run dev` / `docker compose up -d`)
2. 起動前に `lsof -i :<port>` / `docker ps` で重複確認 → 重複あれば user に 1 問確認 ("既存プロセスを停止しますか? / 別 port で起動しますか?")
3. AI が起動 (バックグラウンド可、PID 控える)
4. 起動失敗時 (port 占有 / README 不在等) は error 報告 + 中断 ("手動起動してから再 invoke してください")

### Step 3: agent-browser で AC 検証 (フォールバック chrome-devtools-mcp)

1. gwt.md の AC-1 / AC-2 / AC-E1 等を順次検証
2. **第一選択**: `agent-browser` skill で実 UI を操作
3. **フォールバック**: agent-browser のスコープ外 (Network 計測 / Performance プロファイリング / Lighthouse 等) なら `chrome-devtools-mcp` を user に 1 問確認 (未導入なら install 是非も 1 問確認)
4. 独自 headless browser (playwright / puppeteer 等) は立てない、両方不可なら user に相談

### Step 4: AC 達成判定 + チェックリスト更新

1. 各 AC が満たされたら gwt.md のチェックリスト `- [ ] AC-N: ...` → `- [x] AC-N: ...` に書き換え
2. 全 AC 達成 → Step 6 へ
3. AC 未達あり → Step 5 へ

### Step 5: AC 未達発覚時 (qa-engineer 能動 dispatch)

1. `qa-engineer` を能動 dispatch — 差し戻し findings の言語化 + テストコード同期確認
2. `gwt.md` の変更履歴 (逆時系列) に追記: `{YYYY-MM-DD}: {対象AC} — {変更内容}（{変更理由・関連 issue / PR}）`
3. gwt.md 末尾「## レビュー履歴」セクションに dispatch log を追記 (ADR-0007)
4. user に「AC 未達につき実装に差し戻します」と提示 → user 1 問確認 → 実装フェーズに戻る (STOP POINT 1 相当)

### Step 6: dev server / docker 停止

1. Step 2 で起動した PID / コンテナを停止 (`kill <PID>` / `docker compose down` / `docker stop <container>`)
2. `lsof -i :<port>` / `docker ps` で残存していないことを確認
3. 失敗時は user に PID + コマンドを通知 (cleanup を促す)

### Step 7: STOP POINT 2 (code-review skill + security-engineer) の案内

1. user に「テストフェーズが完了しました。次はセルフレビューです」と明示
2. **STOP POINT 2 案内 (必ず両方を含める)**:
   - `code-review` skill を user が手動 invoke (CodeRabbit の機械的レビュー)
   - `security-engineer` を能動 dispatch して security-focused なコードレビューを 1 回実施 (security-engineer dispatch 結果は write-review-response 内で review-response.md のレビュー履歴に追記)
3. 完了後の再開方法を案内: 「(a) enhance-brainstorming を再 invoke、または (b) `write-review-response` skill を直接 invoke」

## 規律明示

- agent-browser → chrome-devtools-mcp → 相談 の優先順序
- 実装修正 → テストコード同期確認 (不要時も 1 行根拠を残す)
- AC 未達発覚時は qa-engineer 能動 dispatch (自己判断で済まさず職種境界に通す)
- STOP POINT 2 案内に security-engineer によるコードセキュリティレビューを必ず含める
- dispatch log を gwt.md / review-response.md のレビュー履歴セクションに追記 (ADR-0007)
- dev server / docker は AI が起動 + 必ず停止 (放置禁止)
- Step 1 で AI 利用ポリシー (.ai-restrictions.md) を Read して案内 (ADR-0010)

## 失敗時の挙動

| 状況 | 挙動 |
|---|---|
| README 不在 / 起動コマンド不明 | error 報告 + 中断 ("手動起動してから再 invoke") |
| port 占有 | `lsof -i :<port>` 提示 → 既存停止 or 別 port 指定を 1 問確認 |
| agent-browser が対象機能非対応 | chrome-devtools-mcp 使用是非を 1 問確認 → 未導入なら install 是非も 1 問確認 |
| AC 未達 | qa-engineer dispatch → gwt.md 変更履歴追記 → 実装差し戻し提案 → user 1 問確認 |
| 異常終了で dev server / docker 停止漏れ | cleanup ロジックで停止試行、失敗時は PID + コマンドを user に通知 |

## 関連

- ADR-0001 (collection-scope-and-naming, STOP POINT 2 のセキュリティレビュー 2 層)
- ADR-0007 (audit-trail-dispatch-log)
- ADR-0010 (ai-utilization-policy-loading)
- enhance-brainstorming SKILL.md (起点 skill)
- write-review-response SKILL.md (次工程 sub-skill)

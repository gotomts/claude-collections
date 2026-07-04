---
name: gwt-test
description: |
  enhance-brainstorming で生成された gwt.md の AC (受け入れ条件) を agent-browser で検証し、
  チェックリスト更新 + 変更履歴追記する skill。dev server / docker は AI が起動・停止する。
  Step 0 で状態判定 (ADR-0012)、AC 検証完了時は qa-engineer を常時能動 dispatch (網羅性 review、ADR-0013)。
  AC 未達発覚時も qa-engineer を能動 dispatch して差し戻し findings を言語化。
  STOP POINT 2 は code-review skill を auto-invoke (課金前 1 問確認、ADR-0013) + security-engineer 能動 dispatch。
  Step 1 で .ai-restrictions.md を Read (ADR-0010)。完了後は write-review-response skill に chain。
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

実装完了後に呼び出し、gwt.md の AC を実機 (agent-browser) で検証する skill。enhance-brainstorming / enhance-executing-plans からの連鎖、または user が直接 invoke のどちらでも動作。

## Phase 定義 (ADR-0012 D3)

| Phase | 前提 file | 出力 | 出力条件 |
|---|---|---|---|
| 0 | `docs/superpowers/{branch}/*-gwt.md` 存在 | (判定) | 状態判定完了、Step 番号を確定 |
| 検証 | gwt.md + 実装済コード | gwt.md checklist 更新 (`- [ ]` → `- [x]`) | 各 AC を agent-browser で検証 |
| 網羅性 review | gwt.md checklist 全 [x] | gwt.md レビュー履歴に qa-engineer log 追記 | qa-engineer が網羅性 OK と判定 (ADR-0013) |
| セルフレビュー | 実装済コード | review-response.md への dispatch log 引継ぎ | code-review skill auto-invoke 完了 + security-engineer dispatch 完了 |

## 動作 (9 ステップ)

### Step 0: 状態判定 (ADR-0012 D2)

1. `git rev-parse --abbrev-ref HEAD` で現ブランチ取得、サニタイズ (`/` → `-`)
2. `docs/superpowers/{branch}/` を Glob で列挙、`gwt.md` の存在有無を確認
3. **前提**: `*-gwt.md` が存在すること。無ければ error "gwt.md がありません。enhance-brainstorming Phase 3 を完了させてください" + 中断
4. gwt.md の checklist 状態を確認:
   - checklist 全 `- [ ]` → Step 1 (初回検証) から
   - checklist 一部 `- [x]` → Step 3 (未検証 AC のみ検証) から
   - checklist 全 `- [x]`、レビュー履歴に「AC 完了時 qa-engineer dispatch」ログ有 → Step 8 (STOP POINT 2) から
5. `handoff.md` が同ディレクトリにあれば Read (補助情報)
6. 判定結果を user に「現在 Phase = X、Step Y から再開します」と明示、user 1 問確認

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
2. 全 AC 達成 → Step 6 (AC 完了時 qa-engineer 常時 dispatch) へ
3. AC 未達あり → Step 5 (AC 未達時 qa-engineer) へ

### Step 5: AC 未達時 qa-engineer 能動 dispatch

1. `qa-engineer` を能動 dispatch — 差し戻し findings の言語化 + テストコード同期確認
2. `gwt.md` の変更履歴 (逆時系列) に追記: `{YYYY-MM-DD}: {対象AC} — {変更内容}（{変更理由・関連 issue / PR}）`
3. gwt.md 末尾「## レビュー履歴」セクションに dispatch log を追記 (ADR-0007)
4. user に「AC 未達につき実装に差し戻します」と提示 → user 1 問確認 → 実装フェーズに戻る (`enhance-executing-plans` skill に chain、または直接 STOP POINT 1 に戻す)

### Step 6: AC 検証完了時 qa-engineer 常時能動 dispatch (ADR-0013 D1)

全 AC 達成後、silent failure 回避のため以下を実行:

1. `qa-engineer` を **常時能動 dispatch** — AC 網羅性 (異常系 / 境界値 / 空状態 / seasonality 等) の review、抜けたシナリオの検出
2. dispatch log を gwt.md 末尾「## レビュー履歴」セクションに追記 (ADR-0007)
3. qa-engineer が「抜けたシナリオあり」と判定した場合、user に 1 問確認 → gwt.md の AC 追加 → Step 3 (再検証) へ戻る
4. 網羅性 OK → Step 7 (dev/docker 停止) へ

### Step 7: dev server / docker 停止

1. Step 2 で起動した PID / コンテナを停止 (`kill <PID>` / `docker compose down` / `docker stop <container>`)
2. `lsof -i :<port>` / `docker ps` で残存していないことを確認
3. 失敗時は user に PID + コマンドを通知 (cleanup を促す)

### Step 8: STOP POINT 2 = code-review skill auto-invoke + security-engineer 能動 dispatch (ADR-0013 D2)

1. user に「テストフェーズが完了しました。次はセルフレビューです」と明示
2. **code-review skill 課金前 1 問確認** (ADR-0013 D2、M4 fix 2026-07-04: **scope は code-review のみ**、security-engineer と write-review-response chain は独立):
   - 「code-review skill (CodeRabbit) を自動 invoke します、続けてよいですか? user account に課金されます」を user に提示
   - yes → 3 へ / no → 3 を skip、gwt.md レビュー履歴に「STOP POINT 2 で code-review skip (user 選択、user 手動 invoke へ委譲)」を追記して 4 へ (silent failure 回避のため security-engineer + write-review-response chain は必ず実行)
3. `Skill` tool で `code-review` skill を **auto-invoke** (CodeRabbit の機械的レビュー、ADR-0013 D2)
4. **`security-engineer` を能動 dispatch** (評価 mode、Step 2 の yes/no と独立、必ず実行) — security-focused なコードレビューを 1 回実施 (silent failure 回避、ADR-0013 D2 scope)
5. dispatch log は write-review-response 内で review-response.md のレビュー履歴に集約されるが、gwt-test 内でも「STOP POINT 2 実行完了 (code-review = {実行 / skip}、security-engineer = 実行)」を gwt.md レビュー履歴に追記 (再開判定 hint)
6. `Skill` tool で `write-review-response` skill を chain invoke (常に実行、silent failure 回避)

## 規律明示

- Step 0 状態判定で再開可能な skill 設計 (ADR-0012 D2)、SKILL.md 冒頭の Phase 定義 table を再開判定の仕様源 (ADR-0012 D3)
- agent-browser → chrome-devtools-mcp → 相談 の優先順序
- 実装修正 → テストコード同期確認 (不要時も 1 行根拠を残す)
- AC 未達発覚時 + AC 完了時、両方で qa-engineer を能動 dispatch (silent failure 回避、ADR-0013)
- STOP POINT 2 の code-review skill は **auto-invoke** (課金前 1 問確認)、user 手動依存を廃止 (ADR-0013)
- security-engineer は STOP POINT 2 で必ず能動 dispatch (code-review skill の機械的レビューを補完)
- dispatch log を gwt.md / review-response.md のレビュー履歴セクションに追記 (ADR-0007)
- dev server / docker は AI が起動 + 必ず停止 (放置禁止)
- Step 1 で AI 利用ポリシー (.ai-restrictions.md) を Read して案内 (ADR-0010)

## 失敗時の挙動

| 状況 | 挙動 |
|---|---|
| gwt.md 未生成 | error 報告 + 中断 (Step 0 で検知、"enhance-brainstorming Phase 3 を完了させてください") |
| README 不在 / 起動コマンド不明 | error 報告 + 中断 ("手動起動してから再 invoke") |
| port 占有 | `lsof -i :<port>` 提示 → 既存停止 or 別 port 指定を 1 問確認 |
| agent-browser が対象機能非対応 | chrome-devtools-mcp 使用是非を 1 問確認 → 未導入なら install 是非も 1 問確認 |
| AC 未達 | qa-engineer dispatch → gwt.md 変更履歴追記 → 実装差し戻し提案 → user 1 問確認 |
| Step 6 で qa-engineer が抜けシナリオ検出 | user 承認後 gwt.md AC 追加 → Step 3 再検証 |
| Step 8 で code-review skill 課金確認 no | code-review skip して security-engineer のみ dispatch、user に手動 invoke を残す |
| 異常終了で dev server / docker 停止漏れ | cleanup ロジックで停止試行、失敗時は PID + コマンドを user に通知 |

## 関連

- ADR-0001 (collection-scope-and-naming, STOP POINT 2 のセキュリティレビュー 2 層)
- ADR-0003 (skill-chain-and-stop-points — Superseded by ADR-0012)
- ADR-0007 (audit-trail-dispatch-log)
- ADR-0010 (ai-utilization-policy-loading)
- ADR-0012 (implementation-phase-skill-and-state-detection) — Step 0 状態判定
- ADR-0013 (gwt-test-qa-engineer-always-dispatch-and-code-review-auto-invoke) — Step 6 と Step 8 の agent 強制
- enhance-brainstorming SKILL.md (起点 skill)
- enhance-executing-plans SKILL.md (前工程 skill、実装完了で本 skill に chain)
- write-review-response SKILL.md (次工程 sub-skill)

## やったこと

- `claude-collections` repo に `spec-first-superpowers` コレクションを新設 (indie-studio と並列の plugin collection)
- 4 skill 実装: `enhance-brainstorming` (起点) / `gwt-test` / `write-review-response` / `finish-spec-pr`
- agent vendoring: `shared/agents/` から 4 体 (code-reviewer / qa-engineer / software-architect / security-engineer) を `make sync` で取り込み
- shared/skills/finish-stage-pr に body-source-path 引数を追加する後方互換改修 (ADR-0004)
- templates 4 種 (summary / gwt / pr-description / review-response) を spec-first-superpowers/templates/ に同梱
- ADR 0001-0010 を起草 (設計判断系 6 + 追加機能系 4)
- root .claude-plugin/marketplace.json に entry 追加、CONTEXT-MAP.md に索引追加
- 5 成果物の生成順を summary-first に変更 (ADR-0002)、Spec フェーズで認識齟齬検出を 3 重に分散
- agent 能動 dispatch を各 skill ステップに織り込み (Agent dispatch matrix、ADR-0005 関連)
- セキュリティレビュー 2 層 (設計 = Phase 3/4 + コード = STOP POINT 2)
- 監査ログ: agent dispatch log を 5 成果物のレビュー履歴セクションに集約 (ADR-0007)
- コンプライアンス 3 項目: 機微情報チェック (ADR-0008) + ライセンスチェック (ADR-0009) + AI 利用ポリシー案内 (ADR-0010)

## 補足

- 本 PR は spec-first-superpowers コレクションの初リリース。indie-studio のような 5 ステージ × 5 ゲート × 多職種 director モデルとは思想が異なる (superpowers の直線フローを尊重)、用途で棲み分ける
- enhance-brainstorming Phase 3 の Y 方式 (summary context を superpowers:brainstorming に委譲) は dogfood で運用上機能しない場合、Z 方式 (自前実装) に移行する余地を ADR-0006 に明記
- コンプライアンス 3 項目は本コレクションでは「trigger / 案内のみで強制しない」薄い設計。具体的な規制チェック / ライセンス互換性検証 / AI 利用制約強制は外部ツールに委ねる (環境依存)
- shared/skills/finish-stage-pr の改修は後方互換、indie-studio 側の挙動は変えていない (Task 4.5 の follow-up commit で indie-studio 側 vendored copy を再 sync して make verify exit 0 を確認済み)
- 本 PR の実装は `superpowers:subagent-driven-development` ハーネスで進行: 11 task 全てが per-task review で Approved、`.superpowers/sdd/progress.md` ledger に進捗を永続化
- final whole-branch review (opus) の Important 2 件を反映済み (commit 942ea10) — Critical 0、残 Minor 2 件 (失敗時挙動 table の polish と vendored shared/skills の ADR-0031 参照) は follow-up
- **既知制約 (ADR-0005 Consequences に明記)**: vendored agents (`spec-first-superpowers/agents/*.md`) は `shared/agents/` から取り込んだ body をそのまま持つため、indie-studio 由来の語彙 (S1〜S5 / ハーネス / docs/indie-studio パス等) が混在する。これは generated file 手編集禁止ルールを優先した結果の構造的副作用で、CONTEXT.md の禁止語彙と衝突する。解決策 (shared/agents/ 中立化 / sync 語彙置換 / agents ハンドメイド化) は別 PR の follow-up issue でトラッキング

## 動作確認方法

1. リポジトリを worktree でチェックアウトして本 PR ブランチを取得
2. `make sync COLLECTION=spec-first-superpowers` を実行して agents/skills が正しく取り込まれることを確認
3. `make verify` で drift なし (exit code 0) を確認
4. Claude Code 上で `/spec-first-superpowers:enhance-brainstorming <topic>` を呼んで以下を確認:
   - Step 1 で `.ai-restrictions.md` (テスト用に作成) が読まれて案内が出る
   - Phase 1 で `software-architect` agent が能動 dispatch される
   - Phase 2 で summary.md が summary-first 順序で生成される、dispatch log が「## レビュー履歴」セクションに追記される
   - Phase 3 で `superpowers:brainstorming` が summary context を context として design.md を生成 (Y 方式)、`security-engineer` が機微情報チェックリストを提示
   - Phase 4 で `superpowers:writing-plans` が plan.md を生成、`security-engineer` が依存ライブラリのライセンスチェックを実施
   - Phase 5 で `qa-engineer` が AC レビュー
   - Phase 6 で pr-description.md が生成される
5. 別途 indie-studio の任意 skill を動かして finish-stage-pr の default 動作 (内蔵テンプレ) が壊れていないことを確認 (後方互換確認)
6. 本 PR の merge 後、release-drafter の draft が自動更新されることを確認 (既存 release-drafter 運用との整合)

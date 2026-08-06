# 0017. レビュワー側 skill `pr-review` の新設 + 子セッション 2 本の並走

## Status

Accepted (2026-08-03)。番号は 2026-08-06 に 0016 から 0017 へ繰り上げた ([ADR-0016](0016-local-review-to-implementation-reviewer-and-builtin-review-after-pr.md) が先に main へ入り 0016 を取ったため。`AGENTS.md`「既に存在する ADR の renumber は行わない」の対象は**公開済みの番号**であり、本 ADR は未 merge のため参照が repo 内に閉じている)。

## Context

本コレクションの既存 5 skill (`enhance-brainstorming` / `enhance-executing-plans` / `gwt-test` / `write-review-response` / `finish-spec-pr`) は、**全て implementer 側**に立っている — 自分がこれから書くコードの Spec を先に決め、実装し、テストし、セルフレビューを受け、PR を出す。`write-review-response` ですら「自分の PR に付いたレビュー指摘に応答する」側であり、向きは implementer のままである。

一方で、**自分がレビュワーとして他人の PR を受け取る**場面は上記のどの skill でも扱えない。この場面固有の困りごとは 3 つある:

1. **把握コストが先に来る**: implementer は設計を決めてから書くので理解が先にあるが、レビュワーは完成した差分から設計意図を逆算する必要がある
2. **動作確認の土台が無い**: PR に受入条件が書かれていても、それは「作者の主張」であって「レビュワーの理解が正しいか」を反証する形になっていない
3. **動作確認とコードレビューが逐次になる**: `gwt-test` は test → STOP POINT 2 (review) の逐次で、レビュワーの実作業 (動かしながら読む) と噛み合わない

既存 `gwt-test` の流用は成立しない。`gwt-test` の gwt.md は Spec フェーズで**先に**書かれたものを読む前提であり、レビュワー側では gwt.md がまだ存在しない (差分から起こす必要がある)。gwt.md の出所が逆転している以上、同じ skill には収まらない。

## Decision

### D1: レビュワー側 skill `pr-review` を新設する

`enhance-superpowers/skills/pr-review/SKILL.md` を追加する。責務は「レビュー対象の把握 (summary) → 動作確認の土台作り (gwt) → 人間レビュー → 動作確認とコードレビューの並走 → join」。

命名はプレーン名とした。既存の `enhance-*` 接頭辞は「公式 superpowers skill のラッパー」を意味する (`enhance-brainstorming` = `superpowers:brainstorming` の拡張) が、本 skill に対応する公式 skill は存在しない。独自 skill である `gwt-test` / `write-review-response` / `finish-spec-pr` と同じくプレーン名が整合する。

`review-pr-spec` は採らなかった: 成果物名 (summary/gwt = Spec) を冠すると、本 skill が持つ「並走検証 + join」まで含んだ範囲を過小に見せる。`reviewing-pr` の動名詞形も採らなかった: 既存 5 skill に動名詞形が無く、コレクション内で浮く。

`write-review-response` と向きが紛らわしい問題は、description 冒頭に「レビュワー側」と明示することで扱う (skill 選択は description で行われるため実害が出ない)。

### D2: レビュー対象は PR 番号を引数で受け取る

`<pr-number>` を必須引数とし、skill 側が `git fetch origin pull/<N>/head` → `herdr worktree create --branch review/pr-<N> --base FETCH_HEAD` でレビュー用 worktree を作る。

「checkout 済みブランチの diff を見る」形は採らなかった: レビュワーの実際の入り口は GitHub 上の PR であり、先に自分で checkout する手順を要求すると skill の外に前作業が漏れる。

PR 作者のブランチ名をそのまま checkout せず `review/pr-<N>` を切るのは、レビュー中の実験的コミットが作者側ブランチに混ざる事故を防ぐため。`pull/<N>/head` を fetch source にすることで fork 由来の PR でも同じ手順が通る。

### D3: 子セッション 2 本を同一 worktree・タブ 2 枚で並走させる

Step 1 で作った workspace に `herdr tab create` でタブを 2 枚足し、それぞれに `herdr agent start --kind claude` で子を立てる。

- `pr<N>-verify` — gwt.md を元に agent-browser で動作確認。書き込みは **gwt.md のみ**
- `pr<N>-review` — 差分のコードレビュー。書き込みは **review-report.md のみ**

worktree を 2 つに分ける案は採らなかった: 同一ブランチは 2 重 checkout できず片方を `--detach` にする必要があり、加えて依存インストール 2 回分と dev server の port 競合コストがかかる。レビューは本質的に read-only であり、このコストが見合わない。

同一 worktree 共有が成立する条件は「**両者ともコードを書かない**」ことである。書き込み先が上記のとおり分離されている限り衝突しない。この条件が崩れると git の index.lock 競合が起きるため、両子への初回プロンプトで「ファイルを修正しない」「git commit / push しない」を明示的に禁じる。

片方 (コードレビュー) を親セッション内の subagent にする案も採らなかった: 動作確認とコードレビューは所要時間が大きく異なり、親が subagent を抱えると巡回して blocked に回答する役が居なくなる。

### D4: 成果物は発動元リポジトリに置き、commit しない

`{出力先}` の既定を**発動元リポジトリ**の `docs/superpowers/pr-{N}/` とする (`--output-dir` で上書き可)。レビュー用 worktree には置かない。

理由は 2 つ:

- レビュー用 worktree は使い捨てであり、成果物を置くと片付けと同時に消える
- 他人の PR ブランチにレビューメモを commit する事故を構造的に防ぐ

生成物は untracked のまま残す。本コレクションの既定方針「コミット前提: 設計ドキュメントは worktree 同居・main 退避なし」(CONTEXT.md) は implementer 側の成果物についての決定であり、**レビュワーが他人の PR に対して書いたメモには適用しない**。

### D5: crit を唯一の承認ゲートにする

summary.md + gwt.md が揃った時点で `crit <summary> <gwt>` を起動し、人間が行単位でコメントを付ける。反映後 `crit comments --json` で unresolved が 0 になったことを確認してから子セッションを起動する。

user 承認 1 問 (既存 skill の様式) を採らなかった: summary はレビュワー自身の理解を書いたものであり、ズレは「どの行の記述が違うか」という粒度で出る。yes/no の 1 問ではその粒度を拾えない。理解がズレたまま子 2 本を走らせると 2 本分の作業がまるごと無駄になるため、ここだけは行単位のレビューに投資する価値がある。

crit にコメントが 0 件だった場合は「指摘なしで承認」とみなしてよいか 1 問確認する。crit を開かずに閉じた事故と区別が付かないため。

## Consequences

- **レビュワー側の作業がコレクションに入る**: これまで implementer 側に閉じていた本コレクションが、PR を受け取る側の作業も扱えるようになる
- **skill 数が 5 → 6 になる**: CONTEXT.md の skill 一覧 / agent dispatch matrix / 配置 table の更新が必要
- **herdr が実行前提になる**: 本 skill は `HERDR_ENV=1` を前提とし、herdr 外では起動時に中断する。既存 5 skill には無かった前提であり、コレクションとして「herdr 依存の skill と非依存の skill が混在する」状態になる
- **`gh` が実行前提になる**: PR メタ情報の取得に `gh pr view` を使う。未導入環境では成立しない
- **子セッションの後片付けが user 判断に残る**: 子 2 本と worktree の片付けは Step 6 で 1 問確認する。親が自動で消すと、未確認の観測結果が失われうるため

# claude-collections

Claude Code 用の**スキル+エージェント集（コレクション）**を複数ホストするリポジトリ。各コレクションは1つの自己完結ユニットとして、自分の skills・agents・設計ドキュメント（ADR/CONTEXT）を持つ（モノレポ的）。

## 構成

```
claude-collections/
├── README.md                       # 本ファイル
├── AGENTS.md                       # エージェント向け規約(正本)
├── CLAUDE.md                       # @AGENTS.md ポインタ
├── CONTEXT-MAP.md                  # コレクション索引
├── docs/adr/                       # repo 横断の決定
├── .claude-plugin/marketplace.json # Claude Code plugin marketplace 宣言
└── <collection>/                   # コレクション(自己完結)
    ├── CONTEXT.md
    ├── docs/{adr,ROADMAP.md}
    ├── .claude-plugin/plugin.json  # Claude Code plugin metadata
    ├── skills/
    └── agents/
```

## ルール

- **コレクション優先**：スキル/エージェントは root 直下でなく `<collection>/` 配下に置く。各コレクションは自己完結（`docs/adr/0001`）。
- **実在職種**：エージェントは現実の職種名で設計する（成果物名で割らない）。
- **`plugin:name` で起動**：スキル/エージェントは frontmatter の `name` で識別されるが、**起動は `plugin:name` 形式の修飾名で行う**（例：`shared:software-architect`）。agent は bare name が解決されず、さらにコレクション間で agent 名が重複すると片方の agent セットが registry から落ちる。skill は名前空間が効くのでこの制約を受けないが、表記は修飾形に揃える（ADR-0010）。
- 詳細な規約は [`AGENTS.md`](AGENTS.md)、コレクション一覧は [`CONTEXT-MAP.md`](CONTEXT-MAP.md)。

## コレクション

- **[`indie-studio`](indie-studio/)** — 個人開発のサービス設計〜デザイン〜開発をオールインで回す AI 自律開発ハーネス。アンカー（人間が握る土台）から企画・デザイン・技術設計・分解・実装までを、人間の数ゲートだけで自律的に進める。**`shared` と `enhance-superpowers` の install が必要**（S5 実装ステージを enhance-superpowers へ委譲・indie-studio ADR-0032）。
- **[`enhance-superpowers`](enhance-superpowers/)** — 公式 superpowers plugin の直線フロー（brainstorming → writing-plans → executing-plans）に、5 成果物 Spec フェーズ確定・agent 能動 dispatch・監査ログ・コンプライアンス trigger を被せた強化版。
- **[`shared`](shared/)** — 上記 2 つが共通で使う基盤。collection 非依存の中立語彙で書かれた engineering 系 13 職種エージェントと helper skill 2 本を提供する。**上記いずれかを使う場合は併せて install が必要**（ADR-0010）。

## Plugin として install して使う

本リポジトリは Claude Code の **plugin marketplace** として機能する（`.claude-plugin/marketplace.json`）。各コレクションは独立した plugin として配布され、`/plugin install <name>@claude-collections` で他プロジェクトに取り込める。

### 同じ Mac の別プロジェクトから使う（local path）

ローカルチェックアウトを直接 marketplace として登録する。反復開発に最適。

```
/plugin marketplace add /Users/<you>/ghq/github.com/gotomts/claude-collections
/plugin install shared@claude-collections
/plugin install enhance-superpowers@claude-collections
/plugin install indie-studio@claude-collections
```

### 別マシン・別環境から使う（GitHub repo）

GitHub 経由で marketplace を登録する。public リポジトリなので事前の認証は不要（手動 install/update・auto-update いずれも認証なしで動く）。

```
/plugin marketplace add gotomts/claude-collections
/plugin install shared@claude-collections
/plugin install enhance-superpowers@claude-collections
/plugin install indie-studio@claude-collections
```

`GITHUB_TOKEN`（または `GH_TOKEN`）の設定は必須ではない。GitHub API の未認証レート制限を避けたい場合の任意設定。

### install 済みを最新に更新する

**marketplace の更新と plugin の更新は別操作**。marketplace だけ更新しても install 済み plugin は古い commit の cache を指したままで、新しく追加した skill / agent は現れない。両方を順に実行する。

```sh
# 1. marketplace（= repo の clone）を最新 main に追従させる
claude plugin marketplace update claude-collections

# 2. install 済み plugin を 1 つずつ最新 commit へ更新する
for p in shared enhance-superpowers indie-studio; do
  claude plugin update "$p@claude-collections"
done
```

`claude plugin update` の `--scope` は既定が `user`。project / local scope で install した場合は、install 時と同じ scope を明示する（例：`--scope project`）。

**更新はセッションへの反映が別に要る。** `claude plugin update` は実行中のセッションには効かないため、`/reload-plugins` を実行するか Claude Code を再起動する（reload が prompt cache を無効化する場合は警告が出て適用が保留されるので、`/reload-plugins --force` で適用する）。反映するまで、新しい skill は cache に置かれていてもセッションからは見えない。

Claude Code セッション内から対話的にやる場合は `/plugin` を使う（同じ 2 段階を UI で行う）。

#### 「skill が見つからない」ときの確認手順

repo に存在するはずの skill が `<plugin>:<skill>` で解決されない場合、原因はほぼ cache の古さ。まず install 状態を 1 コマンドで見る。

```sh
claude plugin list --json | python3 -c "
import json, sys
for p in json.load(sys.stdin):
    if 'claude-collections' in p['id']:
        print(p['id'], p['version'], p['scope'], 'enabled=%s' % p['enabled'])
"
```

- **`version` が repo の main とズレている** → 上の更新手順を実行する。
- **`enabled` が `false`** → `claude plugin enable <name>@claude-collections` で有効化する（`enable` の `--scope` は既定で install 済み scope を自動検出する）。install されていても enable されていなければ skills も agents もロードされない。
- **どちらも正常なのに見えない** → その commit の cache に skill の実体があるか確認する。無ければ更新自体が失敗している。`sha` には上で得た `version` を入れる。

  ```sh
  sha=97159496d7e0   # ← 上の出力の version に置き換える
  ls ~/.claude/plugins/cache/claude-collections/*/"$sha"/skills/
  ```

### バージョニング方針

- **現状（テスト期）**：`plugin.json` の `version` を省略し、git commit SHA を暗黙の pin として扱う。main にコミットすると `/plugin marketplace update` で即反映される
- **安定化後**：semver を `plugin.json` に明示し、breaking change には major bump を伴う。切り替え判断は [`docs/adr/0003`](docs/adr/0003-plugin-marketplace-distribution.md) を extends する新 ADR で記録する

## 新しいコレクションを追加するとき

1. `<collection>/` 配下に `skills/` / `agents/` / `docs/adr/` / `CONTEXT.md` / `ROADMAP.md` / `.claude-plugin/plugin.json` を作る（ADR-0001 の構造）
2. shared のエージェント／スキルを使う場合は、skill 内から `shared:<agent>` / `shared:<skill>` の修飾名で参照する（vendoring は廃止・ADR-0010）。`shared` plugin の install が前提になる。**agent は bare name が解決されないため修飾必須**、skill は名前空間が効くが表記を揃えて修飾形にする
3. コレクション固有の agent 名は **shared および他コレクションと重複させない**（同名衝突は agent セットの消失を招く・ADR-0010）
4. root の `marketplace.json` に新 plugin を 1 entry 追加
5. `make regen-drafter-configs` で release-drafter の config を生成
6. `CONTEXT-MAP.md` にコレクションの所在と概要を追記
7. **初回リリースは tag 付け替えと publish を同時に行う**（新規コレクションは直前のリリースが無いため version-resolver の patch 固定が効かず、release-drafter の初期値 `v0.1.0` が出る。draft のまま `--tag` だけ直しても次の main push で drafter に戻されるので、`--draft=false` と同時に指定する）：`gh release edit --repo gotomts/claude-collections <collection>/v0.1.0 --tag <collection>/v0.0.1 --title <collection>/v0.0.1 --draft=false`。実行後は `gh api repos/gotomts/claude-collections/releases --jq '.[]|"\(.tag_name) draft=\(.draft)"'` で tag と draft 状態を確認する（`gh release list` はキャッシュで古い tag を返しうる）

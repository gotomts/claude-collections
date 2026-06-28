.PHONY: help sync verify status regen-drafter-configs verify-drafter-configs

help:  ## 利用可能な target を表示
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-22s\033[0m %s\n", $$1, $$2}'

sync:  ## shared から取り込み (COLLECTION=name で指定 / 無指定なら TTY 時 picker[fzf あれば矢印キー、なければ番号] / 非 TTY 時は全 collection)
	@./scripts/sync-shared.sh sync $(COLLECTION)

verify:  ## drift 検知: source 更新忘れ / dst body 手編集 を両方検出 (CI 用、drift で exit 1)
	@./scripts/sync-shared.sh verify $(COLLECTION)

status:  ## synced/drifted/edited/missing の状態表示
	@./scripts/sync-shared.sh status $(COLLECTION)

regen-drafter-configs:  ## release-drafter の per-collection config を template から再生成
	@./scripts/regen-drafter-configs.sh

verify-drafter-configs:  ## drafter configs が template + collection 一覧と sync しているか CI 検証 (drift で exit 1)
	@./scripts/regen-drafter-configs.sh --check

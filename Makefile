.PHONY: help sync verify status

help:  ## 利用可能な target を表示
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

sync:  ## shared から各 collection へ取り込み (COLLECTION=name で指定可)
	@./scripts/sync-shared.sh sync $(COLLECTION)

verify:  ## drift 検知 (CI 用、drift で exit 1)
	@./scripts/sync-shared.sh verify $(COLLECTION)

status:  ## synced/drifted/missing の状態表示
	@./scripts/sync-shared.sh status $(COLLECTION)

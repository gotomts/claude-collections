.PHONY: help regen-drafter-configs verify-drafter-configs

help:  ## 利用可能な target を表示
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-22s\033[0m %s\n", $$1, $$2}'

regen-drafter-configs:  ## release-drafter の per-collection config を template から再生成
	@./scripts/regen-drafter-configs.sh

verify-drafter-configs:  ## drafter configs が template + collection 一覧と sync しているか CI 検証 (drift で exit 1)
	@./scripts/regen-drafter-configs.sh --check

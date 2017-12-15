.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' Makefile | \
	sort | \
	awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

format: ## Format the whole codabase with the upcoming formatter
	@docker run \
	--rm --name elixir_dev -it \
	-v $(shell pwd):/app leifg/elixir:edge \
	sh -c "cd /app && mix format ${FILE}"

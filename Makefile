.DEFAULT_GOAL := help

# --- pinned tool versions (bumps are explicit commits) ---
PKL_VERSION := 0.32.0

UNAME_S := $(shell uname -s | tr A-Z a-z)
UNAME_M := $(shell uname -m)
ifeq ($(UNAME_M),x86_64)
  PKL_ARCH := amd64
else
  PKL_ARCH := aarch64
endif
ifeq ($(UNAME_S),darwin)
  PKL_OS := macos
else
  PKL_OS := linux
endif

BIN := bin
PKL := $(BIN)/pkl

.PHONY: configure
configure: $(PKL) ## Set up a working environment from scratch (tools go to bin/)

$(PKL):
	@mkdir -p $(BIN)
	curl -fsSL -o $(PKL) \
	  https://github.com/apple/pkl/releases/download/$(PKL_VERSION)/pkl-$(PKL_OS)-$(PKL_ARCH)
	chmod +x $(PKL)
	$(PKL) --version

.PHONY: test
test: $(PKL) ## Run schema tests (valid fixtures must eval, invalid must fail)
	./scripts/test.sh

.PHONY: eval
eval: $(PKL) ## Eval a workflow file: make eval FILE=path/to/workflow.pkl
	$(PKL) eval $(FILE)

.PHONY: clean
clean: ## Remove downloaded tools
	rm -rf $(BIN)/*

.PHONY: help
help: ## List all targets with explanations
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

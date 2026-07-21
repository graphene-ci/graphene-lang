.DEFAULT_GOAL := help

# --- pinned tool versions (bumps are explicit commits) ---
KCL_VERSION := v0.12.7
KCL_LSP_VERSION := v0.11.2

UNAME_S := $(shell uname -s | tr A-Z a-z)
UNAME_M := $(shell uname -m)
ifeq ($(UNAME_M),x86_64)
  KCL_ARCH := amd64
else
  KCL_ARCH := arm64
endif
ifeq ($(UNAME_S),darwin)
  KCL_OS := darwin
else
  KCL_OS := linux
endif

BIN := bin
KCL := $(BIN)/kcl
KCL_LSP := $(BIN)/kcl-language-server

.PHONY: configure
configure: $(KCL) $(KCL_LSP) ## Set up a working environment from scratch (tools go to bin/)

$(KCL):
	@mkdir -p $(BIN)
	curl -fsSL -o $(BIN)/kcl.tgz \
	  https://github.com/kcl-lang/cli/releases/download/$(KCL_VERSION)/kcl-$(KCL_VERSION)-$(KCL_OS)-$(KCL_ARCH).tar.gz
	tar xzf $(BIN)/kcl.tgz -C $(BIN) kcl
	rm $(BIN)/kcl.tgz
	$(KCL) version

$(KCL_LSP):
	@mkdir -p $(BIN)
	curl -fsSL -o $(BIN)/kclvm.tgz \
	  https://github.com/kcl-lang/kcl/releases/download/$(KCL_LSP_VERSION)/kclvm-$(KCL_LSP_VERSION)-$(KCL_OS)-$(KCL_ARCH).tar.gz
	tar xzf $(BIN)/kclvm.tgz -C $(BIN) --strip-components=2 kclvm/bin/kcl-language-server
	rm $(BIN)/kclvm.tgz
	$(KCL_LSP) version

.PHONY: test
test: $(KCL) ## Run schema tests (valid fixtures must eval, invalid must fail)
	./scripts/test.sh

.PHONY: eval
eval: $(KCL) ## Eval a workflow file: make eval FILE=path/to/workflow.k
	$(KCL) run $(FILE)

.PHONY: clean
clean: ## Remove downloaded tools
	rm -rf $(BIN)/*

.PHONY: help
help: ## List all targets with explanations
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

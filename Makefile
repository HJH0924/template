GO := go
ifeq ($(origin ROOT_DIR),undefined)
ROOT_DIR := $(shell pwd)
endif

# Linux command settings                
FIND := find . ! -path './third_party/*' ! -path './vendor/*'    
XARGS := xargs --no-run-if-empty    

# Copy githook scripts when execute makefile    
COPY_GITHOOK:=$(shell cp -f githooks/* .git/hooks/) 

all: verify-copyright test format lint 

## test: Test the package.
.PHONY: test
test:
	@echo "===========> Testing packages"
	@$(GO) test ./...

.PHONY: golines.verify
golines.verify:
ifeq (,$(shell which golines 2>/dev/null))
	@echo "===========> Installing golines"
	@$(GO) install github.com/segmentio/golines@latest
endif

.PHONY: goimports.verify
goimports.verify:
ifeq (,$(shell which goimports 2>/dev/null))
	@echo "===========> Installing goimports"
	@$(GO) install golang.org/x/tools/cmd/goimports@latest
endif

## format: Format the package with `gofmt`
.PHONY: format
format: goimports.verify golines.verify
	@echo "===========> Formating codes"
	 @$(FIND) -type f -name '*.go' | $(XARGS) gofmt -s -w
	 @$(FIND) -type f -name '*.go' | $(XARGS) goimports -w -local .
	 @$(FIND) -type f -name '*.go' | $(XARGS) golines -w --max-len=120 --reformat-tags --shorten-comments --ignore-generated .   

.PHONY: lint.verify
lint.verify:
ifeq (,$(shell which golangci-lint 2>/dev/null))
	@echo "===========> Installing golangci lint"
	@$(GO) install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
	@golangci-lint completion bash > $(HOME)/.golangci-lint.bash
	@if ! grep -q .golangci-lint.bash $(HOME)/.bashrc; then echo "source \$$HOME/.golangci-lint.bash" >> $(HOME)/.bashrc; fi
endif

## lint: Check syntax and styling of go sources.
.PHONY: lint
lint: lint.verify
	@echo "===========> Run golangci to lint source codes"
	@golangci-lint run $(ROOT_DIR)/...

.PHONY: copyright.verify
copyright.verify:
ifeq (,$(shell which addlicense 2>/dev/null))
	@echo "===========> Installing addlicense"
	@$(GO) install github.com/HJH0924/addlicense@latest
endif

## verify-copyright: Verify the license headers for all files.
.PHONY: verify-copyright
verify-copyright: copyright.verify
	@echo "===========> Verifying the license headers for all files"
	@addlicense --check -c "Tvux" $(ROOT_DIR) --skip-dirs=third_party,.idea,.vscode,vendor,_output || true

## add-copyright: Ensures source code files have copyright license headers.
.PHONY: add-copyright
add-copyright: copyright.verify
	@addlicense -v -c "Tvux" $(ROOT_DIR) --skip-dirs=third_party,.idea,.vscode,vendor,_output

.PHONY: updates.verify
updates.verify:
ifeq (,$(shell which go-mod-outdated 2>/dev/null))
	@echo "===========> Installing go-mod-outdated"
	@$(GO) install github.com/psampaz/go-mod-outdated@latest
endif

## check-updates: Check outdated dependencies of the go projects.
.PHONY: check-updates
check-updates: updates.verify
	@$(GO) list -u -m -json all | go-mod-outdated -update -direct

## gitlint-install: Install go-gitlint
.PHONY: gitlint-install
gitlint-install:
ifeq (,$(shell which go-gitlint 2>/dev/null))
	@echo "===========> Installing go-gitlint"
	@curl https://raw.githubusercontent.com/llorllale/go-gitlint/master/download-gitlint.sh > download-gitlint.sh
	@chmod +x download-gitlint.sh
	@./download-gitlint.sh
	@mv ./bin/gitlint ~/go/bin/go-gitlint
	@rm -rf ./bin ./download-gitlint.sh
endif

## help: Show this help info.
.PHONY: help
help: Makefile
	@echo -e "\nUsage: make <TARGETS> ...\n\nTargets:"
	@sed -n 's/^##//p' $< | column -t -s ':' |  sed -e 's/^/ /'
	@echo "$$USAGE_OPTIONS"

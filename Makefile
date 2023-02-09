DOTPATH := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))
CANDIDATES := $(wildcard .??*)
EXCLUSIONS := .DS_Store .git .gitmodule
DOTFILES := $(filter-out $(EXCLUSIONS), $(CANDIDATES))

.DEFAULT_GOAL := help

.PHONY: help

all: deploy brew vim

list: ## List dotfiles that symbolic links will be deployed.
	@$(foreach val, $(DOTFILES), /bin/ls -dF $(val);)

deploy: ## Deploy dotfiles symbolic links
	@echo '===> Start to deploy config files to home directory.'
	@echo ''
	@$(foreach val, $(DOTFILES), ln -sfnv $(abspath $(val)) $(HOME)/$(val);)

brew: ## Install formulae listed in Brewfile.
	@/bin/bash brew.sh

vim: ## Set up vim.
	@/bin/bash vim.sh

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| sort \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'


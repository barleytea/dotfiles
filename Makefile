DOTPATH := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))
CANDIDATES := $(wildcard .??*)
EXCLUSIONS := .DS_Store .git .gitmodule
DOTFILES := $(filter-out $(EXCLUSIONS), $(CANDIDATES))

.DEFAULT_GOAL := help

.PHONY: help

all: nix deploy brew vim

list: ## List dotfiles that symbolic links will be deployed.
	@$(foreach val, $(DOTFILES), /bin/ls -dF $(val);)

nix: ## Install Nix
	@curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm
	@source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
	@nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
	@nix-channel --update
	@nix-shell '<home-manager>' -A install
	@nix run .#update

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


DOTPATH := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))
CANDIDATES := $(wildcard .??*)
EXCLUSIONS := .DS_Store .git .gitmodule
DOTFILES := $(filter-out $(EXCLUSIONS), $(CANDIDATES))

.DEFAULT_GOAL := help

.PHONY: help

all: deploy vim

list: ## List dotfiles that symbolic links will be deployed.
	@$(foreach val, $(DOTFILES), /bin/ls -dF $(val);)

deploy: ## Deploy dotfiles symbolic links
	@echo '===> Start to deploy config files to home directory.'
	@echo ''
	@$(foreach val, $(DOTFILES), ln -sfnv $(abspath $(val)) $(HOME)/$(val);)

vim: ## Set up vim.
	@/bin/bash vim.sh

nix-install:
	curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm
	source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
	nix --version
	nix-channel --add https://nixos.org/channels/nixpkgs-unstable
	nix-channel --update
	ls -al /nix/var/nix/profiles/default/bin/

nix-apply:
	nix run . switch

nix-uninstall:
	/nix/nix-uninstaller uninstall

nix-darwin-install:
	nix-build https://github.com/LnL7/nix-darwin/archive/master.tar.gz -A installer
	./result/bin/darwin-installer

nix-darwin-apply:
	#!/usr/bin/env bash
	darwin-rebuild switch

nix-darwin-update:
	nix-channel --update darwin
	darwin-rebuild changelog


help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| sort \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'


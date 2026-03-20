.DEFAULT_GOAL := help
.PHONY: help

SHELL := /usr/bin/env bash

help: ## Show available tasks
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-25s\033[0m %s\n", $$1, $$2}'

host-help: ## Show Windows host UX guide path
	@echo "See windows-ctf/host-windows/README.md for PowerShell commands."

bootstrap-wsl: ## Bootstrap Kali inside WSL2
	bash ./scripts/bootstrap-wsl-kali.sh

bootstrap-vm: ## Bootstrap Kali inside VMware
	bash ./scripts/bootstrap-vm-kali.sh

sync-dotfiles: ## Clone/pull dotfiles and apply links
	bash ./scripts/sync-dotfiles.sh

verify-environment: ## Verify command availability and baseline health
	bash ./scripts/verify-environment.sh

install-core: ## Install core package manifest only
	bash ./scripts/install-manifest.sh core

install-all: ## Install all manifests (core + category + gui)
	bash ./scripts/install-manifest.sh all

install-mise: ## Install mise, Node.js LTS, and global npm tools (codex etc.)
	bash ./scripts/install-mise.sh

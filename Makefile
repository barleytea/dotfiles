RULE_REGEX := ^[a-zA-Z_][a-zA-Z0-9_-]+:
RULE_AND_DESC_REGEX := $(RULE_REGEX).*?## .*$$
EXTRA_COMMENT_REGEX := ^## .* ##$$
.DEFAULT_GOAL := help
.PHONY: help

SHELL := /usr/bin/env bash
# Nix profile path - pick the first available known location (allow override)
NIX_PROFILE ?= $(firstword $(foreach path,/run/current-system/sw/etc/profile.d/nix-daemon.sh /run/current-system/sw/etc/profile.d/nix.sh /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh /etc/profiles/per-user/$(USER)/etc/profile.d/nix.sh $(HOME)/.nix-profile/etc/profile.d/nix.sh,$(wildcard $(path))))
NIX_SOURCE_CMD = if [ -z "$(NIX_PROFILE)" ] || [ ! -f "$(NIX_PROFILE)" ]; then echo "Nix profile script not found; set NIX_PROFILE to a valid path" >&2; exit 1; fi; source "$(NIX_PROFILE)";

help: ## このヘルプメッセージを表示します
	@grep -E -e $(RULE_AND_DESC_REGEX) -e $(EXTRA_COMMENT_REGEX) $(MAKEFILE_LIST) | ./scripts/help.awk | less -R

help-fzf: ## fzfを使ってヘルプメッセージを表示します
	@grep -E -e $(RULE_AND_DESC_REGEX) $(MAKEFILE_LIST) \
	| ./scripts/help.awk \
	| fzf --ansi \
	| cut -d ' ' -f 1 \
	| xargs -I{} make {}

## Nix ##
nix-channel-update: ## Nixチャンネルを最新に更新します
	$(NIX_SOURCE_CMD) \
	nix-channel --add https://nixos.org/channels/nixpkgs-unstable
	$(NIX_SOURCE_CMD) \
	nix-channel --update

## ---- Flake Lock 操作 (細粒度アップデート) ---- ##
flake-update-darwin: ## darwin/flake.lock の全入力を更新します
	$(NIX_SOURCE_CMD) \
	cd darwin && nix flake update

flake-update-nixos: ## nixos/flake.lock の全入力を更新します
	$(NIX_SOURCE_CMD) \
	cd nixos && nix flake update

flake-update-nixvim: ## nixvim/flake.lock の全入力を更新します
	$(NIX_SOURCE_CMD) \
	cd nixvim && nix flake update

flake-update-all: flake-update-darwin flake-update-nixos flake-update-nixvim ## 全 flake.lock を更新します

## ---- Home Manager Operations (macOS) ---- ##
home-manager-switch: ## Home Manager設定を適用 (flake.lock を更新しない)
	$(NIX_SOURCE_CMD) \
	cd darwin && nix run nixpkgs#home-manager -- switch --flake .#home --impure --no-write-lock-file

home-manager-build: ## Home Manager設定をビルドのみ (適用しない)
	$(NIX_SOURCE_CMD) \
	cd darwin && nix build .#homeConfigurations.home.activationPackage --impure

home-manager-apply: flake-update-darwin home-manager-switch ## Home Manager設定を適用 (まずflakeを全更新)

nix-uninstall: ## Nixを完全にアンインストールします
	$(NIX_SOURCE_CMD) \
	/nix/nix-uninstaller uninstall

## ---- nix-darwin Operations (macOS) ---- ##
nix-darwin-apply: ## nix-darwinの全設定を適用します（システム全体の設定）
	$(NIX_SOURCE_CMD) \
	cd darwin && sudo nix --extra-experimental-features "nix-command flakes" run nix-darwin -- switch --flake .#all --impure

nix-darwin-homebrew-apply: ## nix-darwinのHomebrew設定のみを適用します
	$(NIX_SOURCE_CMD) \
	cd darwin && sudo nix --extra-experimental-features "nix-command flakes" run nix-darwin -- switch --flake .#homebrew --impure

nix-darwin-system-apply: ## nix-darwinのシステム設定のみを適用します（Finder、Dock等の設定）
	$(NIX_SOURCE_CMD) \
	cd darwin && sudo nix --extra-experimental-features "nix-command flakes" run nix-darwin -- switch --flake .#system --impure

nix-darwin-service-apply: ## nix-darwinのサービス設定のみを適用します
	$(NIX_SOURCE_CMD) \
	cd darwin && sudo nix --extra-experimental-features "nix-command flakes" run nix-darwin -- switch --flake .#service --impure

nix-darwin-check: ## nix-darwinの設定をビルドのみ行います（実際の適用はしません）
	$(NIX_SOURCE_CMD) \
	cd darwin && nix --extra-experimental-features "nix-command flakes" build .#darwinConfigurations.all.system --impure --no-write-lock-file

## ---- NixOS Operations ---- ##
nixos-switch: ## NixOSシステム設定を適用します
	$(NIX_SOURCE_CMD) \
	cd nixos && sudo nixos-rebuild switch --flake .#desktop

nixos-build: ## NixOSシステム設定をビルドのみ行います（適用しない）
	$(NIX_SOURCE_CMD) \
	cd nixos && sudo nixos-rebuild build --flake .#desktop --no-write-lock-file

## ---- All Operations ---- ##
nix-update-all: nix-channel-update home-manager-apply nix-darwin-apply ## Nix関連の全設定を一括で更新・適用します (macOS)

nix-check-all: nix-channel-update home-manager-apply nix-darwin-check ## CI環境用：実際の適用なしでテストを実行します (macOS)

nix-check-all-ci: nix-channel-update home-manager-switch nix-darwin-check ## CI環境用：flake.lockを更新せずにテストを実行します (macOS)

nix-gc: ## Nixのガーベジコレクションを実行します
	$(NIX_SOURCE_CMD) \
	sudo nix-collect-garbage -d

## Pre-commit ##
pre-commit-init: ## pre-commitフックを初期化・インストールします
	mise run pre-commit-init

pre-commit-run: ## pre-commitを全ファイルに対して実行します
	mise exec -- pre-commit run --all-files

## VSCode ##
vscode-apply: ## VSCodeの設定と拡張機能を適用します
	bash vscode/settings/index.sh
	bash vscode/extensions/apply.sh

vscode-insiders-apply: ## VSCode Insidersの設定と拡張機能を適用します
	bash vscode/settings/index_insiders.sh
	bash vscode/extensions/apply_insiders.sh

vscode-save: ## 現在のVSCode拡張機能一覧を保存します
	bash vscode/extensions/save.sh

vscode-sync: ## VSCodeの設定を同期します
	bash vscode/settings/sync.sh

## Mise ##
mise-install-npm-commitizen: ## miseで管理しているnpmパッケージ（commitizen）をグローバルにインストールします
	mise run npm-commitizen

mise-install-all: ## miseで管理している全ツールをインストールします
	mise install

mise-list: ## miseのツール一覧を表示します
	mise ls

mise-config: ## miseの設定を表示します
	mise config

## Others ##
zsh: ## zshの起動時間を測定します
	time (zsh -i -c exit)

paths: ## 現在のPATH環境変数を見やすく表示します
	echo $$PATH | tr ':' '\n'

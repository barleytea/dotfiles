RULE_REGEX := ^[a-zA-Z_][a-zA-Z0-9_-]+:
RULE_AND_DESC_REGEX := $(RULE_REGEX).*?## .*$$
EXTRA_COMMENT_REGEX := ^## .* ##$$
.DEFAULT_GOAL := help
.PHONY: help

SHELL := /usr/bin/env bash
# Nix profile path - pick the first available known location (allow override)
NIX_PROFILE ?= $(firstword $(foreach path,/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh /etc/profiles/per-user/$(USER)/etc/profile.d/nix.sh $(HOME)/.nix-profile/etc/profile.d/nix.sh,$(wildcard $(path))))
ifeq ($(NIX_PROFILE),)
$(error Nix profile script not found; set NIX_PROFILE to a valid path)
endif
ifeq ($(wildcard $(NIX_PROFILE)),)
$(error Nix profile script '$(NIX_PROFILE)' not found; set NIX_PROFILE to a valid path)
endif

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
	source $(NIX_PROFILE); \
	nix-channel --add https://nixos.org/channels/nixpkgs-unstable
	source $(NIX_PROFILE); \
	nix-channel --update

## ---- Flake Lock 操作 (細粒度アップデート) ---- ##
flake-update: ## flake.lock の全入力を更新します
	source $(NIX_PROFILE); \
	nix flake update

flake-update-nixpkgs: ## nixpkgs 入力のみ更新します
	source $(NIX_PROFILE); \
	nix flake lock --update-input nixpkgs

flake-update-home-manager: ## home-manager 入力のみ更新します
	source $(NIX_PROFILE); \
	nix flake lock --update-input home-manager

flake-update-nixvim: ## nixvim 入力のみ更新します
	source $(NIX_PROFILE); \
	nix flake lock --update-input nixvim

## ---- Home Manager Operations ---- ##
home-manager-switch: ## Home Manager設定を適用 (flake.lock を更新しない)
	source $(NIX_PROFILE); \
	nix run nixpkgs#home-manager -- switch --flake .#home --impure

home-manager-build: ## Home Manager設定をビルドのみ (適用しない)
	source $(NIX_PROFILE); \
	nix build .#homeConfigurations.home.activationPackage --impure

home-manager-diff-activation: ## (旧) activationPackage ベースの簡易差分 (closure は過小・参考程度)
	bash scripts/home-manager-diff-activation.sh

home-manager-diff: ## 現行 generation と "home-manager build" した新 generation の実質差分を表示
	bash scripts/home-manager-diff.sh

home-manager-apply: flake-update home-manager-switch ## Home Manager設定を適用 (まずflakeを全更新)

nix-uninstall: ## Nixを完全にアンインストールします
	source $(NIX_PROFILE); \
	/nix/nix-uninstaller uninstall

nix-darwin-apply: ## nix-darwinの全設定を適用します（システム全体の設定）
	source $(NIX_PROFILE); \
	sudo nix --extra-experimental-features "nix-command flakes" run nix-darwin -- switch --flake .#all --impure

nix-darwin-homebrew-apply: ## nix-darwinのHomebrew設定のみを適用します
	source $(NIX_PROFILE); \
	sudo nix --extra-experimental-features "nix-command flakes" run nix-darwin -- switch --flake .#homebrew --impure

nix-darwin-system-apply: ## nix-darwinのシステム設定のみを適用します（Finder、Dock等の設定）
	source $(NIX_PROFILE); \
	sudo nix --extra-experimental-features "nix-command flakes" run nix-darwin -- switch --flake .#system --impure

nix-darwin-service-apply: ## nix-darwinのサービス設定のみを適用します
	source $(NIX_PROFILE); \
	sudo nix --extra-experimental-features "nix-command flakes" run nix-darwin -- switch --flake .#service --impure

nix-update-all: nix-channel-update home-manager-apply nix-darwin-apply ## Nix関連の全設定を一括で更新・適用します

nix-darwin-check: ## nix-darwinの設定をビルドのみ行います（実際の適用はしません）
	source $(NIX_PROFILE); \
	nix --extra-experimental-features "nix-command flakes" build .#darwinConfigurations.all.system --impure

nix-check-all: nix-channel-update home-manager-apply nix-darwin-check ## CI環境用：実際の適用なしでテストを実行します

nix-gc: ## Nixのガーベジコレクションを実行します
	source $(NIX_PROFILE); \
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

vscode-sync: ## VSCodeとNeovimの設定を同期します
	bash vscode/settings/sync.sh

vscode-neovim-init: ## VSCode用のNeovim初期化ファイルを設定します
	bash vscode/settings/neovim-init.sh

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

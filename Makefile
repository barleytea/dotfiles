RULE_REGEX := ^[a-zA-Z_][a-zA-Z0-9_-]+:
RULE_AND_DESC_REGEX := $(RULE_REGEX).*?## .*$$
EXTRA_COMMENT_REGEX := ^## .* ##$$
.DEFAULT_GOAL := help
.PHONY: help

SHELL := /bin/bash
NIX_PROFILE := /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh

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

home-manager-apply: ## Home Managerの設定を適用します（flakeを更新してから適用）
	source $(NIX_PROFILE); \
	nix flake update
	nix run nixpkgs#home-manager -- switch --flake .#home --impure

nix-uninstall: ## Nixを完全にアンインストールします
	source $(NIX_PROFILE); \
	/nix/nix-uninstaller uninstall

nix-darwin-apply: ## nix-darwinの全設定を適用します（システム全体の設定）
	source $(NIX_PROFILE); \
	nix --extra-experimental-features "nix-command flakes" run nix-darwin -- switch --flake .#all --impure

nix-darwin-homebrew-apply: ## nix-darwinのHomebrew設定のみを適用します
	source $(NIX_PROFILE); \
	nix --extra-experimental-features "nix-command flakes" run nix-darwin -- switch --flake .#homebrew --impure

nix-darwin-system-apply: ## nix-darwinのシステム設定のみを適用します（Finder、Dock等の設定）
	source $(NIX_PROFILE); \
	nix --extra-experimental-features "nix-command flakes" run nix-darwin -- switch --flake .#system --impure

nix-darwin-service-apply: ## nix-darwinのサービス設定のみを適用します
	source $(NIX_PROFILE); \
	nix --extra-experimental-features "nix-command flakes" run nix-darwin -- switch --flake .#service --impure

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
	pre-commit install

pre-commit-run: ## pre-commitを全ファイルに対して実行します
	pre-commit run --all-files

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

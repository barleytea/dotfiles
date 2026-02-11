.DEFAULT_GOAL := help
.PHONY: help

SHELL := /usr/bin/env bash

help: ## このヘルプメッセージを表示
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-25s\033[0m %s\n", $$1, $$2}'

## Setup ##
setup: ## 完全セットアップ（パッケージ + ツール + リンク）
	bash ./install.sh

install-packages: ## aptパッケージをインストール
	xargs -a packages/base.txt sudo apt install -y

install-ctf: ## CTFツールをインストール
	xargs -a packages/ctf.txt sudo apt install -y

install-tools: ## non-aptツールをインストール
	bash ./scripts/install-tools.sh

install-fonts: ## Nerd Fontsをインストール
	bash ./scripts/install-fonts.sh

## Config ##
link: ## シンボリックリンクを作成
	bash ./scripts/link.sh

unlink: ## シンボリックリンクを削除
	bash ./scripts/unlink.sh

link-dry-run: ## リンク作成のdry-run
	bash ./scripts/link.sh --dry-run

## Update ##
update-packages: ## aptパッケージを更新
	sudo apt update && sudo apt upgrade -y

update-tools: ## non-aptツールを更新
	bash ./scripts/install-tools.sh --update

update-repo: ## dotfilesリポジトリを更新
	git pull

## Mise ##
mise-install: ## mise管理のツールをインストール
	mise install

mise-run-commitizen: ## commitizen/cz-gitをグローバルインストール
	mise run npm-commitizen

mise-run-pre-commit: ## pre-commitフックをインストール
	mise run pre-commit-init

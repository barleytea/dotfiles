[private]
@default: help

# ================== nix ================= #

# Nixチャンネルを最新に更新
nix-channel-update:
  #!/usr/bin/env bash
  source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  nix-channel --add https://nixos.org/channels/nixpkgs-unstable
  nix-channel --update

# Home Managerの設定を適用（flakeを更新してから適用）
home-manager-apply:
  #!/usr/bin/env bash
  source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  nix flake update
  nix run nixpkgs#home-manager -- switch --flake .#home --impure

# Nixを完全にアンインストール
nix-uninstall:
  #!/usr/bin/env bash
  source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  /nix/nix-uninstaller uninstall

# nix-darwinの全設定を適用（システム全体の設定）
nix-darwin-apply:
  #!/usr/bin/env bash
  source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  nix --extra-experimental-features "nix-command flakes" run nix-darwin -- switch --flake .#all --impure

# nix-darwinのHomebrew設定のみ適用
nix-darwin-homebrew-apply:
  #!/usr/bin/env bash
  source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  nix --extra-experimental-features "nix-command flakes" run nix-darwin -- switch --flake .#homebrew --impure

# nix-darwinのシステム設定のみ適用（Finder、Dock等の設定）
nix-darwin-system-apply:
  #!/usr/bin/env bash
  source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  nix --extra-experimental-features "nix-command flakes" run nix-darwin -- switch --flake .#system --impure

# nix-darwinのサービス設定のみ適用
nix-darwin-service-apply:
  #!/usr/bin/env bash
  source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  nix --extra-experimental-features "nix-command flakes" run nix-darwin -- switch --flake .#service --impure

# Nix関連の全設定を一括更新・適用
nix-update-all: nix-channel-update home-manager-apply nix-darwin-apply

# nix-darwinの設定をビルドのみ（実際の適用はしない）
nix-darwin-check:
  #!/usr/bin/env bash
  source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  nix --extra-experimental-features "nix-command flakes" build .#darwinConfigurations.all.system --impure

# CI環境用：実際の適用なしでのテスト
nix-check-all: nix-channel-update home-manager-apply nix-darwin-check

# ================ pre-commit ============ #

# pre-commitフックを初期化・インストール
pre-commit-init:
  #!/usr/bin/env bash
  pre-commit install

# pre-commitを全ファイルに対して実行
pre-commit-run:
  #!/usr/bin/env bash
  pre-commit run --all-files

# ================ vscode ================ #

# ref: https://scrapbox.io/mrsekut-p/VSCode%E3%81%AE%E8%A8%AD%E5%AE%9A%E3%82%92dotfiles%E3%81%A7%E7%AE%A1%E7%90%86%E3%81%99%E3%82%8B

# VSCodeの設定と拡張機能を適用
vscode-apply:
  #!/usr/bin/env bash
  bash vscode/settings/index.sh
  bash vscode/extensions/apply.sh

# VSCode Insidersの設定と拡張機能を適用
vscode-insiders-apply:
  #!/usr/bin/env bash
  bash vscode/settings/index_insiders.sh
  bash vscode/extensions/apply_insiders.sh

# 現在のVSCode拡張機能一覧を保存
vscode-save:
  #!/usr/bin/env bash
  bash vscode/extensions/save.sh

# VSCodeとNeovimの設定を同期する
vscode-sync:
  #!/usr/bin/env bash
  bash vscode/settings/sync.sh

# VSCode用のNeovim初期化ファイルを設定する
vscode-neovim-init:
  #!/usr/bin/env bash
  bash vscode/settings/neovim-init.sh

# ================ mise ================== #

# mise で管理している npm パッケージ（commitizen）をグローバルにインストール
mise-install-npm-commitizen:
  #!/usr/bin/env bash
  mise run npm-commitizen

# mise で管理している全ツールをインストール
mise-install-all:
  #!/usr/bin/env bash
  mise install

# mise のツール一覧を表示
mise-list:
  #!/usr/bin/env bash
  mise ls

# mise の設定を表示
mise-config:
  #!/usr/bin/env bash
  mise config

# ================ others ================ #

# 非推奨: 代わりに mise-install-npm-commitizen を使用
npm-tools:
  #!/usr/bin/env bash
  mise run npm-commitizen

# mise tasks の実行（npm-commitizenをインストール）
mise-tools:
  #!/usr/bin/env bash
  mise run npm-commitizen

# zshの起動時間を測定
zsh:
  #!/usr/bin/env bash
  time (zsh -i -c exit)

# 現在のPATH環境変数を見やすく表示
paths:
  #!/usr/bin/env bash
  echo $PATH | tr ':' '\n'

# 使用可能なタスク一覧を表示
@help:
  #!/usr/bin/env bash
  echo "Usage: just <recipe>"
  echo ""
  just --list

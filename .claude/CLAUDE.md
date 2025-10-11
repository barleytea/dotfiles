# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Architecture Overview

これはNixとHome Managerを使用したmacOS dotfilesリポジトリです。主な構造は以下の通りです：

- **Nix Flake**: flake.nixで全体の設定を管理
- **Home Manager**: home-manager/以下でユーザー環境設定
- **nix-darwin**: darwin/以下でmacOSシステム設定
- **Package Management**: NixとMise（旧rtx）でツール管理

## Common Commands

### Nix Operations

**NixOS:**
```bash
# NixOS設定を適用（Home Manager含む）
sudo nixos-rebuild switch --flake .#desktop

# 設定をビルドのみ（実際の適用はしない）
sudo nixos-rebuild build --flake .#desktop
```

**macOS (nix-darwin):**
```bash
# nix-darwinの全設定を適用
make nix-darwin-apply

# 設定をビルドのみ（実際の適用はしない）
make nix-darwin-check

# Homebrew設定のみを適用
make nix-darwin-homebrew-apply

# システム設定のみを適用（Finder、Dock等）
make nix-darwin-system-apply

# サービス設定のみを適用
make nix-darwin-service-apply
```

**Home Manager (standalone / macOS):**
```bash
# Home Manager設定を適用（flake更新 + switch）
make home-manager-apply

# Home Manager設定を適用（flake更新なし）
make home-manager-switch

# 設定をビルドのみ
make home-manager-build

# 現在との差分を表示
make home-manager-diff
```

**Flake管理:**
```bash
# 全入力を更新
make flake-update

# nixpkgsのみ更新
make flake-update-nixpkgs

# home-managerのみ更新
make flake-update-home-manager

# nixvimのみ更新
make flake-update-nixvim
```

**一括操作:**
```bash
# Nix関連の全設定を一括で更新・適用（macOS用）
make nix-update-all

# 利用可能なコマンド一覧
make help

# fzfでコマンド選択
make help-fzf
```

### Development Tools
```bash
# miseでツール管理
make mise-install-all
make mise-list

# pre-commitを実行
make pre-commit-run
make pre-commit-init

# VSCode設定を適用
make vscode-apply
make vscode-insiders-apply
```

## Key Architecture Patterns

### Nix Configuration Structure
- **flake.nix**: メインエントリポイント、inputs/outputsの定義
- **home-manager/default.nix**: Home Manager設定のエントリポイント
- **darwin/default.nix**: nix-darwinシステム設定のエントリポイント

### Tool Management Strategy
- **Nix**: システムレベルのパッケージ管理
- **Home Manager**: ユーザー環境とdotfiles管理
- **mise**: ランタイムとツールのバージョン管理（node, go等）

### Configuration Categories
1. **Editors**: Neovim、VSCode、Cursor
2. **Terminals**: Alacritty、WezTerm、Ghostty
3. **Shell**: Zsh + Starship + Sheldon + Atuin
4. **Window Management**: Yabai + skhd
5. **Development**: pre-commit、gitleaks、commitizen

## Important Notes

### Nix Specifics
- experimental-features (nix-command flakes) が有効
- allowUnfree = true で商用パッケージも利用可能
- Haskellパッケージのテストは無効化済み

### mise Configuration
- globalConfigでツールバージョンを管理
- npm-commitizenタスクでcommitizen/cz-gitをインストール
- experimentalモードが有効

### File Paths
- dotfiles root: ~/git_repos/github.com/barleytea/dotfiles
- Nix設定: ~/.config/nix/nix.conf
- Home Manager設定: ~/.config/home-manager/

## Build and Deploy Process

**NixOS:**
1. **Development**: 設定ファイルを編集
2. **Build Check**: `sudo nixos-rebuild build --flake .#desktop`でビルド確認
3. **Apply**: `sudo nixos-rebuild switch --flake .#desktop`でシステム設定適用（Home Manager含む）
4. **Verification**: 設定が正しく適用されているか確認

**macOS (nix-darwin):**
1. **Development**: 設定ファイルを編集
2. **Build Check**: `make nix-darwin-check`でビルド確認
3. **Apply**: `make nix-darwin-apply`でシステム設定適用
4. **Verification**: 設定が正しく適用されているか確認

**macOS/Linux (Home Manager standalone):**
1. **Development**: 設定ファイルを編集
2. **Diff Check**: `make home-manager-diff`で差分確認
3. **Build Check**: `make home-manager-build`でビルド確認
4. **Apply**: `make home-manager-apply`で設定適用（flake更新含む）
5. **Verification**: 設定が正しく適用されているか確認

## Documentation Structure

ドキュメントは10の倍数でカテゴリ分けされています：
- 10s: セットアップ・インストール
- 20s: システム・パッケージ管理
- 30s: 言語・ランタイム
- 40s: エディタ・IDE
- 50s: ツール・ユーティリティ
- 60s: サービス・デーモン

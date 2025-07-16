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
```bash
# Home Manager設定を適用
just home-manager-apply

# nix-darwin設定を適用（システム全体）
just nix-darwin-apply

# 全設定を一括更新・適用
just nix-update-all

# 設定をビルドのみ（実際の適用はしない）
just nix-darwin-check
```

### Development Tools
```bash
# miseでツール管理
just mise-install-all
just mise-list

# VSCode設定を適用
just vscode-apply

# pre-commitを実行
just pre-commit-run
```

### System Management
```bash
# 利用可能なタスク一覧
just help

# PATH環境変数を表示
just paths

# zshの起動時間測定
just zsh
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

1. **Development**: 設定ファイルを編集
2. **Build Check**: `just nix-darwin-check`でビルド確認
3. **Apply**: `just home-manager-apply`でHome Manager設定適用
4. **System Apply**: `just nix-darwin-apply`でシステム設定適用
5. **Verification**: 設定が正しく適用されているか確認

## Documentation Structure

ドキュメントは10の倍数でカテゴリ分けされています：
- 10s: セットアップ・インストール
- 20s: システム・パッケージ管理
- 30s: 言語・ランタイム
- 40s: エディタ・IDE
- 50s: ツール・ユーティリティ
- 60s: サービス・デーモン

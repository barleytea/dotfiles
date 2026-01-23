# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Architecture Overview

これはNixとHome Managerを使用したmacOS/NixOS dotfilesリポジトリです。主な構造は以下の通りです：

- **Nix Flake**: flake.nixで全体の設定を管理
- **Home Manager**: home-manager/以下でユーザー環境設定
- **nix-darwin**: darwin/以下でmacOSシステム設定
- **NixOS**: nixos/以下でLinuxシステム設定
- **Package Management**: NixとMise（旧rtx）でツール管理

### Supported Architectures

| Architecture | nixpkgs | Status |
|--------------|---------|--------|
| Apple Silicon (aarch64-darwin) | unstable | Full support |
| Intel Mac (x86_64-darwin) | 24.11 | Supported (some Homebrew packages excluded) |
| NixOS (x86_64-linux) | unstable | Full support |

### Version-specific Settings (compat/)

バージョン依存の設定は `compat/` ディレクトリに分離されています：

- `darwin/compat/unstable.nix`: unstable専用オプション（system.primaryUser, homebrew.user）
- `darwin/compat/nixpkgs-2411.nix`: 24.11専用設定（macOS 13互換性のためHomebrew除外）
- `home-manager/compat/unstable.nix`: unstable専用パッケージ（nerd-fonts.hack, xan, nil, nil_ls）
- `home-manager/compat/nixpkgs-2411.nix`: 24.11専用パッケージ（nerdfonts.override）

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
- **home-manager/compat/**: バージョン依存パッケージ
- **darwin/default.nix**: nix-darwinシステム設定のエントリポイント
- **darwin/compat/**: バージョン依存オプション
- **nixos/configuration.nix**: NixOS設定のエントリポイント

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

### Claude Code Configuration
- **home-manager/claude/config/**: Claude Code設定の管理
  - **CLAUDE.md**: プロジェクト固有の指示
  - **settings.json**: Claude Code設定
  - **commands/**: カスタムコマンド定義
  - **skills/**: カスタムスキル定義
- **自動デプロイ**: `make home-manager-apply`で`~/.claude/`にシンボリックリンクを作成
- **スキル追加手順**:
  1. `home-manager/claude/config/skills/<skill-name>/`にスキルディレクトリを作成
  2. `SKILL.md`（必須）とオプションファイルを配置
  3. `make home-manager-apply`で`~/.claude/skills/<skill-name>/`に自動展開

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

ドキュメントはClaude Codeスキルとして管理されています（`.claude/skills/`）：

**セットアップ・インストール:**
- `/installation` - Nix and dotfiles installation guide

**システム・パッケージ管理:**
- `/nix-operations` - Nix operations (home-manager, nix-darwin, rollback)
- `/mise-guide` - Mise tool version management

**言語・ランタイム:**
- `/languages-setup` - Language and runtime setup

**エディタ・IDE:**
- `/vscode-setup` - VSCode configuration
- `/cursor-setup` - Cursor AI editor (NixOS)
- `/nixos-keybindings` - NixOS keyboard shortcuts

**ツール・ユーティリティ:**
- `/npm-tools` - NPM package management
- `/pre-commit-guide` - Pre-commit hooks
- `/atuin-guide` - Atuin shell history (SQLite)
- `/zoxide-guide` - Zoxide directory navigation
- `/zellij-worktree` - Zellij git worktree workflow

**サービス・デーモン:**
- `/services-guide` - Yabai and skhd (macOS)
- `/fileserver-guide` - NixOS file server (Tailscale)
- `/gitserver-guide` - Git SSH server (NixOS)
- `/tailscale-acl` - Tailscale ACL

**チートシート:**
- `/hyprland-cheatsheet` - Hyprland shortcuts

## Documentation Maintenance Policy

When making changes to this dotfiles project, **ALWAYS** check and update related documentation to keep it synchronized.

### 自動更新が必要なケース

以下のような変更を行った場合、関連するドキュメントを必ず更新してください：

1. **新しいツール・パッケージを追加**
   - → `README.md` の "Main Tools" セクションを更新
   - → 該当するスキル（例: `/nix-operations`, `/mise-guide`）に使用方法を追加

2. **新しいNixモジュール・設定ファイルを追加**
   - → `.claude/CLAUDE.md` の "Architecture Overview" または "Nix Configuration Structure" を更新
   - → `/nix-operations` スキルのコマンド例を更新

3. **キーバインド・ショートカットを変更**
   - → `/hyprland-cheatsheet` スキル（Hyprland）
   - → `/nixos-keybindings` スキル（NixOS keyd設定）
   - → `/services-guide` スキル（Yabai/skhd）
   - → `/zellij-worktree` スキル（Zellij）

4. **新しいMakeタスク・コマンドを追加**
   - → `.claude/CLAUDE.md` の "Common Commands" セクション
   - → 該当するスキル（`/nix-operations`, `/mise-guide` など）

5. **ディレクトリ構造・ファイルパスを変更**
   - → `.claude/CLAUDE.md` の "Nix Configuration Structure" セクション
   - → 該当するスキルの Configuration Location セクション

6. **サービス・設定の動作を変更**
   - → 該当するスキル（`/services-guide`, `/fileserver-guide`, `/gitserver-guide` など）

### 更新プロセス

**IMPORTANT**: コードを変更した後、以下のプロセスを**必ず**実行してください：

1. **影響範囲の特定**
   - 変更内容を確認し、影響するドキュメント/スキルをリストアップ

2. **ドキュメント更新**
   - 特定した全ドキュメントを更新
   - コマンド例、設定例、説明文を最新の状態に

3. **整合性チェック**
   - README.md と .claude/CLAUDE.md が矛盾していないか確認
   - スキル間で重複・矛盾する情報がないか確認

4. **ユーザーへ報告**
   - 更新したドキュメントの一覧を提示
   - 変更内容のサマリーを説明

### 便利なツール

ドキュメント同期を支援するスキル：

- `/sync-docs` - 最近の変更を分析し、更新が必要なドキュメントを自動検出・提案

### 更新例

**例1: 新しいパッケージを追加**
```
変更: home-manager/default.nix に ripgrep を追加
更新箇所:
- README.md → Main Tools > Development Tools
- /nix-operations → Package installation examples
```

**例2: Yabaiのキーバインド追加**
```
変更: home-manager/skhd/default.nix に alt+t を追加
更新箇所:
- /services-guide → Keyboard Shortcuts テーブル
```

**例3: 新しいMakeタスク追加**
```
変更: Makefile に make docker-prune を追加
更新箇所:
- .claude/CLAUDE.md → Development Tools セクション
```

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Architecture Overview

これはNixとHome Managerを使用したmacOS/NixOS dotfilesリポジトリ、およびシンボリックリンクベースのParrotOS設定を含むリポジトリです：

**Nix-based Configurations:**
- **darwin/**: macOS用の独立したflake（nix-darwin + home-manager）
  - `darwin/flake.nix`: macOS設定のメインエントリポイント
  - `darwin/home-manager/`: macOS用のHome Manager設定
- **nixos/**: NixOS用の独立したflake（system + home-manager）
  - `nixos/flake.nix`: NixOS設定のメインエントリポイント
  - `nixos/home-manager/`: NixOS用のHome Manager設定
- **nixvim/**: Neovim用の独立したflake（スタンドアロン使用可能）
  - `nixvim/flake.nix`: Neovim設定のメインエントリポイント

**Non-Nix Configuration:**
- **parrotos/**: ParrotOS/Debian用の設定（シンボリックリンク + aptパッケージ管理）
  - `parrotos/setup.sh`: ワンライナーブートストラップ
  - `parrotos/install.sh`: メインインストーラー
  - `parrotos/Makefile`: 独立したタスクランナー
  - Nix依存なし、aptとGitHub Releasesでツール管理

### Supported Architectures

| Architecture | Package Manager | Status |
|--------------|-----------------|--------|
| Apple Silicon (aarch64-darwin) | Nix (unstable) | Full support |
| Intel Mac (x86_64-darwin) | Nix (unstable) | Full support |
| NixOS (x86_64-linux) | Nix (unstable) | Full support |
| ParrotOS / Debian (x86_64, aarch64) | apt + GitHub Releases | Full support |

## Common Commands

### Nix Operations

**NixOS:**
```bash
# NixOS設定を適用（Home Manager含む）
make nixos-switch
# または: cd nixos && sudo nixos-rebuild switch --flake .#desktop

# 設定をビルドのみ（実際の適用はしない）
make nixos-build
# または: cd nixos && sudo nixos-rebuild build --flake .#desktop
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
```

**Flake管理:**
```bash
# 全flake.lockを更新（darwin, nixos, nixvim）
make flake-update-all

# darwin/flake.lockのみ更新
make flake-update-darwin

# nixos/flake.lockのみ更新
make flake-update-nixos

# nixvim/flake.lockのみ更新
make flake-update-nixvim

# Nixチャンネルを最新に更新
make nix-channel-update
```

**一括操作:**
```bash
# Nix関連の全設定を一括で更新・適用（macOS用）
make nix-update-all

# CI環境用：実際の適用なしでテストを実行（macOS）
make nix-check-all

# 利用可能なコマンド一覧
make help

# fzfでコマンド選択
make help-fzf
```

**メンテナンス:**
```bash
# Nixのガーベジコレクションを実行
make nix-gc

# Nixを完全にアンインストール
make nix-uninstall
```

### ParrotOS / Debian
**ワンライナーセットアップ:**
```bash
curl -fsSL https://raw.githubusercontent.com/barleytea/dotfiles/main/parrotos/setup.sh | bash
```

**手動セットアップ（parrotosディレクトリ内で実行）:**
```bash
# 完全セットアップ
make setup

# 個別インストール
make install-packages  # apt基本パッケージ
make install-ctf       # CTFツール
make install-tools     # non-aptツール (mise, starship, sheldon, etc.)
make install-fonts     # Nerd Fonts

# シンボリックリンク
make link              # リンク作成
make unlink            # リンク削除
make link-dry-run      # dry-run

# 更新
make update-packages   # aptパッケージ更新
make update-tools      # non-aptツール更新
make update-repo       # dotfilesリポジトリ更新

# mise
make mise-install              # mise管理ツールをインストール
make mise-run-commitizen       # commitizen/cz-git
make mise-run-pre-commit       # pre-commitフック
```

詳細は `parrotos/README.md` または `parrotos/Makefile` を参照。

### Development Tools (Nix環境)
```bash
# miseでツール管理
make mise-install-all
make mise-list
make mise-config

# pre-commitを実行
make pre-commit-run
make pre-commit-init

# VSCode設定を適用
make vscode-apply
make vscode-insiders-apply

# VSCode拡張機能一覧を保存
make vscode-save

# VSCodeとNeovimの設定を同期
make vscode-sync

# VSCode用のNeovim初期化ファイルを設定
make vscode-neovim-init
```

**パフォーマンス診断:**
```bash
# zshの起動時間を測定
make zsh

# 現在のPATH環境変数を見やすく表示
make paths
```

## Key Architecture Patterns

### Nix Configuration Structure

**macOS (darwin):**
- **darwin/flake.nix**: macOS用flakeのメインエントリポイント、inputs/outputsの定義
- **darwin/home-manager/default.nix**: macOS用Home Manager設定のエントリポイント
- **darwin/default.nix**: nix-darwinシステム設定のエントリポイント

**NixOS:**
- **nixos/flake.nix**: NixOS用flakeのメインエントリポイント、inputs/outputsの定義
- **nixos/home-manager/default.nix**: NixOS用Home Manager設定のエントリポイント
- **nixos/configuration.nix**: NixOSシステム設定のエントリポイント

**Neovim (nixvim):**
- **nixvim/flake.nix**: Neovim用flakeのメインエントリポイント
- **nixvim/config/**: Neovim設定ファイル群

### Tool Management Strategy
- **Nix**: システムレベルのパッケージ管理
- **Home Manager**: ユーザー環境とdotfiles管理
- **mise**: ランタイムとツールのバージョン管理（node, go等）

### Configuration Categories
1. **Editors**: Neovim、VSCode、Cursor
2. **Terminals**: Alacritty、WezTerm、Ghostty
3. **Shell**: Zsh + Starship + Sheldon + Atuin
4. **Window Management**: AeroSpace + JankyBorders + AltTab
5. **Development**: pre-commit、gitleaks、commitizen

### Claude Code Configuration

**macOS (darwin):**
- **darwin/home-manager/claude/config/**: macOS用Claude Code設定の管理
  - **CLAUDE.md**: プロジェクト固有の指示
  - **settings.json**: Claude Code設定（hooks、permissions）
  - **commands/**: カスタムコマンド定義
  - **skills/**: カスタムスキル定義

**NixOS:**
- **nixos/home-manager/claude/config/**: NixOS用Claude Code設定の管理
  - 構造はmacOSと同じ

**デプロイメント:**
- **自動デプロイ**: `make home-manager-apply`（macOS）または`sudo nixos-rebuild switch`（NixOS）で`~/.claude/`にシンボリックリンクを作成
- **スキル追加手順**:
  1. OS別のディレクトリに配置（`darwin/home-manager/claude/config/skills/<skill-name>/` または `nixos/home-manager/claude/config/skills/<skill-name>/`）
  2. `SKILL.md`（必須）とオプションファイルを配置
  3. 設定を適用すると`~/.claude/skills/<skill-name>/`に自動展開

#### Statusline（ステータスバー）機能
- **スクリプト場所**:
  - macOS: `darwin/home-manager/claude/config/statusline.sh`
  - NixOS: `nixos/home-manager/claude/config/statusline.sh`
- **表示内容**:
  - **1行目**: 🤖 モデル名 | 📁 ディレクトリ名 | 🌿 Gitブランチ
  - **2行目**: 💰 セッション費用/当日費用/ブロック費用 | 🔥 Burn rate（$/時） | 🧠 コンテキスト使用量
  - **3行目**: 📊 今月の累計費用
- **機能**:
  - `npx ccusage`と統合し、リアルタイムで費用・トークン使用状況を表示
  - Gitブランチ情報をキャッシュ（5秒間隔）
  - 月間累計費用をキャッシュ（60秒間隔）
  - Burn rate（1時間あたりの消費ペース）を自動計算
- **パフォーマンス最適化**: キャッシュによりGitコマンドとccusageの実行頻度を抑制

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
1. **Development**: 設定ファイルを編集（nixos/ディレクトリ内）
2. **Build Check**: `make nixos-build`でビルド確認
3. **Apply**: `make nixos-switch`でシステム設定適用（Home Manager含む）
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
- `/services-guide` - AeroSpace, JankyBorders, AltTab (macOS)
- `/fileserver-guide` - NixOS file server (Tailscale)
- `/gitserver-guide` - Git SSH server (NixOS)
- `/tailscale-acl` - Tailscale ACL

**チートシート:**
- `/hyprland-cheatsheet` - Hyprland shortcuts
- `/nixvim-cheatsheet` - Nixvim (Neovim) keybindings and plugins

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
   - → `/services-guide` スキル（AeroSpace / Borders / AltTab）
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
変更: darwin/home-manager/default.nix に ripgrep を追加
更新箇所:
- README.md → Main Tools > Development Tools
- /nix-operations → Package installation examples
```

**例2: AeroSpaceのキーバインド変更**
```
変更: darwin/home-manager/aerospace/aerospace.toml に alt-shift-s を追加
更新箇所:
- /services-guide → Keyboard Shortcuts テーブル
```

**例3: 新しいMakeタスク追加**
```
変更: Makefile に make docker-prune を追加
更新箇所:
- .claude/CLAUDE.md → Development Tools セクション
```

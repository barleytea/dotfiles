# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Architecture Overview

これはNixとHome Managerを使用したmacOS/NixOS dotfilesリポジトリ、およびWindows + WSL2向けのNix非依存なCTF環境設定を含むリポジトリです：

**Nix-based Configurations:**
- **darwin/**: macOS用の独立したflake（nix-darwin + home-manager）
  - `darwin/flake.nix`: macOS設定のメインエントリポイント
  - `darwin/home-manager/`: macOS用のHome Manager設定
- **nixos/**: NixOS用の独立したflake（system + home-manager）
  - `nixos/flake.nix`: NixOS設定のメインエントリポイント
  - `nixos/home-manager/`: NixOS用のHome Manager設定
- **nixvim/**: Neovim用の独立したflake（スタンドアロン使用可能）
  - `nixvim/flake.nix`: Neovim設定のメインエントリポイント

### Supported Architectures

| Architecture | Package Manager | Status |
|--------------|-----------------|--------|
| Apple Silicon (aarch64-darwin) | Nix (unstable) | Full support |
| Intel Mac (x86_64-darwin) | Nix (unstable) | Full support |
| NixOS (x86_64-linux) | Nix (unstable) | Full support |
| Windows + WSL2 (windows-ctf) | apt + winget + scripts | Full support |

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
- **nixos/home-manager/dashboard/**: eww 背景ダッシュボード（天気・時刻・システム状態・生活情報）。`systemd.user.timers` で 10 分ごとにデータ取得し、layer-shell の BOTTOM レイヤーに常駐表示する。詳細は `/dashboard-guide`
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

### AI ツール設定（modules/home/claude/config/）

Claude Code 設定は OS 横断の正典 `modules/home/claude/config/` を単一ソースとして管理する（darwin/nixos 個別の claude ディレクトリは存在しない）。AI エージェント向けの行動原則は同ディレクトリの **AGENTS.md** が唯一の真のソースで、`~/.claude/CLAUDE.md` と `~/.gemini/GEMINI.md` はそこへのシンボリックリンク。

**ファイル配置（`modules/home/claude/config/`）:**
| ファイル/ディレクトリ | 役割 |
|------------------------|------|
| `settings.json` | 全マシン共通のベース設定（hooks、permissions、model 等） |
| `overlays/windows-ctf.json` | windows-ctf 専用の上書き差分（Orca 用 hooks、`excludedCommands`） |
| `merge-settings.sh` | ベースとoverlayをディープマージするスクリプト。`hooks` 配下の配列は連結、それ以外の配列は置換 |
| `agents/explore.md` | 組み込み Explore エージェントを `model: haiku` で上書き |
| `AGENTS.md` | 行動原則（Claude・Gemini 共通の単一ソース） |
| `hooks/` | フックスクリプト群 |
| `skills/` | カスタムスキル定義 |
| `commands/` | カスタムコマンド定義 |
| `statusline.sh` | ステータスライン表示スクリプト |

**`~/.claude/settings.json` の生成方式（重要: シンボリックリンクではなく実ファイル）:**
- **Nix環境（darwin/NixOS）**: `modules/home/claude/default.nix` の Home Manager activation が `merge-settings.sh settings.json` を実行し、ベース設定のみから `~/.claude/settings.json` を生成
- **WSL（windows-ctf）**: `windows-ctf/scripts/setup-claude.sh` がベース設定 + `overlays/windows-ctf.json` をマージして生成
- それ以外（`CLAUDE.md`、statusline、hooks、skills、commands、agents）はすべて `modules/home/claude/config/` からのシンボリックリンク

**権限モデル / ガードレール:**
- 全マシン共通で `permissions.defaultMode: auto` + サンドボックス有効（WSL では `bubblewrap` が必要。windows-ctf のマニフェストに追加済み）
- `permissions.deny` / `autoMode.hard_deny`: force-push や秘密情報ファイル（`~/.npmrc_local`, `~/.zshrc_local`, `~/.ssh`, `~/.aws`, `/etc/nixos/secrets`, `.env` 等）の読み取りをブロック
- `autoMode.soft_deny`: `git push`, `git reset --hard`, `rm -rf`, `*-rebuild switch`, `home-manager switch`, `gh repo delete`, `npm publish` 等は確認を要求
- `permissions.ask`: `model: opus` / `model: fable` を指定するサブエージェント起動時に確認を要求

**モデル戦略:**
- メインセッション: `fable[1m]` / `effortLevel high`（戦略立案・監査・レビュー用）
- サブエージェント: `env.CLAUDE_CODE_SUBAGENT_MODEL=sonnet` によりデフォルトで Sonnet
- Explore エージェント: `agents/explore.md` で `model: haiku` に固定
- `modelSettings` で sonnet/haiku の effort を下げている
- `env.zsh` から `ANTHROPIC_MODEL=opusplan` の export は削除済み（モデル指定は settings.json が一元管理）

**ai-guardrails（review / natural-japanese スキル）:**
- flake input `github:barleytea/ai-guardrails` として `darwin/flake.nix` と `nixos/flake.nix` の両方から取り込み
- 両 HM エントリポイントで `programs.ai-guardrails = { enable = true; installInstructionFiles = false; }` を設定
- `~/.claude/skills/review-*`（8種）と `~/.claude/skills/external-*`（例: `external-natural-japanese`）を自動インストール
- 手動コピーしていた `review-*` / `natural-japanese` スキルは `modules/home/claude/config/skills/` から削除済み
- WSL では `windows-ctf/scripts/setup-claude.sh` が、隣接チェックアウト `../ai-guardrails/generated/`（`AI_GUARDRAILS_DIR` で上書き可）が存在する場合に同じスキル群をリンクする

**スキル追加手順:**
1. `modules/home/claude/config/skills/<skill-name>/` に配置
2. `SKILL.md`（必須）とオプションファイルを配置
3. 設定を適用すると`~/.claude/skills/<skill-name>/`に自動展開

#### Statusline（ステータスバー）機能
- **スクリプト場所**: `modules/home/claude/config/statusline.sh`
- **表示内容（1行）**:
  - モデル名 │ 📁 ディレクトリ名 🌿 Gitブランチ │ ctx ◔ % │ 5h ◕ % │ 7d ● % │ ⏳ブロック残時間 │ $今月累計/mo
- **リングメーター仕様（パターン3: Ring Meter）**:
  - 使用率を5段階のリングアイコンで表現: ○(0-24%) ◔(25-49%) ◑(50-74%) ◕(75-99%) ●(100%)
  - `ctx`: コンテキストウィンドウ使用率
  - `5h`: 5時間ウィンドウ使用率（rate_limits.five_hour.used_percentage、v2.1.80+）
  - `7d`: 7日間ウィンドウ使用率（rate_limits.seven_day.used_percentage、v2.1.80+）
  - 5h/7dは値が存在する場合のみ表示（古いバージョンへのフォールバック）
- **機能**:
  - `ccusage monthly`で今月累計費用を取得（60秒キャッシュ）
  - `ccusage blocks`でブロック残り時間を取得（30秒キャッシュ）
  - Gitブランチ情報をキャッシュ（5秒間隔）
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

### zsh Configuration Management
- `~/.config/zsh/.zshrc` は Home Manager が activation script で実ファイルとして管理（`home.activation.writeZshrc`）
- **外部ツールが `.zshrc` を書き換えることがある**（例: safe-chain setup）→ `make home-manager-apply` で復元可能
- ローカル設定（外部ツールの init スクリプト等）は `~/.zshrc_local` に記述する
  - `~/.zshrc` 末尾で `~/.zshrc_local` を自動 source する設計
- safe-chain の init: `source ~/.safe-chain/scripts/init-posix.sh` → `~/.zshrc_local` に記述
- 詳細は `/safe-chain-guide` スキルを参照

### .npmrc Management (Secret-safe)
- `home.file.".npmrc"` は使わない（既存ファイルの clobber 問題 + シークレット漏洩リスク）
- **ベース設定**（`prefix`, `min-release-age`）は `pkgs.writeText "npmrc-base"` で Nix store に置く
- **シークレット**（`_authToken` 等）は `~/.npmrc_local` でユーザーが手動管理（Nix管理外）
- `home.activation.mergeNpmrc` が activation 時にベース + `~/.npmrc_local` をマージして `~/.npmrc` を生成
- 詳細は `/npm-tools` スキルを参照

### gwq Configuration (git worktree manager)
- `~/.config/gwq/config.toml` は `modules/home/git/default.nix` で管理
- basedir を ghq root (`~/git_repos`) と統一することで `ghq list` でworktreeも一括検索できる
- 命名テンプレート: `{{.Host}}/{{.Owner}}/{{.Repository}}={{.Branch}}`（worktreeのパスに `=` が含まれる）
- worktreeの実体: `~/git_repos/github.com/owner/repo=branch` に配置
- zsh キーバインド:
  - `Ctrl+G`: 全リポジトリ + worktree を fzf で検索・cd（`ghq_repository_search`）
  - `Ctrl+W`: worktreeのみを fzf で検索・cd（`worktree_search`、`=` 含むパスでフィルタ）
  - `Ctrl+]`: ghq list から複数選択して `claude --add-dir` で起動（`claude_add_dir_search`）

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
- `/direnv-guide` - direnv setup and usage (.env auto-loading, .envrc management)
- `/zellij-worktree` - Zellij git worktree workflow
- `/cmux-guide` - cmux terminal multiplexer (Ghostty-based), difit-cmux command, and cmux-workspace branch switcher
- `/safe-chain-guide` - Aikido safe-chain supply chain security tool setup
- `/renovate-guide` - Renovate Bot setup for automatic mise version updates

**サービス・デーモン:**
- `/services-guide` - AeroSpace, JankyBorders, AltTab (macOS)
- `/dashboard-guide` - eww 生活情報ダッシュボード (NixOS/Hyprland)
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

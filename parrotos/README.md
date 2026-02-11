# ParrotOS Dotfiles

CTF 用の ParrotOS マシン向けの dotfiles 設定です。Nix を使わず、**シンボリックリンクベース** + **apt パッケージ管理** で、マシン交換時のワンライナーセットアップを実現します。

## 特徴

- ✅ **ワンライナーブートストラップ**: `curl | bash` で即座にセットアップ
- ✅ **Nix 不要**: プレーンな設定ファイルとシンボリックリンク
- ✅ **apt パッケージ管理**: CTF ツールを含む全パッケージをリスト管理
- ✅ **デスクトップ環境**: ParrotOS デフォルトの MATE をそのまま使用
- ✅ **既存設定の再利用**: darwin/nixos の設定から抽出・最適化

## 対応環境

- ParrotOS (Debian bookworm ベース)
- Debian 12+ / Ubuntu 22.04+
- アーキテクチャ: x86_64, aarch64 (ARM64)

## クイックスタート

### ワンライナーセットアップ

```bash
curl -fsSL https://raw.githubusercontent.com/barleytea/dotfiles/main/parrotos/setup.sh | bash
```

### 手動セットアップ

```bash
# 1. リポジトリをクローン
mkdir -p ~/git_repos/github.com/barleytea
git clone https://github.com/barleytea/dotfiles.git ~/git_repos/github.com/barleytea/dotfiles

# 2. インストーラーを実行
cd ~/git_repos/github.com/barleytea/dotfiles/parrotos
./install.sh

# 3. ログアウト・ログイン（zsh をデフォルトシェルにするため）
```

## ディレクトリ構造

```
parrotos/
├── setup.sh              # ワンライナーブートストラップ
├── install.sh            # メインインストーラー
├── Makefile              # タスクランナー
├── packages/
│   ├── base.txt          # 基本パッケージ (apt)
│   └── ctf.txt           # CTF ツール (apt)
├── scripts/
│   ├── install-tools.sh  # non-apt ツール
│   ├── install-fonts.sh  # Nerd Fonts
│   ├── link.sh           # シンボリックリンク作成
│   ├── unlink.sh         # シンボリックリンク削除
│   └── zellij-*.sh       # Zellij ヘルパー
├── shell/zsh/            # Zsh 設定
├── git/                  # Git 設定
├── starship/             # Starship プロンプト
├── atuin/                # Shell 履歴
├── mise/                 # ツールバージョン管理
├── tmux/                 # Tmux 設定
├── lazygit/              # Lazygit 設定
├── ghostty/              # Ghostty ターミナル
├── zellij/               # Zellij ターミナルマルチプレクサ
├── yazi/                 # Yazi ファイルマネージャ
└── editorconfig/         # EditorConfig
```

## インストール内容

### 基本パッケージ (apt)

- **開発ツール**: git, curl, wget, build-essential, cmake
- **CLI ツール**: zsh, tmux, jq, fzf, ripgrep, bat, fd-find, htop, tree
- **その他**: python3, direnv, xclip

### CTF ツール (apt)

- **ネットワーク**: nmap, wireshark, tcpdump, netcat
- **パスワードクラック**: john, hashcat, hydra
- **Web**: sqlmap, gobuster, ffuf, burpsuite
- **バイナリ解析**: gdb, radare2, ghidra
- **フォレンジック**: binwalk, foremost, exiftool, steghide
- **その他**: metasploit-framework, python3-pwntools

### non-apt ツール (GitHub Releases / 公式インストーラー)

- **ランタイム管理**: mise
- **エディタ**: cursor (公式インストーラー、CI ではスキップ)
- **プロンプト**: starship
- **Shell 拡張**: sheldon, atuin, zoxide
- **ターミナル**: zellij
- **CLI ツール**: yazi, eza, delta, ghq, lazygit, fastfetch

### Nerd Fonts

- Hack Nerd Font (デフォルト)
- JetBrains Mono, Fira Code, Meslo (オプション)

## 使い方

### Makefile コマンド

```bash
make help              # ヘルプを表示
make setup             # 完全セットアップ
make install-packages  # apt パッケージをインストール
make install-ctf       # CTF ツールをインストール
make install-tools     # non-apt ツールをインストール
make install-fonts     # Nerd Fonts をインストール
make link              # シンボリックリンクを作成
make unlink            # シンボリックリンクを削除
make link-dry-run      # リンク作成の dry-run
make update-packages   # apt パッケージを更新
make update-tools      # non-apt ツールを更新
make mise-install      # mise 管理のツールをインストール
```

### mise タスク

```bash
mise install                    # 全ツールをインストール
mise run npm-commitizen         # commitizen/cz-git をインストール
mise run pre-commit-init        # pre-commit フックをインストール
```

## 設定ファイル

### シンボリックリンクマッピング

| ソース | ターゲット |
|---|---|
| `shell/zsh/.zshenv` | `~/.zshenv` |
| `shell/zsh/.zshrc` | `~/.config/zsh/.zshrc` |
| `shell/zsh/config/*.zsh` | `~/.config/zsh/config/` |
| `git/config` | `~/.config/git/config` |
| `starship/starship.toml` | `~/.config/starship.toml` |
| `atuin/config.toml` | `~/.config/atuin/config.toml` |
| `mise/config.toml` | `~/.config/mise/config.toml` |
| `tmux/tmux.conf` | `~/.tmux.conf` |
| `lazygit/config.yml` | `~/.config/lazygit/config.yml` |
| `zellij/config.kdl` | `~/.config/zellij/config.kdl` |
| (その他) | (対応するパス) |

### Zsh プラグイン (Sheldon)

- zsh-defer
- fast-syntax-highlighting
- zsh-autosuggestions

### キーバインド

- **Vi モード**: `bindkey -v`
- **Ctrl+G**: ghq リポジトリ検索 (fzf)
- **Zellij**: デフォルトで自動起動 (CI 環境では無効)

## カスタマイズ

### パッケージの追加

`packages/base.txt` または `packages/ctf.txt` にパッケージ名を追加:

```bash
echo "your-package-name" >> packages/base.txt
make install-packages
```

### 設定の調整

設定ファイルを直接編集:

```bash
vim parrotos/shell/zsh/config/aliases.zsh
make link  # 再リンク
```

### ローカル設定

`~/.zshrc_local` にローカル設定を追加すると、`.zshrc` から自動読み込みされます。

## トラブルシューティング

### Debian パッケージ名の違い

- `bat` → `batcat` (alias で `bat` に変換済み)
- `fd` → `fdfind` (alias で `fd` に変換済み)

### Zellij クリップボード

ParrotOS (MATE/X11) では `xclip` を使用。Wayland 環境では `wl-copy` に変更が必要。

### Ghostty

MATE/X11 環境での動作確認が必要。動作しない場合は Alacritty を検討。

### mise ツールが見つからない

```bash
# PATH に ~/.local/bin を追加
export PATH="$HOME/.local/bin:$PATH"
source ~/.zshenv
```

## ライセンス

このプロジェクトは個人用の dotfiles であり、自由に利用・改変できます。

## 関連リンク

- [親リポジトリ (darwin/nixos)](../)
- [Claude Code スキル](.claude/skills/)

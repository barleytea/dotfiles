# Architecture

このリポジトリは 4 つの独立スコープから成る。

## 1. スコープ全体図

| スコープ | パス | 説明 | ビルド単位 |
|---------|------|------|-----------|
| Darwin（macOS） | `darwin/` | nix-darwin システム + OS 固有 HM モジュール | 独立 flake |
| NixOS | `nixos/` | NixOS システム + OS 固有 HM モジュール（NixOS module 統合型） | 独立 flake |
| Shared HM modules | `modules/home/` | OS 横断の Home Manager モジュール（両 flake から `inputs.dotfiles-shared` で参照） | flake 入力 |
| Nixvim | `nixvim/` | スタンドアロン Neovim 設定。`nix run` 単体可、HM モジュールとしても再利用 | 独立 flake |
| Windows CTF | `windows-ctf/` | WSL2 Kali / VMware Kali / Windows ホストUX | Nix 非依存（apt + bash） |
| VSCode | `vscode/` | 設定・拡張機能の sync 用シェルスクリプト | スクリプト |
| Zellij plugins | `zellij-plugins/` | 自作プラグイン（Rust） | cargo |

`darwin/home-manager/` と `nixos/home-manager/` は OS 固有 / OS 差分が大きいモジュールのみを残し、共通モジュールは `modules/home/` に集約済み（両 flake が `dotfiles-shared` input 経由で同じソースを取り込む）。

### `modules/home/` に集約済みの共通モジュール
- `alacritty/`, `atuin/`, `cz-git/`, `editorconfig/`, `helix/`, `lazygit/`, `sheldon/`, `starship/`, `tmux/`, `yazi/`, `zed/`
- `claude/`, `gemini/`, `git/`, `mise/`, `zellij/`
  - うち `mise/config.toml` と `zellij/config.kdl` は `pkgs.stdenv.isDarwin` で差分を Nix 側から差し替え

### Darwin 専用 HM モジュール（`darwin/home-manager/`）
- `aerospace/` … タイル型ウィンドウマネージャ（macOS）
- `borders/` … JankyBorders 連携
- `cmux/` … cmux 連携 + difit-cmux スクリプト

### NixOS 専用 HM モジュール（`nixos/home-manager/`）
- `fcitx5/` … 日本語入力
- `hyprland/` … Wayland WM

### OS 差分が大きく OS 固有のまま残しているモジュール
- `ghostty/` … `config/config` に macOS 専用 3 行 + `pwd.nix` を経由する `mkOutOfStoreSymlink` のパス差
- `packages/packages.nix` … OS 専用パッケージ（bubblewrap / lmstudio / git-credential-manager 等）
- `shell/zsh/config/*` … macOS 専用ウィジェット、Linux 専用 asdf 設定、Zellij 起動条件
- `pwd.nix` … home 配下のパスのみ違う（ghostty が消費）

## 2. Darwin の構成

```
darwin/
├── flake.nix              entrypoint（aarch64-darwin / x86_64-darwin 自動検出）
├── default.nix            "all" 設定: common + homebrew + system
├── common.nix             nix 設定、primaryUser、homebrew.user 等
├── homebrew/              brew tap / brews / casks / mas
├── system/                NSGlobalDomain / dock / trackpad 等の system.defaults
└── home-manager/          ユーザ環境（Home Manager 単独 apply 可）
    ├── default.nix
    ├── packages/          systemPackages 一覧
    ├── shell/zsh/         zsh 設定（envalues, functions, keybinds, path, zellij）
    └── <tool>/            tool 別モジュール（alacritty/atuin/mise/zellij/…）
```

flake outputs:
- `homeConfigurations.home` … `make home-manager-apply` で適用
- `darwinConfigurations.all` … `make nix-darwin-apply` で適用（system + homebrew 一括）
- `darwinConfigurations.homebrew` / `darwinConfigurations.system` … 部分適用用

`nixvim-config` は input として `git+file:..?dir=nixvim` から取り込む（CI では `--override-input` でローカルパスに差し替え）。

## 3. NixOS の構成

```
nixos/
├── flake.nix              entrypoint（x86_64-linux 固定）
├── configuration.nix      system モジュール集約（imports）
├── hardware-configuration.nix
├── system/                共通システム設定
├── desktop/               GNOME / Hyprland / Wofi / Waybar / Dunst
├── services/              fileserver(Samba/NFS) / gitserver / tailscale / ollama
├── storage/               filesystem mounts / directories
├── packages/              cursor AppImage 抽出パッケージ等
└── home-manager/          ユーザ環境（NixOS module 経由で統合）
```

flake outputs:
- `nixosConfigurations.desktop` … `make nixos-switch` で適用（HM 自動統合）

Home Manager は NixOS の `users.miyoshi_s` に `useGlobalPkgs = true` で統合される。`make home-manager-apply` のような独立適用は darwin 側のみの体系。

## 4. Nixvim

```
nixvim/
├── flake.nix              nixvim パッケージと HM モジュールを export
└── config/
    ├── default.nix
    ├── options.nix / keymaps.nix / colorschemes.nix
    └── plugins/           ui / editor / lsp / completion / git / markdown
```

outputs:
- `packages.<system>.default` … `nix run ./nixvim` で起動できる Neovim パッケージ
- `homeManagerModules.default` … darwin/nixos の HM から `imports` で取り込み

`darwin/flake.nix` と `nixos/flake.nix` の `nixvim-config` input が指す先がこれ。

## 5. Windows CTF

完全独立スコープ。Nix を使わず apt + bash + manifest 駆動。

```
windows-ctf/
├── Makefile               独自タスクランナー
├── manifests/             apt パッケージ・カテゴリ別バンドル
├── scripts/               bootstrap / install / sync / verify
├── config/                bash / starship / atuin / claude config
└── host-windows/          komorebi + AutoHotkey + Ghostty + Flow Launcher
```

CI は `windows-host.yml` が `bash -n` で構文チェック + ダミー bootstrap を実行する。

## 6. AI スキル

`.claude/skills/<skill-name>/SKILL.md` 形式。Claude Code から `/skill-name` で呼び出せるし、人間が直接 markdown として読める。

スキル一覧:
- セットアップ系: `installation`, `nix-operations`, `mise-guide`, `languages-setup`, `npm-tools`, `pre-commit-guide`
- エディタ系: `vscode-setup`, `cursor-setup`, `nixvim-cheatsheet`
- ターミナル/シェル系: `atuin-guide`, `zoxide-guide`, `zellij-worktree`
- WM 系: `services-guide`, `hyprland-cheatsheet`, `nixos-keybindings`
- サーバ系: `fileserver-guide`, `gitserver-guide`, `tailscale-acl`
- メタ: `sync-docs`

## 7. CI ワークフロー

| ワークフロー | トリガ | 内容 |
|-------------|--------|------|
| `.github/workflows/darwin.yml` | `darwin/`, `nixvim/`, `Makefile`, `vscode/`, `scripts/` | HM apply, mise install, nix-darwin build, nixvim build, `make nix-check-all-ci`, vscode apply/save |
| `.github/workflows/nixos.yml` | `nixos/`, `nixvim/` | NixOS toplevel build, nixvim build（GC 挟む） |
| `.github/workflows/windows-host.yml` | `windows-ctf/` | bash 構文チェック + setup スクリプトのドライラン |

Renovate と Dependabot がそれぞれ動いて mise / GitHub Actions を更新する。

## 8. データの流れ（macOS の例）

1. ユーザが `make home-manager-apply` を実行
2. Make が `flake-update-darwin` で `darwin/flake.lock` を更新
3. `cd darwin && nix build path:.#homeConfigurations.home.activationPackage --override-input nixvim-config ../nixvim`
4. `./result/activate` で `~/` 配下のシンボリックリンクと activation script が走る
5. `home.activation.mergeNpmrc` がベース `.npmrc` と `~/.npmrc_local` をマージ
6. `.local/bin/zellij-*` 等の自作スクリプトも展開される

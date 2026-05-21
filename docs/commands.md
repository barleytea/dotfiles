# Commands

`make help` で日本語の対話的ヘルプ（`less`）が開く。`make help-fzf` なら fzf で選択 → 実行できる。

ここでは目的別に主要ターゲットを整理する。**全ターゲットは Makefile の `## コメント` を SoT とする**。

## 1. Nix（macOS / nix-darwin）

| ターゲット | 説明 | flake.lock 更新 |
|------------|------|-----------------|
| `make home-manager-apply` | HM 設定を適用（推奨） | ✅（事前に `flake-update-darwin`） |
| `make home-manager-switch` | HM 設定を適用（lock 更新なし） | ❌ |
| `make home-manager-build` | ビルドのみ | ❌ |
| `make nix-darwin-apply` | nix-darwin の `all` 設定を適用 | ❌（apply 時は更新せず） |
| `make nix-darwin-homebrew-apply` | Homebrew 設定のみ | ❌ |
| `make nix-darwin-system-apply` | system.defaults のみ | ❌ |
| `make nix-darwin-check` | ビルドチェックのみ | ❌ |
| `make nix-update-all` | チャンネル更新 + HM apply + nix-darwin apply | ✅ |
| `make nix-check-all` | チャンネル更新 + HM apply + nix-darwin check（ローカル CI 相当） | ✅ |
| `make nix-check-all-ci` | チャンネル更新 + HM switch + nix-darwin check（CI 用、lock 更新なし） | ❌ |

> ⚠️ `home-manager-apply` は内部で `flake-update-darwin` を呼ぶ副作用がある（lock を必ず更新する）。lock を変えたくないときは `make home-manager-switch` を使うこと。

## 2. Nix（NixOS）

| ターゲット | 説明 |
|------------|------|
| `make nixos-switch` | システム設定（HM 含む）を適用 |
| `make nixos-build` | ビルドのみ |

NixOS 側には `home-manager-apply` 相当のターゲットは無い（HM は system flake に統合済み）。

## 3. flake.lock 操作

| ターゲット | 対象 |
|------------|------|
| `make flake-update-darwin` | `darwin/flake.lock` |
| `make flake-update-nixos` | `nixos/flake.lock` |
| `make flake-update-nixvim` | `nixvim/flake.lock` |
| `make flake-update-all` | 上記 3 つを順次 |

`flake-update-*` は専用ブランチで行い、機能変更を伴う PR には混ぜないこと。

## 4. Nix メンテナンス

| ターゲット | 説明 |
|------------|------|
| `make nix-channel-update` | nixpkgs-unstable に更新 |
| `make nix-gc` | `sudo nix-collect-garbage -d` |
| `make nix-uninstall` | Nix の完全アンインストール |

## 5. Nixvim（スタンドアロン）

`nix run ./nixvim` で起動。flake のみ管理対象で、Make ターゲットは `flake-update-nixvim` のみ。

## 6. pre-commit

| ターゲット | 説明 |
|------------|------|
| `make pre-commit-init` | フックをインストール（mise 経由） |
| `make pre-commit-run` | 全ファイルに対し実行 |

設定は `.pre-commit-config.yaml`。`gitleaks` で秘密情報スキャン、基本フックで trailing whitespace / EOL fixer / YAML check 等。

## 7. VSCode

| ターゲット | 説明 |
|------------|------|
| `make vscode-apply` | 設定と拡張機能を適用 |
| `make vscode-insiders-apply` | Insiders 版に同じ操作 |
| `make vscode-save` | 現在の拡張機能一覧を保存 |
| `make vscode-sync` | 設定を同期 |

## 8. mise

| ターゲット | 説明 |
|------------|------|
| `make mise-install-all` | mise 管理ツール全てをインストール |
| `make mise-install-npm-commitizen` | commitizen / cz-git を global インストール |
| `make mise-run-safe-chain-setup` | aikido safe-chain のセットアップ |
| `make mise-update-npm-tools` | npm CLI の pin を min-age 制約付きで最新化（`MISE_NPM_MIN_AGE_DAYS` で日数指定可、デフォルト 7） |
| `make mise-list` | ツール一覧 |
| `make mise-config` | mise の設定表示 |

## 9. その他ユーティリティ

| ターゲット | 説明 |
|------------|------|
| `make zsh` | zsh の起動時間を測定 |
| `make paths` | `$PATH` を改行区切りで表示 |
| `make windows-ctf-help` | `windows-ctf/Makefile` のヘルプを呼ぶ |
| `make windows-host-help` | Windows ホスト UX ガイドの場所表示 |
| `make windows-ctf-dump-wt-settings` | Windows Terminal 設定を dotfiles に dump |

## 10. 環境変数

| 変数 | 既定値 | 用途 |
|------|--------|------|
| `NIX_PROFILE` | 自動検出 | Nix 環境変数 source 元の `profile.d` スクリプト |
| `NIXVIM_CONFIG_INPUT` | `path:../nixvim` | flake input `nixvim-config` の override 先（CI で `${{ github.workspace }}/nixvim` を渡す） |
| `MISE_NPM_MIN_AGE_DAYS` | `7` | `mise-update-npm-tools` の min-age 日数 |

## 11. CI 想定の使い分け

| シナリオ | ローカル | CI |
|----------|----------|----|
| macOS PR 検証 | `make nix-check-all` | `make nix-check-all-ci`（lock 更新を伴わない） |
| NixOS PR 検証 | `make nixos-build` | `nix build path:.#nixosConfigurations.desktop.config.system.build.toplevel ...` を直接実行 |
| nixvim PR 検証 | `nix build ./nixvim` | `nix build .#packages.<system>.default --no-write-lock-file` |

## 12. 検証のおすすめフロー

変更を加えたら最低でも以下を実行する:

1. 影響範囲の OS で `*-check` / `*-build` を通す（apply はまだしない）
2. `make pre-commit-run` で lint と gitleaks
3. 問題なければ apply
4. 挙動が変わったら `AGENTS.md` / `docs/architecture.md` / `docs/commands.md` を同期更新

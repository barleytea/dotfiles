---
name: npm-tools
description: NPM tools and package management using mise including commitizen, cz-git, and global package configuration
---

# npm tools

[Install npm tools](#install-npm-tools)

## .npmrc の管理方法

`.npmrc` はシークレット（`_authToken` 等）を含むため、**ベース設定（Nix管理）＋ローカル設定（手動管理）の合成**で管理します。

### 設計方針

| ファイル | 管理者 | 内容 |
|---------|--------|------|
| `~/.npmrc` | activation script が自動生成 | 最終的に使われるファイル |
| Nix store (npmrcBase) | Nix管理（darwin/nixos default.nix） | 非シークレット設定（prefix, min-release-age） |
| `~/.npmrc_local` | ユーザーが手動管理 | シークレット専用（`_authToken` 等） |

### 初回セットアップ

```sh
# 既存の ~/.npmrc をシークレット専用ファイルにリネーム
mv ~/.npmrc ~/.npmrc_local

# ~/.npmrc_local にはシークレットのみ残す（例）
# tokyucorp:registry=https://npm.pkg.github.com
# //npm.pkg.github.com/:_authToken=YOUR_TOKEN

# home-manager 適用で activation script が ~/.npmrc を自動生成
make home-manager-apply
```

### 生成される ~/.npmrc（activation 後）

```
prefix=/Users/miyoshi_s/.npm-global
min-release-age=7
tokyucorp:registry=https://npm.pkg.github.com
//npm.pkg.github.com/:_authToken=YOUR_TOKEN
```

### 注意事項

- `prefix` は Nix activation script が自動で設定するため、手動で `npm config set prefix` は不要
- `~/.npmrc_local` が存在しない場合はベース設定のみで `~/.npmrc` を生成（エラーにならない）
- `_authToken` などシークレットは絶対に Nix store（dotfiles リポジトリ）に含めないこと

## Create directory for global npm packages

```sh
# ~/.npm-global ディレクトリは自動作成されるが、手動で作る場合:
mkdir -p ~/.npm-global
# ※ prefix は Nix activation script で自動設定されるため npm config set は不要
```

## Install npm tools

### 方法1: mise タスクを使用（推奨）

```sh
# commitizen + cz-git をグローバルにインストール
make mise-install-npm-commitizen

# または直接 mise を使用
mise run npm-commitizen

# mise で管理している全ツールをインストール
make mise-install-all
```

### 方法2: 従来のnpmコマンド

```sh
# 非推奨: 代わりに上記の mise タスクを使用
make npm-tools
```

## mise で管理されているツール

### ツール一覧の確認

```sh
# インストールされているツール一覧
make mise-list

# mise の設定確認
make mise-config
```

### 管理対象ツール

- **Node.js**: `lts`
- **Go**: `1.23.4`
- **NPMパッケージ（mise管理）**:
  - `@redocly/cli`
  - `corepack`
  - `@anthropic-ai/claude-code`
  - `@google/gemini-cli`
- **NPMパッケージ（グローバルインストール）**:
  - `commitizen`
  - `cz-git`

## commitizen & cz-git

### Usage

```sh
git cz
```

または

```sh
cz
```

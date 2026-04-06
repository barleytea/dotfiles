# safe-chain Guide

Aikido safe-chain セキュリティツールのセットアップと設定ガイド。

---

## What is safe-chain?

[Aikido safe-chain](https://github.com/AikidoSec/safe-chain) は、`npm install` / `pip install` / `bun add` などのパッケージマネージャーコマンドをラップして、マルウェアや supply chain 攻撃から保護するセキュリティツール。

ラップ対象: `npm`, `npx`, `yarn`, `pnpm`, `pnpx`, `bun`, `bunx`, `pip`, `pip3`, `uv`, `poetry`, `python`, `python3`, `pipx`

---

## インストール

mise で管理（`~/.config/mise/config.toml`）：

```toml
[tools]
"npm:@aikidosec/safe-chain" = "latest"

[tasks.safe-chain-setup]
description = "Set up aikido safe-chain (CA cert + npm proxy)"
run = ["safe-chain setup"]
```

```bash
# インストール
mise install "npm:@aikidosec/safe-chain"

# CA証明書のセットアップ（初回のみ）
mise run safe-chain-setup
```

---

## zsh への統合

**重要**: safe-chain の init スクリプトは `~/.zshrc_local` に追加する。
`~/.config/zsh/.zshrc` は Home Manager が管理するため直接編集しない。

```bash
# ~/.zshrc_local に追記
echo 'source ~/.safe-chain/scripts/init-posix.sh' >> ~/.zshrc_local
```

`~/.zshrc_local` の例：
```zsh
export USE_NIXVIM=true

# Safe-chain Zsh initialization script
source ~/.safe-chain/scripts/init-posix.sh
```

`~/.config/zsh/.zshrc`（Home Manager 管理）は以下の内容で、最後に `~/.zshrc_local` を読み込む：
```zsh
# Load all configuration files
for config_file ($ZDOTDIR/config/*.zsh) source $config_file
for tool_config ($ZDOTDIR/config/tools/*.zsh) source $tool_config

# Load local configuration if exists
if [[ -f ~/.zshrc_local ]]; then
  source ~/.zshrc_local
  echo "[zsh] Local configuration loaded"
fi
```

---

## セットアップ後の確認

```bash
# safe-chain が使えるか確認
command -v safe-chain

# PATH に bin が通っているか確認（init-posix.sh が追加）
echo $PATH | tr ':' '\n' | grep safe-chain

# CA証明書の確認
ls ~/.safe-chain/certs/
# → ca-cert.pem  ca-key.pem
```

---

## トラブルシューティング

### `.zshrc` が safe-chain に上書きされた場合

`safe-chain setup` が `~/.config/zsh/.zshrc` を書き換えてしまった場合の修復手順：

```bash
# 1. safe-chain の init を ~/.zshrc_local に移動（まだなければ追記）
echo 'source ~/.safe-chain/scripts/init-posix.sh' >> ~/.zshrc_local

# 2. Home Manager で .zshrc を正しい内容に戻す
make home-manager-apply
```

### `EPERM: operation not permitted` エラー

`safe-chain setup` 実行時に CA 証明書ファイルへの書き込みが拒否される場合：

```bash
# 権限確認
ls -la ~/.safe-chain/certs/

# 権限修正して再実行
chmod 600 ~/.safe-chain/certs/ca-key.pem
mise run safe-chain-setup
```

---

## ファイル構成

```
~/.safe-chain/
├── certs/
│   ├── ca-cert.pem   # CA証明書（公開鍵）
│   └── ca-key.pem    # CA秘密鍵
└── scripts/
    └── init-posix.sh # zsh 用の初期化スクリプト（関数定義 + PATH 追加）
```

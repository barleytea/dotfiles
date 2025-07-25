# VSCode-Neovim 設定同期システム

このディレクトリには、VSCodeとNeovimの設定を同期するための各種ファイルが含まれています。

## 主要ファイル

- `settings.json` - VSCodeの設定ファイル
- `keybindings.json` - VSCodeのキーバインド設定
- `neovim-keymaps.json` - Neovim連携時の追加キーマップ設定
- `neovim-init.sh` - Neovim初期化スクリプト
- `index.sh` - VSCode標準版へのシンボリックリンク作成スクリプト
- `index_insiders.sh` - VSCode Insiders版へのシンボリックリンク作成スクリプト
- `sync.sh` - VSCodeとNeovimの設定同期スクリプト

## 同期システムの使い方

### justコマンドを使う方法（推奨）

リポジトリのルートディレクトリで以下のコマンドを実行できます：

```bash
# VSCode用のNeovim初期化ファイルを生成
make vscode-neovim-init

# VSCodeとNeovimの設定を同期
make vscode-sync

# VSCode設定をシンボリックリンクで適用
make vscode-apply
```

### 初期セットアップ

1. Home Managerで同期ツールをインストール:

```nix
modules.neovim-vscode-sync = {
  enable = true;
  autoSync = true;  # 自動同期する場合はtrue
};
```

2. 設定の初期化:

```bash
# Neovim初期化ファイルを生成
./neovim-init.sh
# または
make vscode-neovim-init

# VSCodeと設定を同期
sync-editor-settings
# または
make vscode-sync
```

### 日常的な使用方法

1. VSCode設定を変更した場合:

```bash
# 設定を同期して反映
make vscode-sync
```

2. Neovimの設定を更新した場合も同様:

```bash
make vscode-sync
```

## 仕組み

このシステムは以下のファイル間で設定を同期します:

- VSCode: `settings.json`, `keybindings.json`
- Neovim: `~/.config/nvim/lua/shared/common.lua`, `~/.config/nvim/vscode.lua`

以下のような共通設定が同期されます:

- キーバインド設定
- エディタの見た目（フォント、テーマなど）
- 基本的な編集挙動（タブサイズ、ワードラップなど）

## トラブルシューティング

問題が発生した場合は以下を確認してください:

1. バックアップファイル (`*.bak`) を確認して復元する
2. ログメッセージをチェックして問題を特定する
3. `~/.config/nvim/vscode.lua` ファイルが正しく生成されているか確認する
4. 設定同期後、VSCodeとNeovimを再起動する

## カスタマイズ

カスタム設定を追加するには:

1. `settings.json` - VSCode固有の設定
2. `~/.config/nvim/init.lua` - Neovim固有の設定
3. `home-manager/shared-config/editor-core.nix` - 共通設定

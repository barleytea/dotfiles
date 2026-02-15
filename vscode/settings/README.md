# VSCode 設定同期

このディレクトリには、VSCode の設定を管理・同期するためのファイルが含まれています。

## 主要ファイル

- `settings.json` - VSCode の設定ファイル
- `keybindings.json` - VSCode のキーバインド設定
- `index.sh` - VSCode 標準版へのシンボリックリンク作成スクリプト
- `index_insiders.sh` - VSCode Insiders 版へのシンボリックリンク作成スクリプト
- `sync.sh` - リポジトリ内設定を VSCode ユーザー設定ディレクトリへ同期するスクリプト

## 使い方

```bash
# VSCode設定をシンボリックリンクで適用
make vscode-apply

# VSCode設定ファイルをユーザー設定へ同期
make vscode-sync
```

## トラブルシューティング

1. `*.bak` バックアップを確認して復元する
2. `make vscode-sync` 実行時のログを確認する
3. 設定適用後に VSCode を再起動する

# Cursor for NixOS

このディレクトリには、NixOS用のCursor AI Code Editorの設定が含まれています。

## 機能

- AppImageからCursorをビルド
- デスクトップエントリの自動生成
- アイコンの自動インストール
- 最新版への更新が容易

## バージョン更新方法

最新版のCursorをインストールするには、以下の手順を実行してください：

### 1. 最新版のダウンロードURLとハッシュを取得

[Cursor公式ダウンロードページ](https://cursor.com/download)で最新版を確認後、以下のコマンドでハッシュを計算：

```bash
# 最新版のURLを確認（例: https://downloads.cursor.com/production/...）
nix-prefetch-url https://downloads.cursor.com/production/RELEASE_ID/linux/x64/Cursor-VERSION-x86_64.AppImage
```

### 2. default.nixを更新

`default.nix`の以下の部分を更新：

```nix
let
  pname = "cursor";
  version = "0.50.5";  # 最新バージョンに変更

  src = pkgs.fetchurl {
    url = "https://downloads.cursor.com/production/RELEASE_ID/linux/x64/Cursor-VERSION-x86_64.AppImage";  # 最新URLに変更
    hash = "sha256-...";  # nix-prefetch-urlで取得したハッシュに変更
  };
```

### 3. システムを再ビルド

```bash
sudo nixos-rebuild switch --flake /path/to/dotfiles#desktop
```

## 使用方法

設定を適用すると、以下のコマンドでCursorを起動できます：

```bash
cursor
```

または、アプリケーションメニューから「Cursor」を選択してください。

## トラブルシューティング

### ハッシュミスマッチエラー

ビルド時にハッシュエラーが発生した場合：

1. エラーメッセージに表示される正しいハッシュをコピー
2. `default.nix`の`hash`フィールドを更新
3. 再度ビルドを実行

### AppImageが起動しない

- AppImageサポートが有効になっているか確認：`nixos/packages/appimages.nix`がインポートされているか
- 必要な依存関係がインストールされているか確認

## 参考

- [Cursor公式サイト](https://cursor.com)
- [参考実装](https://github.com/bloodstiller/dotfiles/blob/main/packages/cursor/cursor.nix)

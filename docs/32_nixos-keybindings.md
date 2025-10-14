# NixOS keyboard shortcuts

macOS 風に `Super`（⌘）キーを扱うための仕組みと、関連モジュールの参照先をまとめています。

## Keyd で Super ショートカットを補完

- File: `nixos/desktop/common.nix:27`
- `services.keyd` を有効化し、左右の `Super` キーを専用レイヤーにして `Super+…` 操作を `Ctrl+…` に送出しています。
- ワークスペース切替（`Super+1-0` や `Super+Shift+1-0`）、ウィンドウ操作（`Super+Shift+V/E/M/Q/L`、`Super+Space`、`Super+Return` など）は同レイヤーで `Super` にフォワードしているため、Hyprland で従来どおり機能します。
- これにより `Command+C / V / X / Z / A / S / F / P / N / T / W / Q / L / O`、`Command+Shift+Z`、`Command+,`、`Command+Tab / Command+Shift+Tab` がそのまま Linux アプリでも動作します。
- Control キー自体の挙動は変えていないため、`Ctrl+…` 系ショートカットは従来どおり利用できます。

## デスクトップ別の注意点

### GNOME

- File: `nixos/desktop/gnome-albert.nix:11`
- Spotlight 風にするため `Super+Space`（⌘+Space）で Albert を起動。GNOME の overlay key は無効化済みです。

### Hyprland

- File: `nixos/desktop/hyprland/config.nix:107`
- ウィンドウ操作に使っていた文字キーとの組み合わせは `Super+Shift+…` や `Super+Return` に移動しています（例: `Super+Return` で Alacritty、`Super+Shift+C` でウィンドウを閉じる）。
- 詳細なキー一覧は `docs/hyprland-cheatsheet.md` を参照してください。
- File: `home-manager/alacritty/default.nix:45`
- Alacritty でも `Ctrl+V/C` で貼り付け・コピーできるようキーバインドを追加しています（Command 経由の送出を想定）。

## 日本語入力の切り替え

- fcitx5 のデフォルト通り `Ctrl+Space` で IME を切り替えます。
- `Super+Space` はランチャー用に確保しているため、IME 用には利用しません。

## 適用手順

1. 必要な編集を反映する。
2. `sudo nixos-rebuild test --flake .#<host>` で検証（あるいは `build` でビルドのみ）。
3. 問題なければ `sudo nixos-rebuild switch --flake .#<host>` で適用。

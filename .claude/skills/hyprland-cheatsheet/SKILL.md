---
name: hyprland-cheatsheet
description: Hyprland window manager shortcuts including window navigation, workspace management, media keys, and configuration files
---

# Hyprland チートシート

## 基本操作

| キー | 動作 |
|------|------|
| `Super + Return` | ターミナル（Alacritty）を開く |
| `Super + Shift + Q` | アクティブウィンドウを閉じる |
| `Super + Shift + K` | ウィンドウを強制終了（クリックしたウィンドウを `hyprctl kill`。`killactive` が効かないフリーズしたアプリ向け） |
| `Super + Shift + M` | Hyprlandを終了（ログアウト） |
| `Super + Shift + E` | ファイルマネージャー（Thunar）を開く |
| `Super + Shift + L` | スクリーンロック |

## アプリケーションランチャー

| キー | 動作 |
|------|------|
| `Super + Space` | wofi ランチャー |

## ウィンドウ操作

| キー | 動作 |
|------|------|
| `⌘ (Super) + Shift + V` | クリップボード履歴から貼り付け（Hyprland バインドは `Alt + Shift + V`） |
| `Win（物理Super） + Shift + V` | フローティングモード切替 |
| `Super + Shift + P` | 疑似タイル |
| `Super + J` | 分割方向切替 |

## フォーカス移動

### 矢印キー
| キー | 動作 |
|------|------|
| `Super + ←` | 左のウィンドウにフォーカス |
| `Super + →` | 右のウィンドウにフォーカス |
| `Super + ↑` | 上のウィンドウにフォーカス |
| `Super + ↓` | 下のウィンドウにフォーカス |

### Vimキー
| キー | 動作 |
|------|------|
| `Super + h` | 左のウィンドウにフォーカス |
| `Super + l` | 右のウィンドウにフォーカス |
| `Super + k` | 上のウィンドウにフォーカス |
| `Super + j` | 下のウィンドウにフォーカス |

## ワークスペース操作

| キー | 動作 |
|------|------|
| `Super + 1-9,0` | ワークスペース 1-10 に切り替え |
| `Super + Shift + 1-9,0` | アクティブウィンドウをワークスペース 1-10 に移動 |
| `Super + マウスホイール上` | 前のワークスペース |
| `Super + マウスホイール下` | 次のワークスペース |

## マウス操作

| キー | 動作 |
|------|------|
| `Super + 左クリックドラッグ` | ウィンドウを移動 |
| `Super + 右クリックドラッグ` | ウィンドウをリサイズ |

## スクリーンショット

| キー | 動作 |
|------|------|
| `Print` | 範囲選択スクリーンショット（クリップボードに保存） |
| `Shift + Print` | 全画面スクリーンショット（クリップボードに保存） |

## メディアキー

| キー | 動作 |
|------|------|
| `音量+` | 音量を上げる |
| `音量-` | 音量を下げる |
| `ミュート` | 消音切替 |
| `再生/一時停止` | メディア再生/一時停止 |
| `次の曲` | 次のトラック |
| `前の曲` | 前のトラック |

## 画面輝度

| キー | 動作 |
|------|------|
| `輝度+` | 画面輝度を上げる（+10%） |
| `輝度-` | 画面輝度を下げる（-10%） |

## 自動起動アプリケーション

**systemd user unit 経由**（`graphical-session.target` 配下）:

- Waybar（ステータスバー）
- Hyprpaper（壁紙）
- eww（生活情報ダッシュボード。壁紙レイヤー常駐・操作不可。詳細は `/dashboard-guide`）

**`exec-once` 経由**:

- Dunst（通知デーモン）
- Fcitx5（日本語入力）
- Gammastep（ブルーライトフィルター）
- cliphist（クリップボード履歴の監視）

### graphical-session.target の起動について

**Hyprland は `graphical-session.target` を自動では起動しない。**
`nixos/desktop/hyprland/config.nix` の先頭で

```
exec-once = systemctl --user import-environment WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE XDG_CURRENT_DESKTOP && systemctl --user start hyprland-session.target
exec-shutdown = systemctl --user stop graphical-session.target
```

を実行し、`hyprland-session.target`（`nixos/home-manager/hyprland/default.nix` で定義、
`BindsTo=graphical-session.target`）経由で引き上げている。

この 2 行が無いと `WantedBy = graphical-session.target` のユーザーユニットは
**エラーも出さずに一度も起動しない**（`journalctl --user-unit=<name>` が `No entries` になる）。
新しく常駐プロセスを足すときは、`exec-once` に直接書くのではなく
`graphical-session.target` 配下のユニットにするのが本来の形。

確認:

```bash
systemctl --user status graphical-session.target
systemctl --user list-dependencies graphical-session.target
```

## ターミナルコマンド

| コマンド | 動作 |
|----------|------|
| `hyprctl dispatch exit` | Hyprlandを終了 |
| `hyprctl clients` | アクティブなウィンドウ一覧 |
| `hyprctl workspaces` | ワークスペース一覧 |
| `hyprctl reload` | 設定をリロード |

## 設定ファイル

- メイン設定: `/etc/xdg/hypr/hyprland.conf`
- Waybar設定: `/etc/xdg/waybar/config`
- Dunst設定: `/etc/xdg/dunst/dunstrc`

## テーマと見た目の調整

- Waybar: `nixos/desktop/hyprland/waybar.nix` でモジュール構成・Catppuccin配色を管理。`style.css` 内の `@define-color` を変更すると一括で色が切り替わります。
- ウィンドウ装飾: `nixos/desktop/hyprland/config.nix` の `decoration`・`general` ブロックで丸み・ブラー・ボーダー色を制御。
- 壁紙: `nixos/desktop/hyprland/wallpaper.nix` がグラデーション壁紙を自動生成します。別画像に差し替える場合は `preload`/`wallpaper` 行を書き換え。
- ランチャー: `nixos/desktop/hyprland/wofi.nix` でサイズやフォント、ハイライト色を変更可能。
- 背景ダッシュボード: `nixos/home-manager/dashboard/` の `eww.scss` で配色、`eww.yuck` でレイアウトを変更。`nixos/desktop/hyprland/config.nix` の `# Layer rules` 節に `namespace ^(eww-dashboard)$` 向けの `blur` / `ignore_alpha` / `no_anim` を置いている。

## リロードのショートカット

- Waybar を再起動: `systemctl --user restart waybar`
- ダッシュボードを再起動: `systemctl --user restart eww`
- Hyprland 設定反映: `hyprctl reload`
- Wofi テーマ確認: `wofi --show drun` を都度実行してプレビュー

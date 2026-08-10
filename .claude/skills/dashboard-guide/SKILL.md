---
name: dashboard-guide
description: NixOS/Hyprland desktop dashboard (eww background widget) covering weather, clock, system stats and life info - location changes, data.json schema, keyless API sources, iteration workflow and troubleshooting
---

# 生活情報ダッシュボード（eww 背景ウィジェット）

Hyprland の Wayland layer-shell の **BOTTOM レイヤー**に常駐する非対話ウィジェット。
壁紙より上・ウィンドウより下に描画されるため、デスクトップを見た瞬間に
天気・時刻・システム状態・生活情報が読める。**GNOME セッションでは表示されない**
（wlr-layer-shell が無いため）。

## 構成

| ファイル | 役割 |
|----------|------|
| `nixos/home-manager/dashboard/default.nix` | 唯一の Nix モジュール。地域パラメータ・ユニット・設定ファイル配置 |
| `nixos/home-manager/dashboard/eww.yuck` | ウィジェット定義 |
| `nixos/home-manager/dashboard/eww.scss` | スタイル（Waybar のグラステーマと配色を揃えてある） |
| `nixos/home-manager/dashboard/fetch.sh` | ネットワークからのデータ取得（10 分間隔） |
| `nixos/home-manager/dashboard/live.sh` | 時刻・温度・メモリ・ディスク・稼働時間（5 秒間隔） |
| `nixos/home-manager/dashboard/gpu.sh` | GPU 温度（60 秒間隔） |
| `nixos/home-manager/dashboard/data.sh` | `data.json` を eww に渡す（60 秒間隔） |

Hyprland 側の `layerrule` は `nixos/desktop/hyprland/config.nix` の `# Layer rules` 節。

```
[dashboard-fetch.timer] --10分--> [dashboard-fetch.service]
                                        |
                                  ~/.cache/dashboard/data.json
                                        |
[eww.service] --defpoll--> dashboard-data / dashboard-live / dashboard-gpu
                                        |
                          layer-shell surface (BOTTOM, namespace=eww-dashboard)
```

## 地域を変更する

`nixos/home-manager/dashboard/default.nix` の `location` attrset **1 箇所だけ**を書き換える。

```nix
location = {
  label = "川崎";
  latitude = "35.5308";
  longitude = "139.7029";
  jmaAreaCode = "140000";      # 府県予報区コード（気象警報・注意報の取得単位）
  jmaWarningArea = "1413000";  # 市町村等をまとめた地域コード。"" にすると県全域を集約
};
```

`jmaWarningArea` に実在しないコードを入れると警報欄が常に「発表中なし」になる。
実際に使えるコードは次で確認する。

```bash
curl -s https://www.jma.go.jp/bosai/warning/data/warning/140000.json |
  jq -r '[.areaTypes[].areas[].code] | unique'
```

Hyprland の `gammastep` も座標を持つ（`nixos/desktop/hyprland/config.nix` の
`exec-once = gammastep -l ...`）。こちらは独立しているので、地域を変えるときは併せて見る。

ディスクの監視対象を変えるときは同じファイルの `diskTargets`。

## data.json のスキーマ

`~/.cache/dashboard/data.json`。取得に失敗したセクションは **前回値がそのまま残る**
（`jq` の `*` による deep merge）。`.meta.sections` にはその回に取得できたセクション名だけが入る。

| セクション | 主なキー |
|------------|----------|
| `weather` | `place`, `sunLabel`, `current.{icon,label,temp,apparent,humidity,wind,pop}`, `daily[].{day,dow,icon,max,min,pop}` |
| `warnings` | `items[]`, `active`, `label` |
| `quake` | `items[].{at,place,mag,maxi}` |
| `holiday` | `today`, `next`, `active`, `label` |
| `fx` | `usdjpy`, `label` |
| `news` | `items[].title` |
| `meta` | `fetchedAt`（UNIX 秒）, `fetchedAtLabel`（表示用）, `sections[]` |

**表示用の文字列はすべてシェル側で完成させている**。eww の式言語で日付整形や単位付けを
しないのは、`formattime` / `formatbytes` の引数仕様が eww のバージョンに依存するため。
新しい項目を足すときもこの方針を守る。

## データソース（すべて API キー不要）

| 用途 | エンドポイント |
|------|----------------|
| 天気・気温・週間予報・日の出入り | `https://api.open-meteo.com/v1/forecast` |
| 気象警報・注意報 | `https://www.jma.go.jp/bosai/warning/data/warning/<areaCode>.json` |
| 地震情報 | `https://www.jma.go.jp/bosai/quake/data/list.json` |
| 祝日 | `https://holidays-jp.github.io/api/v1/date.json` |
| 為替（USD/JPY） | `https://open.er-api.com/v6/latest/USD` |
| ニュース | `https://www.nhk.or.jp/rss/news/cat0.xml` |

- **天気状態の真実の源は Open-Meteo の WMO `weather_code` 一本**。アイコンと日本語ラベルの
  マッピング表は `fetch.sh` の `WMO` 変数 1 箇所だけにある。気象庁の予報 API は使わない
  （マッピング表を 2 つ持たないため）
- アイコンは Nerd Font の Weather Icons（U+E300 台）。`Hack Nerd Font` に収録済みなので
  追加フォントは不要。ソースには生グリフを置かず `\uXXXX` エスケープで書く
- `curl` は `--max-time 10 --retry 1`、識別可能な `User-Agent` 付き。タイマーには
  `RandomizedDelaySec = "2min"` を入れて気象庁へのアクセスが同じ秒に集中しないようにしている
- Open-Meteo に `models=` は付けない（複数モデル指定時にフィールド名へサフィックスが付くため）

## 表示を反復して調整する

eww の設定監視は `Modify` イベントしか見ないため、Home Manager の symlink 差し替えでは
ホットリロードされない。リビルドせずに詰めるときは別の設定ディレクトリを使う。

```bash
systemctl --user stop eww          # 本番インスタンスを止める（重なり防止）
mkdir -p ~/eww-dev
cp -L ~/.config/eww/eww.yuck ~/.config/eww/eww.scss ~/eww-dev/
chmod +w ~/eww-dev/*
eww --config ~/eww-dev --force-wayland daemon --no-daemonize &
eww --config ~/eww-dev open dashboard
# 以後 ~/eww-dev のファイルを編集して保存すると自動リロードされる
eww --config ~/eww-dev kill
# 満足したら内容をリポジトリの eww.yuck / eww.scss に戻す
make nixos-switch
systemctl --user start eww
```

`make nixos-switch` 後に見た目が変わらない場合は `systemctl --user restart eww`。
ユニットには `X-Restart-Triggers` を入れてあるので通常は sd-switch が再起動する。

## トラブルシュート

```bash
# ユニットの状態
systemctl --user status eww.service
systemctl --user list-timers dashboard-fetch.timer

# データ取得を即時実行してログを見る
systemctl --user start dashboard-fetch.service
journalctl --user -t dashboard-fetch -n 80 --no-pager

# どのセクションが取れたか
jq '.meta' ~/.cache/dashboard/data.json

# yuck / scss のエラーはここに出る
eww logs
eww ping
eww state          # defpoll 変数の現在値
eww inspector      # GTK インスペクタで CSS を実地デバッグ

# レイヤーが正しい位置にいるか（namespace / layer / 座標）
hyprctl layers | grep -A8 eww-dashboard

# 各スクリプトを単体で叩く
dashboard-live | jq .
dashboard-gpu
dashboard-data | jq '.meta'
```

| 症状 | 原因と対処 |
|------|-----------|
| 何も表示されず `journalctl --user-unit=eww.service` が `No entries` | ユニットが**一度も起動されていない**。`systemctl --user status graphical-session.target` を確認する。inactive なら `hyprland-session.target` を起動する `exec-once` が効いていない（`/hyprland-cheatsheet` の該当節を参照）。`data.json` だけ更新されるのは、フェッチが `timers.target` 配下で target に依存しないため |
| 何も表示されない（ユニットは起動済み） | GNOME セッションで起動していないか確認（Hyprland 専用）。`eww logs` にパースエラーが出ていないか |
| ウィンドウが開かない | `hyprctl monitors` でモニタが 1 枚か確認。`eww.yuck` の `:monitor 0` を実際の索引に合わせる |
| `:focusable "none"` でパースエラー | eww のバージョンによっては真偽値。`:focusable false` に変える |
| 天気だけ `--` | Open-Meteo のフィールド名が変わった可能性。`curl` して `fetch.sh` の jq を合わせる |
| GPU 温度が `--` | `/run/current-system/sw/bin/nvidia-smi` が動くか確認。動かないなら `eww.yuck` の該当行を落とす |
| フッターが赤い | 30 分以上データが更新されていない。`journalctl --user -t dashboard-fetch` を見る |

## 実装上の落とし穴（編集するときに踏むやつ）

- **`graphical-session.target` は Hyprland が自動起動しない。** `hyprland.conf` の
  `exec-once` から `hyprland-session.target` を起動して初めて配下のユニットが動く。
  この仕込みが無いと、ユニットは正しく配置されていてもエラーすら出さずに沈黙する
  （`journalctl --user-unit=eww.service` が `No entries`）。詳細は `/hyprland-cheatsheet`

- **`for` は container の直接の子でなければならない。** `defwidget` の `(children)` 経由で
  `for` を渡すと eww が
  `This widget can only be used as a child of some container widget such as box` で
  ウィンドウを開けず、`ExecStartPost` の失敗 → `Restart=on-failure` → `StartLimitBurst` 到達で
  ユニットが停止する（復帰には `systemctl --user reset-failed eww`）。
  `card` の中で `for` を使うときは必ず `box` で包む
- **window 名と同じ CSS クラス名に見た目を持たせない。** eww は window 名（`dashboard`）を
  GtkWindow と root widget の**両方**にクラスとして付けるため、`.dashboard` に border や
  padding を書くと枠が二重になる。見た目は `.dashboard-body` 側に置いている
- **全ソースが失敗した回は `data.json` を書き換えない。** `meta.fetchedAt` を更新してしまうと
  「データが古い」判定（フッターが赤くなる）が永久に発火しなくなるため、
  `fetch.sh` は取得できたセクションが 0 件なら何も書かずに `exit 1` する
- **静的な内容（Hyprland のキーバインド一覧など）は defpoll にせず `eww.yuck` に直接埋め込む。**
  ショートカットカード（`keybinds-card`）が該当。ビルド時に固定される値のために
  取得スクリプト・timer・キャッシュファイルを新設するのはやりすぎ（YAGNI）。
  一覧の元ネタは `nixos/desktop/hyprland/config.nix` の `bind` と `/hyprland-cheatsheet`
- **時刻・単位の整形を yuck 側でやらない。** `formattime` / `formatbytes` / `EWW_DISK` /
  `EWW_RAM` は eww のバージョンで引数仕様やキー名が変わりうるため、
  `live.sh` / `fetch.sh` 側で完成した文字列を作って渡している。
  yuck が依存している eww 機能は `defpoll` / `for` / `round` / `EWW_CPU.avg` /
  safe-access `?.` / elvis `?:` / 文字列補間だけ
- **`fetch.sh` だけ `excludeShellChecks = ["SC2016"]` が必要。** jq プログラムを `add`
  ラッパー経由で渡しているので、shellcheck が「jq への引数」と認識できず
  単一引用符内の `$var` に SC2016 を出す。`jq` を直接呼んでいる `live.sh` / `data.sh` は不要

## 既知の制約

- **クリックのパススルーは原理的にできない。** Hyprland は BOTTOM レイヤーの surface にも
  ポインタフォーカスを送り、eww / gtk-layer-shell 側に input region を空にする設定は無い。
  `button` / `eventbox` / `:onclick` / `:tooltip` / `:hover` CSS / `calendar` を
  **一切使わない**という規律で「押しても何も起きない」ことを担保している。
  `:onclick` を足したくなった時点でこの前提が崩れる
- `:focusable "none"` によりキーボードフォーカスは取らないので、キーバインドは全て生きる
- `pkgs.eww` は unstable スナップショット。`make flake-update-nixos` で yuck の互換性が
  壊れる可能性がある（特に `defwindow` のプロパティ）。lock 更新時は `eww logs` を確認する
- `EWW_CPU` は 2 秒固定間隔（マジック変数は間隔変更不可）
- 既存の Waybar CSS は未インストールの `JetBrainsMono Nerd Font` と `Inter` を要求している
  （フォールバックで動いている）。ダッシュボード側は実在するファミリだけを指定してある

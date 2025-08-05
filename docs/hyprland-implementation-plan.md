# NixOS Hyprland導入計画書

## 📋 現状分析

### 既存の環境
- **OS**: NixOS 25.05
- **現在のデスクトップ環境**: GNOME
- **ディスプレイマネージャー**: GDM
- **ウィンドウシステム**: X11
- **入力メソッド**: fcitx5 (日本語入力対応)
- **オーディオ**: PipeWire
- **設定管理**: Nix Flakes + Home Manager

### 設定ファイル構造
```
nixos/
├── configuration.nix          # メイン設定
├── desktop/default.nix       # デスクトップ環境設定
├── system/default.nix        # システム設定
├── services/default.nix      # サービス設定
└── hardware-configuration.nix
```

## 🎯 導入目標

### 主要目標
1. **Hyprlandをウィンドウマネージャーとして導入**
2. **既存のGNOME環境との共存**
3. **日本語入力システムの継続動作**
4. **開発環境の維持**

### 期待される効果
- タイリングウィンドウマネージャーによる効率的な作業環境
- リソース使用量の最適化
- カスタマイズ性の向上
- キーボード中心の操作環境

## 🏗️ アーキテクチャ設計

### 設定ファイル構造の拡張
```
nixos/
├── desktop/
│   ├── default.nix           # 既存のGNOME設定
│   ├── hyprland/
│   │   ├── default.nix       # Hyprland基本設定
│   │   ├── config.nix        # Hyprland設定ファイル
│   │   ├── keybinds.nix      # キーバインド設定
│   │   ├── windowrules.nix   # ウィンドウルール
│   │   ├── monitors.nix      # モニター設定
│   │   └── startup.nix       # 自動起動設定
│   └── common.nix            # 共通設定（フォント等）
└── ...
```

### システム統合ポイント
1. **ディスプレイマネージャー**: GDMでHyprlandセッション選択可能
2. **入力メソッド**: fcitx5をWayland対応で継続使用
3. **オーディオ**: PipeWireをそのまま利用
4. **アプリケーション**: 既存のGNOMEアプリとの互換性維持

## 📦 導入コンポーネント

### 必須パッケージ
```nix
programs.hyprland = {
  enable = true;
  xwayland.enable = true;
};

environment.systemPackages = with pkgs; [
  # Core Hyprland
  hyprland
  hyprpaper        # 壁紙
  hyprlock         # スクリーンロック
  hypridle         # アイドル管理
  
  # Wayland utilities
  waybar           # ステータスバー
  wofi            # アプリケーションランチャー
  wlogout         # ログアウトメニュー
  wl-clipboard    # クリップボード
  grim            # スクリーンショット
  slurp           # 範囲選択
  
  # Notification
  dunst           # 通知デーモン
  libnotify       # 通知ライブラリ
  
  # File manager
  thunar          # ファイルマネージャー
  
  # Terminal
  alacritty       # 既存設定を流用
];
```

### オプションパッケージ
```nix
# 追加のユーティリティ
environment.systemPackages = with pkgs; [
  swww            # 動的壁紙（hyprpaperの代替）
  rofi-wayland    # wofiの代替ランチャー
  gammastep       # ブルーライトフィルター
  playerctl       # メディアコントロール
  brightnessctl   # 明度調整
  pamixer         # 音量調整
];
```

## 🔧 実装フェーズ

### Phase 1: 基盤構築
1. **Hyprlandパッケージの導入**
   - `programs.hyprland.enable = true`
   - Waylandサポートの有効化
   - XWaylandの設定

2. **基本設定ファイルの作成**
   - `nixos/desktop/hyprland/default.nix`
   - 最小限の動作設定

3. **セッション管理の設定**
   - GDMでのHyprlandセッション選択
   - 環境変数の設定

### Phase 2: 日本語環境の継続
1. **fcitx5のWayland対応**
   ```nix
   environment.sessionVariables = {
     GTK_IM_MODULE = "fcitx";
     QT_IM_MODULE = "fcitx";
     XMODIFIERS = "@im=fcitx";
     INPUT_METHOD = "fcitx";
     WAYLAND_IM_MODULE = "fcitx";
   };
   ```

2. **フォント設定の移行**
   - 既存のNotoフォント設定を維持
   - Waylandでの日本語フォント表示確認

### Phase 3: UI/UXの構築
1. **ステータスバー（Waybar）の設定**
   - システム情報表示
   - 時計、バッテリー、ネットワーク
   - ワークスペース表示

2. **アプリケーションランチャー（wofi）**
   - アプリケーション検索・起動
   - カスタムスタイリング

3. **通知システム（dunst）**
   - デスクトップ通知の表示
   - 通知のスタイリング

### Phase 4: 高度な設定とカスタマイズ
1. **キーバインドの設定**
   - ウィンドウ操作
   - ワークスペース切り替え
   - アプリケーション起動

2. **ウィンドウルールの設定**
   - アプリケーション固有の動作
   - フローティングウィンドウの管理

3. **自動起動設定**
   - 必要なデーモンの起動
   - 壁紙の設定

## 🧪 テスト戦略

### 段階的テスト
1. **Phase 1後**: Hyprlandセッションでの基本動作確認
2. **Phase 2後**: 日本語入力の動作確認
3. **Phase 3後**: 基本的なデスクトップ操作の確認
4. **Phase 4後**: 全機能の統合テスト

### 確認項目
- [ ] Hyprlandセッションの起動
- [ ] 日本語入力（fcitx5）の動作
- [ ] アプリケーションの起動と表示
- [ ] ウィンドウの基本操作
- [ ] マルチモニター対応
- [ ] スクリーンショット機能
- [ ] 音量・明度調整
- [ ] 通知システム

## 🔄 既存環境との共存

### GNOMEとの共存戦略
- GDMのセッション選択でGNOMEとHyprlandを切り替え可能
- 既存のGNOME設定は保持
- アプリケーションはどちらの環境でも使用可能

### 設定の分離
```nix
# nixos/desktop/default.nix
{ config, pkgs, ... }:
{
  imports = [
    ./gnome.nix      # 既存のGNOME設定
    ./hyprland       # 新しいHyprland設定
    ./common.nix     # 共通設定
  ];
}
```

## 📈 段階的移行計画

### Week 1: 基盤構築
- Hyprlandパッケージの導入
- 基本設定の作成
- セッション起動の確認

### Week 2: 日本語環境と基本UI
- fcitx5のWayland対応
- Waybar、wofi、dunstの設定
- 基本的なデスクトップ環境の構築

### Week 3: カスタマイズと最適化
- キーバインドの詳細設定
- ウィンドウルールの調整
- 自動起動設定の最適化

### Week 4: テストと調整
- 全機能の統合テスト
- パフォーマンスの最適化
- ドキュメント更新

## 🚨 リスク管理

### 主要リスク
1. **セッション起動の問題**: GDMでのHyprlandセッション認識失敗
2. **日本語入力の問題**: Waylandでのfcitx5動作不良
3. **アプリケーション互換性**: XWaylandでのアプリ表示問題

### 対策
- 各フェーズでの段階的テスト実施
- 既存のGNOME環境を保持（フォールバック）
- 設定のバックアップとロールバック計画

## 📚 参考資料

### 公式ドキュメント
- [Hyprland Wiki](https://wiki.hyprland.org/)
- [NixOS Manual - Hyprland](https://nixos.wiki/wiki/Hyprland)
- [Nix Community Hyprland](https://github.com/hyprwm/hyprland)

### 設定例
- [hyprland-nix-config examples](https://github.com/search?q=hyprland+nix)
- [NixOS Hyprland configurations](https://github.com/topics/hyprland-nix)

## 🎉 期待される成果

### 短期的成果
- モダンで効率的なウィンドウマネージャー環境
- キーボード中心の操作による生産性向上
- リソース使用量の最適化

### 長期的成果
- 高度にカスタマイズされた作業環境
- Waylandエコシステムの完全活用
- 将来的なデスクトップ環境の基盤構築

---

この計画書は、NixOSでのHyprland導入を段階的かつ安全に実施するためのロードマップです。既存のGNOME環境との共存を保ちながら、モダンなWaylandベースのデスクトップ環境を構築することを目指します。
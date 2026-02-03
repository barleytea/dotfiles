# Yazi Plugin Management

Yaziプラグイン管理の完全ガイド - flake inputs管理、プラグインの追加・削除、トラブルシューティング

---

## Architecture Overview

yaziプラグインはflake inputsとして管理され、Home Managerで設定されます。

### Configuration Structure

```
dotfiles/
├── flake.nix                    # yazi-plugins input定義
├── flake.lock                   # バージョン固定
└── home-manager/
    └── yazi/
        ├── default.nix          # プラグイン設定
        ├── yazi.toml            # 基本設定・fetcher登録
        └── keymap.toml          # キーバインド設定
```

### Flake Input Configuration

```nix
# flake.nix
inputs = {
  yazi-plugins = {
    url = "github:yazi-rs/plugins/230b9c6055a3144f6974fef297ad1a91b46a6aac";
    flake = false;
  };
};

outputs = {
  # ...
  yazi-plugins,
} @ inputs: {
  homeConfigurations = {
    home = selectedHomeManager.lib.homeManagerConfiguration {
      extraSpecialArgs = { inherit inputs; };  # inputsを渡す
      # ...
    };
  };
};
```

### Home Manager Configuration

```nix
# home-manager/yazi/default.nix
{
  pkgs,
  inputs,  # flakeからinputsを受け取る
  ...
}: {
  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
    shellWrapperName = "y";

    plugins = {
      # inputs.yazi-pluginsを使用
      jump-to-char = "${inputs.yazi-plugins}/jump-to-char.yazi";
      smart-enter = "${inputs.yazi-plugins}/smart-enter.yazi";
      smart-filter = "${inputs.yazi-plugins}/smart-filter.yazi";
      git = "${inputs.yazi-plugins}/git.yazi";
    };

    initLua = ''
      -- gitプラグインの初期化
      local status, result = pcall(function()
        return require("git")
      end)
      if status then
        pcall(function() result:setup() end)
      end
    '';
  };
}
```

---

## Installed Plugins

### Builtin Plugins

| Plugin | Key | Description |
|--------|-----|-------------|
| **fzf** | `s` | ファジーファイル検索（yaziビルトイン） |

### Official Plugins (yazi-rs/plugins)

| Plugin | Key | Type | Description |
|--------|-----|------|-------------|
| **jump-to-char** | `f` + 文字 | Keybind | Vimスタイルの文字ジャンプ |
| **smart-enter** | `l` | Keybind | ファイルを開く/ディレクトリに入る（1キーで両方） |
| **smart-filter** | `F` (Shift+f) | Keybind | スマートフィルタリング（継続フィルター） |
| **git** | Auto | Fetcher + Linemode | Gitステータス表示（M, ?, A, D等） |

### Plugin Types

1. **Keybind型**: キーバインドから呼び出すプラグイン（初期化不要）
2. **Fetcher型**: バックグラウンドで情報取得（yazi.tomlで登録必要）
3. **Linemode型**: ファイル一覧の表示形式を拡張（initLuaで初期化必要）

---

## Plugin Management

### Adding a New Plugin

#### 1. キーバインド型プラグイン（簡単）

```nix
# home-manager/yazi/default.nix
plugins = {
  # 既存のプラグイン...

  # 新しいプラグインを追加
  chmod = "${inputs.yazi-plugins}/chmod.yazi";
};
```

```toml
# home-manager/yazi/keymap.toml
[[manager.prepend_keymap]]
on = [ "c", "m" ]
run = "plugin chmod"
desc = "Chmod on selected files"
```

```bash
# 適用
make home-manager-apply
```

#### 2. Fetcher/Linemode型プラグイン（複雑）

gitプラグインのような複雑なプラグインの場合：

**Step 1: プラグインを追加**
```nix
# home-manager/yazi/default.nix
plugins = {
  git = "${inputs.yazi-plugins}/git.yazi";
};
```

**Step 2: Fetcherを登録（必要な場合）**
```toml
# home-manager/yazi/yazi.toml
[[plugin.prepend_fetchers]]
id = "git"
url = "*"
run = "git"

[[plugin.prepend_fetchers]]
id = "git"
url = "*/"
run = "git"
```

**Step 3: 初期化コードを追加（必要な場合）**
```nix
# home-manager/yazi/default.nix
initLua = ''
  require("git"):setup()
'';
```

**Step 4: エラーハンドリング（推奨）**
```nix
initLua = ''
  local status, result = pcall(function()
    return require("git")
  end)
  if status then
    pcall(function() result:setup() end)
  end
'';
```

### Removing a Plugin

```nix
# home-manager/yazi/default.nix
plugins = {
  # jump-to-char = "${inputs.yazi-plugins}/jump-to-char.yazi";  # コメントアウト
};
```

対応するキーバインド設定も削除：
```toml
# home-manager/yazi/keymap.toml
# [[manager.prepend_keymap]]
# on = "f"
# run = "plugin jump-to-char"
# desc = "Jump to char"
```

### Updating Plugins

```bash
# yazi-pluginsのみ更新
nix flake lock --update-input yazi-plugins

# 全inputsを更新
make flake-update

# 変更を適用
make home-manager-apply
```

### Pinning to Specific Version

```nix
# flake.nix
yazi-plugins = {
  # 特定のコミットにピン留め
  url = "github:yazi-rs/plugins/230b9c6055a3144f6974fef297ad1a91b46a6aac";
  flake = false;
};
```

最新のコミットハッシュを取得：
```bash
# GitHubで確認
# https://github.com/yazi-rs/plugins

# または git ls-remote
git ls-remote https://github.com/yazi-rs/plugins HEAD
```

---

## Available Plugins

### UI Enhancement

- **full-border**: フルボーダー表示（要初期化、互換性問題あり）
- **starship**: Starshipプロンプト統合（要初期化）
- **no-status**: ステータスバーを削除

### Navigation & Search

- **jump-to-char**: Vimスタイル文字ジャンプ ⭐ 現在使用中
- **relative-motions**: Vimモーション風ナビゲーション
- **bunny**: ファジー検索可能なブックマーク
- **cd-git-root**: Gitリポジトリルートへ移動

### Git Integration

- **git**: Gitステータス表示 ⭐ 現在使用中
- **vcs-files**: Git変更ファイル一覧
- **lazygit**: lazygit統合

### Smart Features

- **smart-enter**: ファイル開く/ディレクトリ入る統一 ⭐ 現在使用中
- **smart-filter**: 継続フィルタリング ⭐ 現在使用中
- **smart-paste**: コンテキスト認識ペースト
- **bypass**: 単一サブディレクトリスキップ

### File Operations

- **chmod**: パーミッション変更UI
- **diff**: ファイル比較・パッチ生成
- **compress**: アーカイブ作成

### Preview Enhancement

- **glow**: Markdownプレビュー（glowコマンド必要）
- **hexyl**: バイナリHexビューア
- **mediainfo**: 動画・音声メタデータ表示

公式プラグイン一覧: https://github.com/yazi-rs/plugins

---

## Troubleshooting

### プラグインが動作しない

**症状**: yaziが起動しない、プラグインが読み込まれない

**原因と対処法**:

1. **初期化コードのエラー**
   ```nix
   # エラーハンドリングを追加
   initLua = ''
     local status, err = pcall(function()
       require("plugin-name"):setup()
     end)
     if not status then
       ya.notify({
         title = "Plugin error",
         content = tostring(err),
         timeout = 5,
         level = "error",
       })
     end
   '';
   ```

2. **プラグインバージョンとyaziの互換性**
   - yaziのバージョン確認: `yazi --version`
   - プラグインのREADMEで必要バージョンを確認
   - プラグインのコメント `@since` でバージョン確認

3. **プラグインが配置されていない**
   ```bash
   # プラグインの配置確認
   ls -la ~/.config/yazi/plugins/

   # 設定適用
   make home-manager-apply
   ```

### Gitステータスが表示されない

**症状**: "git"という文字列が表示される、またはGitステータス記号が表示されない

**対処法**:

1. **linemodeをsizeに設定**
   ```toml
   # yazi.toml
   linemode = "size"  # "git"ではない
   ```
   gitプラグインは既存のlinemodeに追加される形式

2. **fetcherが正しく登録されているか確認**
   ```toml
   [[plugin.prepend_fetchers]]
   id = "git"
   url = "*"      # "name"ではなく"url"
   run = "git"
   ```

3. **gitコマンドが利用可能か確認**
   ```bash
   which git
   ```

4. **Gitリポジトリ内でyaziを実行**
   ```bash
   cd ~/git_repos/github.com/barleytea/dotfiles
   yazi
   ```

### キーバインドが動作しない

**症状**: キーを押しても何も起こらない

**対処法**:

1. **キーバインド形式を確認**
   ```toml
   # ❌ 間違い
   on = "c m"

   # ✅ 正しい（2キーシーケンス）
   on = [ "c", "m" ]

   # ✅ 正しい（単一キー）
   on = "s"
   ```

2. **プラグインがインストールされているか確認**
   ```bash
   ls ~/.config/yazi/plugins/plugin-name.yazi/
   ```

3. **キーが他のバインドと競合していないか確認**
   - yaziのデフォルトキーバインドを確認
   - 同じキーが複数のプラグインにバインドされていないか確認

### flake.lockの問題

**症状**: `nix flake lock`でエラーが出る

**対処法**:

1. **ハッシュミスマッチ**
   ```nix
   # 仮のハッシュで試してエラーから正しいハッシュを取得
   hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
   ```

   ```bash
   nix flake lock 2>&1 | grep "got:"
   # 出力されたハッシュを使用
   ```

2. **inputsが渡されていない**
   ```nix
   # flake.nix - outputsにyazi-pluginsを追加
   outputs = {
     # ...
     yazi-plugins,
   } @ inputs: {
     homeConfigurations = {
       home = selectedHomeManager.lib.homeManagerConfiguration {
         extraSpecialArgs = { inherit inputs; };
       };
     };
   };
   ```

---

## Configuration Examples

### Minimal Setup (fzf only)

```nix
{pkgs, ...}: {
  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
    shellWrapperName = "y";
  };
}
```

```toml
# keymap.toml
[[manager.prepend_keymap]]
on = "s"
run = "plugin fzf"
desc = "Search files with fzf"
```

### Recommended Setup (Current)

```nix
{
  pkgs,
  inputs,
  ...
}: {
  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
    shellWrapperName = "y";

    plugins = {
      jump-to-char = "${inputs.yazi-plugins}/jump-to-char.yazi";
      smart-enter = "${inputs.yazi-plugins}/smart-enter.yazi";
      smart-filter = "${inputs.yazi-plugins}/smart-filter.yazi";
      git = "${inputs.yazi-plugins}/git.yazi";
    };

    initLua = ''
      local status, result = pcall(function()
        return require("git")
      end)
      if status then
        pcall(function() result:setup() end)
      end
    '';
  };

  xdg.configFile."yazi/yazi.toml".source = ./yazi.toml;
  xdg.configFile."yazi/keymap.toml".source = ./keymap.toml;

  home.packages = with pkgs; [
    fzf
    fd
    ripgrep
    bat
  ];
}
```

### Full-Featured Setup

全プラグインを有効化（動作確認必要）:

```nix
plugins = {
  # Navigation
  jump-to-char = "${inputs.yazi-plugins}/jump-to-char.yazi";

  # Smart features
  smart-enter = "${inputs.yazi-plugins}/smart-enter.yazi";
  smart-filter = "${inputs.yazi-plugins}/smart-filter.yazi";
  smart-paste = "${inputs.yazi-plugins}/smart-paste.yazi";

  # Git
  git = "${inputs.yazi-plugins}/git.yazi";

  # File operations
  chmod = "${inputs.yazi-plugins}/chmod.yazi";
  diff = "${inputs.yazi-plugins}/diff.yazi";

  # Preview
  glow = "${inputs.yazi-plugins}/glow.yazi";
};
```

---

## References

### Official Documentation

- [Yazi Documentation](https://yazi-rs.github.io/)
- [Yazi Plugins Overview](https://yazi-rs.github.io/docs/plugins/overview/)
- [Yazi Resources - Plugins](https://yazi-rs.github.io/docs/resources/)
- [Home Manager yazi.nix](https://github.com/nix-community/home-manager/blob/master/modules/programs/yazi.nix)

### Repositories

- [yazi-rs/yazi](https://github.com/sxyazi/yazi) - メインリポジトリ
- [yazi-rs/plugins](https://github.com/yazi-rs/plugins) - 公式プラグイン集
- [awesome-yazi](https://github.com/AnirudhG07/awesome-yazi) - コミュニティキュレーション

### Related Files

```
home-manager/yazi/
├── default.nix      # プラグイン設定、initLua
├── yazi.toml        # 基本設定、fetcher登録、linemode設定
└── keymap.toml      # キーバインド設定
```

---

## Common Commands

```bash
# 設定適用
make home-manager-apply

# プラグイン更新
nix flake lock --update-input yazi-plugins
make home-manager-apply

# yaziを起動
yazi
# または
y  # shellWrapperName設定時

# プラグイン確認
ls ~/.config/yazi/plugins/

# yaziバージョン確認
yazi --version

# flake inputs確認
nix flake metadata
```

---

**最終更新**: 2026-02-03
**Yazi Version**: 26.1.22
**Plugin Repository**: [230b9c6](https://github.com/yazi-rs/plugins/tree/230b9c6055a3144f6974fef297ad1a91b46a6aac)

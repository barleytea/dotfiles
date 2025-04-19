# VSCodeとNeovimの設定同期モジュール
{ config, lib, pkgs, ... }:

with lib;
let
  # ホームディレクトリのパスを取得
  home = config.home.homeDirectory;

  # 共通設定モジュールのインポート
  editorCore = import ../shared-config/editor-core.nix { inherit config lib pkgs; };

  # 共通設定を使用（オーバーライド可能）
  commonSettings = editorCore.commonSettings;

  # VSCode専用設定
  vscodeSpecificSettings = {
    # VSCode固有の設定をここに追加
    "editor.inlineSuggest.enabled" = true;
    "workbench.startupEditor" = "none";
    "editor.renderWhitespace" = "trailing";
    "editor.accessibilitySupport" = "off";
    "editor.suggestSelection" = "first";
    "vsintellicode.modify.editor.suggestSelection" = "automaticallyOverrodeDefaultValue";
    "vscode-neovim.neovimExecutablePaths.darwin" = "${home}/.local/state/nix/profiles/profile/bin/nvim";
    "vscode-neovim.neovimInitVimPaths.darwin" = "${home}/.config/nvim/init.lua";
    "vscode-neovim.neovimInitVimPaths.vscodeProfile" = "${home}/.config/nvim/vscode.lua";
    "vscode-neovim.neovimClean" = true;
    "vscode-neovim.optimizeForLightTheme" = false;
    "vscode-neovim.useCtrlKeysForNormalMode" = true;
    "vscode-neovim.useCtrlKeysForInsertMode" = true;
    "vscode-neovim.logLevel" = "error";
    "vscode-neovim.textDecorationsAtTop" = true;
    "vscode-neovim.revealCursorScrollLine" = true;
  };

  # Neovim専用設定
  neovimSpecificSettings = ''
    -- Neovim固有の設定
    vim.opt.number = true
    vim.opt.relativenumber = true
    vim.opt.cursorline = true
    vim.opt.cursorcolumn = true
    vim.opt.termguicolors = true
    vim.opt.signcolumn = "yes"
    vim.opt.scrolloff = 8
    vim.opt.sidescrolloff = 8
    vim.opt.undofile = true

    -- statusline
    vim.opt.laststatus = 3
  '';

  # VSCode設定ファイルパス
  vscodeSettingsPath = "${home}/git_repos/github.com/barleytea/dotfiles/vscode/settings";

  # Neovim設定ファイルパス
  neovimConfigPath = "${home}/.config/nvim";
  neovimLuaPath = "${neovimConfigPath}/lua";

  # VSCode設定生成スクリプト
  generateVSCodeSettingsScript = pkgs.writeShellScript "generate-vscode-settings" ''
    #!/usr/bin/env bash
    set -euo pipefail

    # 設定ファイルパス
    SETTINGS_FILE="${vscodeSettingsPath}/settings.json"
    KEYBINDINGS_FILE="${vscodeSettingsPath}/keybindings.json"
    NEOVIM_KEYMAPS_FILE="${vscodeSettingsPath}/neovim-keymaps.json"

    # VSCode設定ファイルの更新
    if [ -f "$SETTINGS_FILE" ]; then
      # settings.jsonが存在する場合はバックアップを作成
      cp "$SETTINGS_FILE" "${vscodeSettingsPath}/backup_settings.json"
    fi

    # ベース設定生成
    echo "Generating VSCode settings..."
    ${pkgs.jq}/bin/jq -n \
      --argjson common '${builtins.toJSON (editorCore.toVSCodeSettings commonSettings)}' \
      --argjson specific '${builtins.toJSON vscodeSpecificSettings}' \
      '$common * $specific' > "$SETTINGS_FILE"

    echo "VSCode設定ファイルを更新しました: $SETTINGS_FILE"
  '';

  # Neovim設定生成スクリプト
  generateNeovimSettingsScript = pkgs.writeShellScript "generate-neovim-settings" ''
    #!/usr/bin/env bash
    set -euo pipefail

    # Neovim設定ディレクトリがない場合は作成
    mkdir -p "${neovimLuaPath}/shared"

    # 共通設定ファイル
    SHARED_SETTINGS="${neovimLuaPath}/shared/common.lua"

    # VSCodeモード用設定
    VSCODE_MODE="${neovimConfigPath}/vscode.lua"

    # 共通設定を生成
    echo "Generating Neovim common settings..."
    cat > "$SHARED_SETTINGS" << 'EOF'
    -- このファイルは自動生成されています - 手動で編集しないでください
    -- 元ソース: home-manager/shared-config/editor-core.nix

    ${editorCore.toNeovimSettings commonSettings}

    -- Neovim固有の設定
    ${neovimSpecificSettings}

    return {
      isGenerated = true,
      generatedAt = "${toString builtins.currentTime}"
    }
    EOF

    # VSCodeモード用ファイルを生成（存在しない場合のみ）
    if [ ! -f "$VSCODE_MODE" ]; then
      echo "Creating VSCode mode initialization file..."
      cat > "$VSCODE_MODE" << 'EOF'
    -- VSCode-Neovim連携モード - このファイルが読み込まれると、VSCodeモードとして動作します

    -- VSCodeモードフラグを設定
    vim.g.vscode = 1

    -- 共有設定を読み込み
    local ok, shared = pcall(require, 'shared.common')
    if not ok then
      print("Warning: 共有設定ファイルが読み込めませんでした")
    end

    -- utils/keymapsモジュールを読み込み
    local ok, keymap_utils = pcall(require, 'utils.keymaps')
    if ok then
      -- キーマップユーティリティが利用可能
      print("Keymap utilities loaded")
    end

    -- config/vscodeモジュールを読み込み
    local ok, vscode_config = pcall(require, 'config.vscode')
    if ok then
      -- VSCode専用設定
      print("VSCode configuration loaded")
    end

    print("VSCode-Neovim mode initialized")
    EOF
    fi

    echo "Neovim設定ファイルを更新しました:"
    echo "- $SHARED_SETTINGS"
    if [ ! -f "$VSCODE_MODE" ]; then
      echo "- $VSCODE_MODE (新規作成)"
    fi
  '';

  # 両方の設定を生成するスクリプト
  syncSettingsScript = pkgs.writeShellScript "sync-editor-settings" ''
    #!/usr/bin/env bash
    set -euo pipefail

    echo "===== VSCodeとNeovimの設定を同期します ====="

    # VSCode設定の生成
    ${generateVSCodeSettingsScript}

    # Neovim設定の生成
    ${generateNeovimSettingsScript}

    echo "===== 設定同期が完了しました ====="
    echo "VSCode設定: ${vscodeSettingsPath}/settings.json"
    echo "Neovim共通設定: ${neovimLuaPath}/shared/common.lua"
    echo "NeovimのVSCodeモード: ${neovimConfigPath}/vscode.lua"
  '';

in {
  # このモジュールは直接使用せず、他のモジュールから使用する

  # エクスポートする値
  syncSettings = {
    # スクリプト
    script = syncSettingsScript;

    # 設定パス
    paths = {
      vscode = {
        settings = "${vscodeSettingsPath}/settings.json";
        keybindings = "${vscodeSettingsPath}/keybindings.json";
        neovimKeymaps = "${vscodeSettingsPath}/neovim-keymaps.json";
      };
      neovim = {
        shared = "${neovimLuaPath}/shared/common.lua";
        vscodeMode = "${neovimConfigPath}/vscode.lua";
      };
    };

    # 設定値
    values = {
      common = commonSettings;
      vscodeSpecific = vscodeSpecificSettings;
      neovimSpecific = neovimSpecificSettings;
    };
  };

  # 設定ファイル同期を実行するためのコマンド
  home.packages = [
    (pkgs.writeShellScriptBin "sync-editor-settings" ''
      exec ${syncSettingsScript} "$@"
    '')
  ];
}

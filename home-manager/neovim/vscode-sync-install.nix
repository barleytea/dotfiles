# Neovim-VSCode同期システムのインストール設定
{ config, lib, pkgs, ... }:

let
  cfg = config.modules.neovim-vscode-sync;
  homeDir = config.home.homeDirectory;
  dotfilesDir = "${homeDir}/git_repos/github.com/barleytea/dotfiles";
  syncModule = import ./vscode-sync.nix { inherit lib pkgs homeDir; };

  # スクリプトのインストール先
  binDir = "${homeDir}/.local/bin";

  # VSCode初期化スクリプト
  neovimInitScript = pkgs.writeScriptBin "neovim-vscode-init" ''
    #!/usr/bin/env bash
    ${builtins.readFile "${dotfilesDir}/vscode/settings/neovim-init.sh"}
  '';

  # 設定同期スクリプト
  syncSettingsScript = pkgs.writeScriptBin "sync-editor-settings" ''
    #!/usr/bin/env bash
    ${syncModule.syncSettingsScript}
  '';

in {
  options.modules.neovim-vscode-sync = {
    enable = lib.mkEnableOption "VSCode-Neovim synchronization tools";

    autoInstall = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Automatically install the synchronization scripts on activation";
    };

    installPath = lib.mkOption {
      type = lib.types.str;
      default = binDir;
      description = "Path to install the synchronization scripts";
    };

    autoSync = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Automatically synchronize settings on system activation";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      jq      # JSON処理に必要
      neovimInitScript
      syncSettingsScript
    ];

    # インストール後の初期設定
    home.activation = {
      installNeovimVscodeSync = lib.hm.dag.entryAfter ["writeBoundary"] ''
        # 同期スクリプトのシンボリックリンクを作成
        $DRY_RUN_CMD mkdir -p ${cfg.installPath}
        $DRY_RUN_CMD ln -sf ${neovimInitScript}/bin/neovim-vscode-init ${cfg.installPath}/neovim-vscode-init
        $DRY_RUN_CMD ln -sf ${syncSettingsScript}/bin/sync-editor-settings ${cfg.installPath}/sync-editor-settings

        # 実行権限を付与
        $DRY_RUN_CMD chmod +x ${cfg.installPath}/neovim-vscode-init
        $DRY_RUN_CMD chmod +x ${cfg.installPath}/sync-editor-settings

        # 自動同期が有効な場合は実行
        ${if cfg.autoSync then ''
          $DRY_RUN_CMD ${cfg.installPath}/sync-editor-settings
        '' else ""}

        $VERBOSE_ECHO "VSCode-Neovim synchronization tools installed to ${cfg.installPath}"
      '';
    };

    # ドキュメント
    home.file.".local/share/neovim-vscode-sync/README.md".text = ''
      # VSCode-Neovim同期システム

      このツールはVSCodeとNeovimの設定を同期するためのものです。

      ## 利用可能なコマンド

      - `neovim-vscode-init`: VSCode用のNeovim初期化ファイルを設定
      - `sync-editor-settings`: VSCodeとNeovimの共通設定を同期

      ## 使い方

      1. VSCodeを起動するときに `neovim-vscode-init` を実行して初期化
      2. 設定を変更したら `sync-editor-settings` を実行して同期

      ## 設定ファイルの場所

      - VSCode設定: ${dotfilesDir}/vscode/settings/
      - Neovim設定: ${homeDir}/.config/nvim/

      ## トラブルシューティング

      問題が発生した場合は、各設定ファイルのバックアップから復元してください。
      バックアップは `.bak` 拡張子で保存されています。
    '';
  };
}

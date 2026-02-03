{
  pkgs,
  inputs,
  ...
}: {
  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
    shellWrapperName = "y"; # `y` コマンドでyaziを起動＋終了時にディレクトリ移動

    plugins = {
      # キーバインドから呼び出すプラグイン（初期化不要）
      jump-to-char = "${inputs.yazi-plugins}/jump-to-char.yazi";
      smart-enter = "${inputs.yazi-plugins}/smart-enter.yazi";
      smart-filter = "${inputs.yazi-plugins}/smart-filter.yazi";

      # Git統合（初期化が必要）
      git = "${inputs.yazi-plugins}/git.yazi";
    };

    # プラグインの初期化
    initLua = ''
      -- gitプラグインの初期化
      local status, result = pcall(function()
        return require("git")
      end)

      if status then
        local setup_status, setup_err = pcall(function()
          result:setup()
        end)
        if not setup_status then
          ya.notify({
            title = "Git plugin setup error",
            content = "Failed to setup git plugin: " .. tostring(setup_err),
            timeout = 5,
            level = "error",
          })
        end
      end
    '';
  };

  xdg.configFile."yazi/yazi.toml".source = ./yazi.toml;
  xdg.configFile."yazi/keymap.toml".source = ./keymap.toml;
  # xdg.configFile."yazi/theme.toml".source = ./theme.toml;

  # プラグインに必要な依存パッケージ
  home.packages = with pkgs; [
    fzf # ファジーファインダー（ビルトインfzfプラグインで使用）
    fd # 高速なfindの代替（fzfで使用）
    ripgrep # 高速なgrep
    bat # 構文ハイライト付きcat
  ];
}

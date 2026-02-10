{...}: {
  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
    shellWrapperName = "y"; # `y` コマンドでyaziを起動＋終了時にディレクトリ移動
  };

  xdg.configFile."yazi/yazi.toml".source = ./yazi.toml;
  xdg.configFile."yazi/keymap.toml".source = ./keymap.toml;
  # xdg.configFile."yazi/theme.toml".source = ./theme.toml;
}

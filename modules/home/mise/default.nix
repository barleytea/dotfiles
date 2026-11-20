{
  config,
  pkgs,
  ...
}: let
  # python は OS により分岐:
  #   - Darwin: nixpkgs の python が無い/不安定なため mise で 3.15.1 を install_only で導入
  #   - Linux : NixOS の system python を利用し、mise には登録しない
  darwinConfig =
    (builtins.replaceStrings
      ["[tools]\n"]
      ["[tools]\npython = \"3.15.1\"\n"]
      (builtins.readFile ./config.toml))
    + ''

      [settings.python]
      precompiled_flavor = "install_only"
    '';
in {
  programs.mise = {
    enable = true;
    enableZshIntegration = false; # カスタム mise.zsh（modules/home/mise/mise.zsh）で管理
  };

  xdg.configFile = {
    "mise/config.toml".text =
      if pkgs.stdenv.isDarwin then darwinConfig else builtins.readFile ./config.toml;

    # zsh 初期化スクリプト（activate + safe-chain）
    "zsh/config/tools/202-mise.zsh".source = ./mise.zsh;
  };

  home.sessionVariables = {
    MISE_DATA_DIR = "${config.xdg.dataHome}/mise";
    MISE_CONFIG_DIR = "${config.xdg.configHome}/mise";
    MISE_CACHE_DIR = "${config.xdg.cacheHome}/mise";
  };
}

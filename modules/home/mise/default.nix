{
  config,
  lib,
  pkgs,
  ...
}: let
  # python は OS により分岐:
  #   - Darwin: nixpkgs の python が無い/不安定なため mise で 3.13 を install_only で導入
  #   - Linux : nixpkgs 経由で system python を利用
  baseText = builtins.readFile ./config.toml;
  linuxText = builtins.replaceStrings
    [ "python = \"3.13\"\n"
      "\n[settings.python]\nprecompiled_flavor = \"install_only\"\n"
    ]
    [ "python = \"system\"\n"
      ""
    ]
    baseText;
in {
  programs.mise = {
    enable = true;
    enableZshIntegration = true;
  };

  xdg.configFile."mise/config.toml".text =
    if pkgs.stdenv.isDarwin then baseText else linuxText;

  home.sessionVariables = {
    MISE_USE_TOML = "1";
    MISE_EXPERIMENTAL = "1";
  };
}

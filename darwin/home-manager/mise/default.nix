{
  config,
  lib,
  pkgs,
  ...
}: {
  programs.mise = {
    enable = true;
    enableZshIntegration = true;
  };

  xdg.configFile."mise/config.toml" = {
    source = ./config.toml;
  };

  home.sessionVariables = {
    MISE_USE_TOML = "1";
    MISE_EXPERIMENTAL = "1";
  };
}

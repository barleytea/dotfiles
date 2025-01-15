{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (builtins) readFile;
in {
  programs.zsh.enable = true;

  home.sessionVariables = lib.mkForce {};

  xdg = {
    enable = true;
    configFile = {
      "zsh/.zshrc".source = ./.zshrc;
      "zsh/.zshenv".text = ''
        export ZDOTDIR="$HOME/.config/zsh"
      '';
    };
  };
}

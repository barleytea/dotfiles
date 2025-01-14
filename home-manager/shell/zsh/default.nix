{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (builtins) readFile;
in {
  programs.zsh = {
    enable = true;
    dotDir = ".config/zsh";
    initExtra = readFile ./.zshrc;
    history = {
      path = "${config.xdg.stateHome}/zsh/zsh-history";
    };
  };
}

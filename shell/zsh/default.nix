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
    initExtra = readFile ./.zshrc;
  };
}
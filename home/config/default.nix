{
  config,
  lib,
  pkgs,
  ...
}: let
  
in {
  xdg.configFile = {
    ".config".source = "./.config";
  };
}

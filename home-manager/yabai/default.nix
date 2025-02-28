{ config, lib, pkgs, ... }:

{
  home.file = {
    ".config/yabai/yabairc" = {
      source = ./yabairc;
      executable = true;
    };
  };
}

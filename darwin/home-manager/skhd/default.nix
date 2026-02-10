{ config, lib, pkgs, ... }:

{
  home.file = {
    ".config/skhd/skhdrc" = {
      source = ./skhdrc;
      executable = true;
    };
  };
}

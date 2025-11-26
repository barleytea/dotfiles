# Arion pkgs - provides nixpkgs to arion compose files
{ system ? builtins.currentSystem }:

import <nixpkgs> {
  inherit system;
  config = {
    allowUnfree = true;
  };
}

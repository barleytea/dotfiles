{ pkgs, ... }:

let
  username = "miyoshi_s";
  # NixOS only
  home = "/home/${username}";
in {
  inherit username home;
}

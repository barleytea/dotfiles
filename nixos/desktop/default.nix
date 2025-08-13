# Desktop environment configuration
{ config, pkgs, ... }:

{
  imports = [
    ./common.nix      # Shared desktop settings
    ./gnome.nix       # GNOME specific settings
    ./hyprland        # Hyprland configuration
  ];
}

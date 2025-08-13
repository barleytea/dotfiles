# Hyprpaper wallpaper configuration
{ config, pkgs, ... }:

{
  # Create hyprpaper configuration
  environment.etc."xdg/hypr/hyprpaper.conf".text = ''
    preload = /usr/share/backgrounds/nixos/nix-wallpaper-simple-dark-gray.png
    wallpaper = ,/usr/share/backgrounds/nixos/nix-wallpaper-simple-dark-gray.png
    splash = false
  '';

  # Ensure NixOS wallpapers are available
  environment.systemPackages = with pkgs; [
    nixos-artwork.wallpapers.simple-dark-gray
  ];
}
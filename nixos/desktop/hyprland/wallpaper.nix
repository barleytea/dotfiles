# Hyprpaper wallpaper configuration
{ config, pkgs, ... }:

{
  # Restore original NixOS wallpaper
  environment.etc."xdg/hypr/hyprpaper.conf".text = ''
    preload = /usr/share/backgrounds/nixos/nix-wallpaper-simple-dark-gray.png
    wallpaper = ,/usr/share/backgrounds/nixos/nix-wallpaper-simple-dark-gray.png
    splash = false
  '';

  environment.systemPackages = with pkgs; [
    nixos-artwork.wallpapers.simple-dark-gray
  ];
}

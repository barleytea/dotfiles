# Hyprpaper wallpaper configuration
{ config, pkgs, ... }:

let
  wallpaperFile = "${pkgs.nixos-artwork.wallpapers.simple-dark-gray}/share/backgrounds/nixos/nix-wallpaper-simple-dark-gray.png";
  hyprpaperConfig = ''
    preload = ${wallpaperFile}
    wallpaper = ,${wallpaperFile}
    splash = false
  '';
in {
  # Ship the config in both XDG and legacy locations so hyprpaper always finds it.
  environment.etc = {
    "xdg/hypr/hyprpaper.conf".text = hyprpaperConfig;
    "hypr/hyprpaper.conf".text = hyprpaperConfig;
  };

  environment.systemPackages = with pkgs; [
    nixos-artwork.wallpapers.simple-dark-gray
  ];
}

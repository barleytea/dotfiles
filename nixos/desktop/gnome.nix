# GNOME specific configuration
{ config, pkgs, ... }:

{
  imports = [
    ./gnome-albert.nix  # Albert configuration for GNOME
  ];

  # Enable GNOME Desktop Environment
  services.desktopManager.gnome.enable = true;

  # GNOME specific packages
  environment.systemPackages = with pkgs; [
    # GNOME extensions and tools
    gnome-extension-manager
    gnome-tweaks
  ];

  # GNOME specific settings
  services.gnome = {
    core-apps.enable = true;
    games.enable = false;
  };

  # Remove some default GNOME applications
  environment.gnome.excludePackages = (with pkgs; [
    gnome-tour
    epiphany
    geary
    totem
  ]);
}
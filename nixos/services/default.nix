# Services configuration
{ config, pkgs, ... }:

{
  imports = [
    ./tailscale
    ./fileserver
    ./gitserver
  ];

  # System services
  services = {
    # Automatic updates
    system76-scheduler.enable = true;

    # Bluetooth
    blueman.enable = true;

    # Network time synchronization
    chrony.enable = true;

    # Power management
    power-profiles-daemon.enable = true;

    # Flatpak support
    flatpak.enable = true;

    # Firmware updates
    fwupd.enable = true;
  };

  # Enable Bluetooth
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  # XDG portal for Flatpak
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
    ];
  };
}

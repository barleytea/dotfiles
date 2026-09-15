# Services configuration
{ config, pkgs, inputs, ... }:

{
  imports = [
    ./fileserver
    ./gitserver
    ./k3s
    ./ollama
    ./tailscale
    ./writing
    inputs.agent-dangomushi.nixosModules.default
  ];

  # System services
  services = {
    # NixOS 上で完結する AI 小説執筆環境
    writing.enable = true;

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

    # だんごむし Discord bot
    agent-dangomushi = {
      enable = true;
      environmentFile = "/var/lib/agent-dangomushi/env";
    };
  };

  # Enable Bluetooth
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Experimental = true;
        Enable = "Source,Sink,Media,Socket";
      };
    };
  };

  # XDG portal for Flatpak
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
    ];
  };
}

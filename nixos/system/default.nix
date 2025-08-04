# NixOS system-level configuration
{ config, pkgs, ... }:

{
  # Boot configuration
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    kernelPackages = pkgs.linuxPackages_latest;
  };

  # Hardware support
  hardware = {
    enableAllFirmware = true;
  };

  # Audio - disable PulseAudio in favor of PipeWire
  services.pulseaudio.enable = false;

  # Security
  security = {
    rtkit.enable = true;
    polkit.enable = true;
  };

  # Services
  services = {
    # Audio
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    # SSH
    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
      };
    };

    # Printing
    printing.enable = true;

    # Location services
    geoclue2.enable = true;
  };

  # Virtualization
  virtualisation = {
    docker.enable = true;
  };
}

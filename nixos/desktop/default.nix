# Desktop environment configuration
{ config, pkgs, ... }:

{
  # X11 and display manager
  services.xserver = {
    enable = true;

    # Keyboard layout
    xkb = {
      layout = "us";
      variant = "";
    };
  };

  # Display and desktop manager (updated options)
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # Fonts
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-emoji
    liberation_ttf
    fira-code
    fira-code-symbols
    nerd-fonts.hack
  ];

  # Desktop environment packages
  environment.systemPackages = with pkgs; [
    # GNOME extensions and tools
    gnome-extension-manager
    gnome-tweaks

    # Additional desktop apps
    firefox
    chromium
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

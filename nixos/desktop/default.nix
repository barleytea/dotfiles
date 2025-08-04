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

  # Japanese input method
  i18n.inputMethod = {
    enabled = "fcitx5";
    fcitx5.addons = with pkgs; [
      fcitx5-mozc
      fcitx5-gtk
      fcitx5-configtool
    ];
  };

  # Display and desktop manager (updated options)
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # Fonts
  fonts = {
    packages = with pkgs; [
      # Basic fonts
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-emoji
      liberation_ttf

      # Programming fonts
      fira-code
      fira-code-symbols
      nerd-fonts.hack

      # Japanese fonts
      ipafont
      ipaexfont
      kochi-substitute
      source-han-sans
      source-han-serif
    ];

    fontconfig = {
      defaultFonts = {
        serif = [ "Noto Serif CJK JP" "Noto Serif" ];
        sansSerif = [ "Noto Sans CJK JP" "Noto Sans" ];
        monospace = [ "Hack Nerd Font" "Fira Code" ];
      };
    };
  };

  # Desktop environment packages
  environment.systemPackages = with pkgs; [
    # GNOME extensions and tools
    gnome-extension-manager
    gnome-tweaks

    # Additional desktop apps
    firefox
    chromium
    code-cursor

    # Development tools  
    python3
    gnumake
    gcc
    cmake
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

# Common desktop configuration shared between GNOME and Hyprland
{ config, pkgs, ... }:

{
  # X11 and display manager (both GNOME and Hyprland need this)
  services.xserver = {
    enable = true;

    # Keyboard layout
    xkb = {
      layout = "us";
      variant = "";
    };
  };

  # Japanese input method (shared)
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.addons = with pkgs; [
      fcitx5-mozc
      fcitx5-gtk
      fcitx5-configtool
    ];
  };

  # Display manager
  services.displayManager.gdm.enable = true;

  # Fonts (shared)
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

  # Common desktop applications
  environment.systemPackages = with pkgs; [
    # Web browsers
    firefox
    chromium

    # Application launchers
    albert

    # Development tools
    code-cursor
    python3
    gnumake
    gcc
    cmake
  ];

  # Albert launcher configuration (shared between GNOME and Hyprland)
  environment.etc."xdg/albert/albert.conf".text = ''
    [General]
    hotkey=Meta+Space
    showTray=false
    telemetry=false
    
    [org.albert.extension.applications]
    enabled=true
    use_generic_name=false
    use_keywords=true
    use_non_localized_name=false
    fuzzy=true
    
    [org.albert.extension.calculator]
    enabled=true
    
    [org.albert.extension.files]
    enabled=true
    paths=/home
    fuzzy=true
    
    [org.albert.extension.system]
    enabled=true
    
    [org.albert.extension.websearch]
    enabled=true
    
    [org.albert.extension.terminal]
    enabled=true
    
    [org.albert.frontend.qmlboxmodel]
    alwaysOnTop=true
    clearOnHide=false
    hideOnFocusLoss=true
    showCentered=true
    styleSheet=
    windowPosition=@Point(640 360)
    
    [org.albert.frontend.widgetboxmodel]
    alwaysOnTop=true
    clearOnHide=false
    hideOnFocusLoss=true
    showCentered=true
    theme=Arc Dark
  '';
}
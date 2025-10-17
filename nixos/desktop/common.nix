# Common desktop configuration shared between GNOME and Hyprland
{ config, pkgs, ... }:

{
  # X11 and display manager (both GNOME and Hyprland need this)
  services.xserver = {
    enable = true;
    autoRepeatDelay = 200;
    autoRepeatInterval = 5;

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
    fcitx5.addons = [
      pkgs.fcitx5-mozc
      pkgs.fcitx5-gtk
      pkgs.libsForQt5.fcitx5-qt
      pkgs.fcitx5-configtool
    ];
  };

  # macOS-like Super (Command) shortcuts while keeping Control intact
  services.keyd = {
    enable = true;
    keyboards.default = {
      ids = [ "*" ];
      settings.main = {
        leftmeta = "layer(supercmd)";
        rightmeta = "layer(supercmd)";
      };
      settings.control = {
        a = "home";
        e = "end";
        "S-a" = "S-home";
        "S-e" = "S-end";
      };
      settings.supercmd = {
        c = "C-c";
        v = "C-v";
        x = "C-x";
        z = "C-z";
        "S-z" = "C-S-z";
        a = "C-a";
        s = "C-s";
        f = "C-f";
        p = "C-p";
        "S-p" = "M-S-p";
        n = "C-n";
        t = "C-t";
        w = "C-w";
        q = "C-q";
        "S-q" = "M-S-q";
        "S-l" = "M-S-l";
        h = "M-h";
        j = "M-j";
        k = "M-k";
        l = "M-l";
        "S-e" = "M-S-e";
        "S-m" = "M-S-m";
        o = "C-o";
        comma = "C-comma";
        tab = "A-tab";
        "S-tab" = "A-S-tab";
        space = "M-space";
        enter = "M-enter";
        left = "M-left";
        right = "M-right";
        up = "M-up";
        down = "M-down";
        "1" = "M-1";
        "S-1" = "M-S-1";
        "2" = "M-2";
        "S-2" = "M-S-2";
        "3" = "M-3";
        "S-3" = "M-S-3";
        "4" = "M-4";
        "S-4" = "M-S-4";
        "5" = "M-5";
        "S-5" = "M-S-5";
        "6" = "M-6";
        "S-6" = "M-S-6";
        "7" = "M-7";
        "S-7" = "M-S-7";
        "8" = "M-8";
        "S-8" = "M-S-8";
        "9" = "M-9";
        "S-9" = "M-S-9";
        "0" = "M-0";
        "S-0" = "M-S-0";
      };
      settings."supercmd+shift" = {
        v = "A-S-v";
      };
    };
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
    python3
    gnumake
    gcc
    cmake
  ];

  # Albert launcher configuration (shared between GNOME and Hyprland)
  environment.etc."xdg/albert/albert.conf".text = ''
    [General]
    hotkey=Alt+Space
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

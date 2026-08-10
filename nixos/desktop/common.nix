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
      pkgs.qt6Packages.fcitx5-configtool
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
      };
      # keyd に「レイヤー + Shift」を単一のキー名（"S-a" 等）で表現する構文は無い。
      # Shift 付きの組み合わせは必ず複合レイヤー（layer1+layer2）で定義する。
      # 誤って main レイヤー内に "S-x" と書いても静かに無視され、無印字版にフォールバックする
      # （例: Super+Shift+K が Shift 抜きの Super+K として送出される）ため注意
      settings."control+shift" = {
        a = "S-home";
        e = "S-end";
      };
      settings.supercmd = {
        c = "C-c";
        v = "C-v";
        x = "C-x";
        z = "C-z";
        a = "C-a";
        s = "C-s";
        f = "C-f";
        p = "C-p";
        n = "C-n";
        t = "C-t";
        w = "C-w";
        q = "C-q";
        h = "M-h";
        j = "M-j";
        k = "M-k";
        l = "M-l";
        o = "C-o";
        comma = "C-comma";
        tab = "A-tab";
        space = "M-space";
        enter = "M-enter";
        left = "M-left";
        right = "M-right";
        up = "M-up";
        down = "M-down";
        "1" = "M-1";
        "2" = "M-2";
        "3" = "M-3";
        "4" = "M-4";
        "5" = "M-5";
        "6" = "M-6";
        "7" = "M-7";
        "8" = "M-8";
        "9" = "M-9";
        "0" = "M-0";
      };
      settings."supercmd+shift" = {
        v = "A-S-v";
        z = "C-S-z";
        p = "M-S-p";
        q = "M-S-q";
        l = "M-S-l";
        k = "M-S-k";
        e = "M-S-e";
        m = "M-S-m";
        tab = "A-S-tab";
        "1" = "M-S-1";
        "2" = "M-S-2";
        "3" = "M-S-3";
        "4" = "M-S-4";
        "5" = "M-S-5";
        "6" = "M-S-6";
        "7" = "M-S-7";
        "8" = "M-S-8";
        "9" = "M-S-9";
        "0" = "M-S-0";
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
      noto-fonts-color-emoji
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

    # Development tools
    python3
    gnumake
    gcc
    cmake
  ];
}

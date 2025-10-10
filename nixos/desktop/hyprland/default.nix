# Hyprland configuration
{ config, pkgs, ... }:

{
  imports = [
    ./config.nix
    ./waybar.nix
    ./wofi.nix
    ./dunst.nix
    ./wallpaper.nix
    ./lock.nix
  ];

  # Enable Hyprland
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # Hyprland session for GDM
  services.displayManager.sessionPackages = [ pkgs.hyprland ];

  # Essential Wayland packages
  environment.systemPackages = with pkgs; [
    # Core Hyprland components
    hyprland
    hyprpaper        # Wallpaper
    hyprlock         # Screen lock
    hypridle         # Idle management
    
    # Wayland utilities
    waybar           # Status bar
    wofi             # Application launcher
    wlogout          # Logout menu
    wl-clipboard     # Clipboard manager
    wl-clipboard-x11 # X11 compatibility for clipboard
    cliphist         # Clipboard history manager
    xsel             # X11 clipboard utility (for Xwayland compatibility)
    xclip            # Additional X11 clipboard tool
    grim             # Screenshot tool
    slurp            # Region selection
    
    # Additional utilities for enhanced waybar
    blueman          # Bluetooth manager
    curl             # For weather module
    mpd              # Music Player Daemon (optional)
    
    # Notification system
    dunst            # Notification daemon
    libnotify        # Notification library
    
    # File manager
    xfce.thunar      # Lightweight file manager
    xfce.thunar-volman  # Volume management for Thunar
    gvfs             # Virtual file system
    
    # Terminal (use existing alacritty configuration)
    alacritty
    
    # Additional utilities
    gammastep        # Blue light filter
    playerctl        # Media control
    brightnessctl    # Brightness control
    # pamixer          # Volume control (temporarily disabled due to build issues)
    pulsemixer       # Volume control (alternative to pamixer)
    
    # Mouse cursor theme
    adwaita-icon-theme  # Adwaita cursor theme
    
    # Wayland-specific tools
    wlr-randr        # Display management
    xwayland         # X11 compatibility layer
  ];

  # XDG portal configuration for Hyprland
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-hyprland
      xdg-desktop-portal-gtk
    ];
  };

  # Security and session management
  security = {
    polkit.enable = true;
    pam.services.hyprlock = {};
  };

  # Environment variables for Wayland
  environment.sessionVariables = {
    # Wayland
    NIXOS_OZONE_WL = "1";
    
    # Hyprland specific
    WLR_NO_HARDWARE_CURSORS = "1";
    WLR_RENDERER_ALLOW_SOFTWARE = "1";
    
    # Input method (継続使用)
    GTK_IM_MODULE = "fcitx";
    QT_IM_MODULE = "fcitx";
    XMODIFIERS = "@im=fcitx";
    INPUT_METHOD = "fcitx";
    WAYLAND_IM_MODULE = "fcitx";
    
    # Qt/GTK themes
    QT_QPA_PLATFORM = "wayland;xcb";
    GDK_BACKEND = "wayland,x11";
    SDL_VIDEODRIVER = "wayland";
    CLUTTER_BACKEND = "wayland";
  };

  # Enable required services
  services = {
    dbus.enable = true;
    gvfs.enable = true;
    tumbler.enable = true;  # Thumbnail service
  };

  # Hardware acceleration
  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
    };
  };
}
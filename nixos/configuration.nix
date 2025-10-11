# NixOS system configuration
{ config, pkgs, lib, ... }:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix

    # System modules
    ./system/default.nix
    ./desktop/default.nix
    ./services/default.nix
    ./storage/default.nix

    # AppImage support
    ./packages/appimages.nix
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # System settings
  system.stateVersion = "25.05"; # Did you read the comment?

  # Nix settings
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };

  # Network settings
  networking = {
    hostName = "nixos"; # Define your hostname.
    networkmanager.enable = true;
    # ファイアウォール設定はTailscaleとファイルサーバモジュールで管理
    firewall.enable = true;
  };

  # Time zone and internationalization
  time.timeZone = "Asia/Tokyo";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "ja_JP.UTF-8";
    LC_IDENTIFICATION = "ja_JP.UTF-8";
    LC_MEASUREMENT = "ja_JP.UTF-8";
    LC_MONETARY = "ja_JP.UTF-8";
    LC_NAME = "ja_JP.UTF-8";
    LC_NUMERIC = "ja_JP.UTF-8";
    LC_PAPER = "ja_JP.UTF-8";
    LC_TELEPHONE = "ja_JP.UTF-8";
    LC_TIME = "ja_JP.UTF-8";
  };

  # ファイルシステム設定はstorage/default.nixで管理

  # Environment variables for Japanese input
  environment.sessionVariables = {
    GTK_IM_MODULE = "fcitx";
    QT_IM_MODULE = "fcitx";
    XMODIFIERS = "@im=fcitx";
    INPUT_METHOD = "fcitx";
    SDL_IM_MODULE = "fcitx";
    GLFW_IM_MODULE = "ibus";
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Desktop environment settings moved to desktop/default.nix

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Graphics support for Wine
  hardware.graphics.enable = true;
  hardware.graphics.enable32Bit = true;

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # User configuration
  users.mutableUsers = false;
  users.users.miyoshi_s = {
    isNormalUser = true;
    description = "miyoshi_s";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    hashedPassword = "$6$mkbGmoIi0MUYy8yK$Sb27D2/bwxBHqD6i1uyH2yAmIYFCUIZGkTa9FjWUYuE4tiR3R/RarqSbJCIQl0k4dl5qRgtMXrF5DofFqp1UG1";
    shell = pkgs.zsh;
    packages = with pkgs; [
    #  thunderbird
    ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Install firefox.
  programs.firefox.enable = true;

  # System packages
  environment.systemPackages = with pkgs; [
    vim
    git
    curl
    wget
    unzip
    gnumake
    gcc
    cmake
    python3
    openssl
    jq
    file
    # Wine
    wineWowPackages.staging
    winetricks
    # NW.js
    nwjs
    # Cursor (extracted from AppImage)
    (pkgs.callPackage ./packages/cursor/extracted.nix { })
  ];

  # Enable programs
  programs = {
    zsh.enable = true;
    git.enable = true;
  };

  # Git SSH Server
  services.gitserver = {
    enable = true;
    authorizedKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICL34VaEgzwLhtlFTGBarQkJILQAatNVXFDt3zc92O8x miyoshi_s@nixos"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID5GTcPRV7SIMocsu6EsrpUVjgDkOmWA0hJq3xQpSWXy barleytea362@gmail.com"
    ];
    repositories = [
      "novel.git"
    ];
  };
}

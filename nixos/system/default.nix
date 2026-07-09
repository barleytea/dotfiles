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
    # NVIDIA プロプライエタリドライバー
    nvidia = {
      modesetting.enable = true;
      powerManagement.enable = false;
      powerManagement.finegrained = false;
      open = false; # オープンソースドライバーではなくプロプライエタリを使用
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };
  };

  # X11とWaylandでNVIDIAドライバーを使用
  services.xserver.videoDrivers = [ "nvidia" ];

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
        # Ensure remote logins don't fail when the client TERM isn't available.
        SetEnv = "TERM=xterm-256color";
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

  # サーバー用途: サスペンド・ハイバネートを完全に無効化
  # systemd の sleep 系ターゲットを無効化することで、
  # logind/GNOME/Hyprland等どこから systemctl suspend 等が呼ばれても実行されない
  systemd.targets = {
    sleep.enable = false;
    suspend.enable = false;
    hibernate.enable = false;
    hybrid-sleep.enable = false;
  };

  services.logind.settings.Login = {
    HandleLidSwitch = "ignore";
    HandleLidSwitchExternalPower = "ignore";
    HandleLidSwitchDocked = "ignore";
    HandleSuspendKey = "ignore";
    HandleHibernateKey = "ignore";
    IdleAction = "ignore";
  };

  # GDMログイン画面のアイドル時自動サスペンドを無効化
  # NVIDIAプロプライエタリドライバーはこの自動サスペンドからの復帰に失敗し、
  # atomic modeset エラーで画面が真っ黒に固まったまま戻らなくなる不具合があるため
  services.displayManager.gdm.autoSuspend = false;

  # Allow running pre-built binaries from generic Linux distributions (e.g. Claude CLI)
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc
      stdenv.cc.libc
      zlib
      openssl
      curl
      expat
      libuuid
      xorg.libxcb
      xorg.libX11
      xorg.libXext
    ];
  };
}

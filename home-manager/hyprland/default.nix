# Hyprland-specific home-manager configuration
{ config, pkgs, lib, ... }:

let
  cfgEnabled = pkgs.stdenv.isLinux;
in
lib.mkIf cfgEnabled (
  let
    wallpaperFile =
      "${pkgs.nixos-artwork.wallpapers.simple-dark-gray}/share/backgrounds/nixos/nix-wallpaper-simple-dark-gray.png";
    hyprpaperConfig = ''
      preload = ${wallpaperFile}
      wallpaper = ,${wallpaperFile}
      splash = false
    '';
  in {
    xdg.configFile."hypr/hyprpaper.conf".text = hyprpaperConfig;
    xdg.configFile."hyprpaper/hyprpaper.conf".text = hyprpaperConfig;

    systemd.user.services.hyprpaper = {
      Unit = {
        Description = "Hyprpaper wallpaper daemon";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
        ConditionEnvironment = "WAYLAND_DISPLAY";
      };

      Service = {
        ExecStartPre = lib.mkForce (pkgs.writeShellScript "hyprpaper-prestart" ''
          ${pkgs.procps}/bin/pkill -x hyprpaper || true
        '');
        ExecStart = lib.mkForce "${pkgs.hyprpaper}/bin/hyprpaper -c ${config.xdg.configHome}/hyprpaper/hyprpaper.conf";
        Restart = lib.mkForce "on-failure";
        RestartSec = lib.mkForce 2;
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };

    systemd.user.services.waybar = {
      Unit = lib.mkForce {
        Description = "Waybar status bar";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
        Wants = [ "graphical-session.target" ];
        ConditionEnvironment = "WAYLAND_DISPLAY";
      };

      Service = {
        ExecStart = lib.mkForce "${pkgs.waybar}/bin/waybar -c /etc/xdg/waybar/config -s /etc/xdg/waybar/style.css";
        Restart = lib.mkForce "on-failure";
        RestartSec = lib.mkForce 2;
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  }
)

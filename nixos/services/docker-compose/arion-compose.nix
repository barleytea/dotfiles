# Arion Compose configuration for Kali Linux Docker container
# This file defines the Kali service with complete shell environment sharing
{ pkgs ? import <nixpkgs> { config = { allowUnfree = true; }; }, ... }:

let
  # Current user info
  uid = builtins.toString (builtins.getEnv "UID");
  gid = builtins.toString (builtins.getEnv "GID");
  username = builtins.getEnv "USER";

  # Container paths (following XDG Base Directory spec)
  containerHome = "/home/${username}";
  containerConfigDir = "${containerHome}/.config";
  containerDataDir = "${containerHome}/.local/share";
  containerCacheDir = "${containerHome}/.cache";
  containerStateDir = "${containerHome}/.local/state";
in

{
  project.name = "kali-linux";

  services.kali = {
    service = {
      image = "kali-linux:latest";

      # User configuration - match host UID/GID for file permissions
      user = "${uid}:${gid}";

      # Volume mounts for environment sharing and persistence
      volumes = [
        # Zsh shell configuration (read-only)
        "$HOME/.config/zsh:${containerConfigDir}/zsh:ro"
        "$HOME/.zshenv:${containerHome}/.zshenv:ro"

        # Starship prompt configuration (read-only)
        "$HOME/.config/starship.toml:${containerConfigDir}/starship.toml:ro"

        # Sheldon plugin manager (read-only config, writable cache)
        "$HOME/.config/sheldon:${containerConfigDir}/sheldon:ro"
        "$HOME/.cache/sheldon:${containerCacheDir}/sheldon"

        # Atuin shell history (read-write for persistence)
        "$HOME/.local/share/atuin:${containerDataDir}/atuin"

        # Mise tool management (read-only config, writable data and cache)
        "$HOME/.config/mise:${containerConfigDir}/mise:ro"
        "$HOME/.local/share/mise:${containerDataDir}/mise"
        "$HOME/.cache/mise:${containerCacheDir}/mise"

        # Zsh shell history (read-write for persistence)
        "$HOME/.local/state/zsh:${containerStateDir}/zsh"

        # X11 socket for GUI support (read-only)
        "/tmp/.X11-unix:/tmp/.X11-unix:ro"

        # Docker shared volume for pentesting targets
        "/mnt/sda1/shares/docker:/mnt/shares/docker"

        # Work directory
        "$HOME/projects:${containerHome}/projects"
      ];

      # Environment variables for shell and GUI support
      environment = {
        # XDG Base Directory settings
        XDG_CONFIG_HOME = containerConfigDir;
        XDG_DATA_HOME = containerDataDir;
        XDG_CACHE_HOME = containerCacheDir;
        XDG_STATE_HOME = containerStateDir;

        # Zsh configuration
        ZDOTDIR = "${containerConfigDir}/zsh";
        HISTFILE = "${containerStateDir}/zsh/zsh-history";

        # Starship prompt
        STARSHIP_SHELL = "zsh";

        # Sheldon plugin manager
        SHELDON_CONFIG_DIR = "${containerConfigDir}/sheldon";

        # Atuin shell history
        ATUIN_DB_DIR = "${containerDataDir}/atuin";

        # Mise tool management
        MISE_USE_TOML = "1";
        MISE_EXPERIMENTAL = "1";
        MISE_DATA_DIR = "${containerDataDir}/mise";
        MISE_CONFIG_DIR = "${containerConfigDir}/mise";
        MISE_CACHE_DIR = "${containerCacheDir}/mise";

        # Shell settings
        SHELL = "/bin/zsh";
        TERM = "xterm-256color";

        # X11 display support
        DISPLAY = builtins.getEnv "DISPLAY";
        XAUTHORITY = "${containerHome}/.Xauthority";

        # Wayland support
        WAYLAND_DISPLAY = builtins.getEnv "WAYLAND_DISPLAY";
        QT_QPA_PLATFORM = "wayland";
        XDG_RUNTIME_DIR = "/tmp/xdg-runtime";

        # Home directory
        HOME = containerHome;
      };

      # Network configuration (bridge network for security)
      networks = [ "kali-network" ];

      # Resource allocation
      deploy = {
        resources = {
          limits = {
            cpus = "4";
            memory = "4G";
          };
          reservations = {
            cpus = "2";
            memory = "2G";
          };
        };
      };

      # Interactive terminal
      stdin_open = true;
      tty = true;

      # Default command
      command = [ "/bin/zsh" ];

      # Security options
      cap_drop = [ "ALL" ];
      security_opt = [ "no-new-privileges:true" ];

      # IPC for MIT-SHM X11 extension
      ipc = "host";
    };
  };

  # Bridge network for Kali service
  networks.kali-network = {
    driver = "bridge";
  };
}

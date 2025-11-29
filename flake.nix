{
  description = "Flake for Darwin";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    arion = {
      url = "github:hercules-ci/arion";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    nix-darwin,
    nixvim,
    arion,
  } @ inputs: let
    system = "aarch64-darwin"; # Default to Apple Silicon Mac
    linuxSystem = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    pkgsLinux = import nixpkgs {
      system = linuxSystem;
      config = {
        allowUnfree = true;
      };
    };

    # Override to skip tests
    nixpkgsWithOverlays = import nixpkgs {
      inherit system;
      config = {
        allowUnfree = true;
      };
      overlays = [
        (final: prev: {
          haskellPackages = prev.haskellPackages.override {
            overrides = hfinal: hprev: {
              system-fileio = hprev.system-fileio.overrideAttrs (oldAttrs: {
                doCheck = false;
              });
              persistent-sqlite = hprev.persistent-sqlite.overrideAttrs (oldAttrs: {
                doCheck = false;
              });
            };
          };
        })
      ];
    };
  in {

    devShells.${system}.default = pkgs.mkShell {
      packages = with pkgs; [
        # TODO: Add your development packages here
      ];
      shellHook = ''
        $SHELL
      '';
    };

    # Kali Linux Docker images (Linux only)
    packages.${linuxSystem} = {
      # Kali Linux Docker image with security tools
      kali-linux = pkgsLinux.dockerTools.buildLayeredImage {
        name = "kali-linux";
        tag = "latest";

        contents = with pkgsLinux; [
          # Base system utilities
          dockerTools.binSh
          coreutils
          bash
          zsh
          vim
          git
          curl
          wget
          jq
          htop
          tmux

          # X11 and GUI support
          xorg.libX11
          xorg.libXext
          xorg.libXrender
          xorg.libXrandr
          xorg.xauth
          xorg.xdpyinfo
          xorg.xhost
          libxcb
          libxkbcommon
          mesa

          # Additional GUI dependencies
          libxkbcommon
          libGL
          dbus
          fontconfig
          freetype
          gtk3
          libxrender

          # VNC server for remote desktop access
          tigervnc
          xorg.xvfb

          # Lightweight desktop environment
          openbox
          xterm

          # noVNC for browser-based access
          novnc
          python312Packages.websockify

          # Network scanning tools
          nmap
          masscan
          arp-scan
          tcpdump
          wireshark
          aircrack-ng
          traceroute
          bind

          # Web security tools
          burpsuite
          nikto
          sqlmap
          wpscan

          # Password testing tools
          hashcat
          john
          hydra

          # Exploitation frameworks
          metasploit

          # Reverse engineering tools
          ghidra
          radare2
          gdb
          binutils

          # System forensics
          sleuthkit

          # Wireless tools
          hostapd
          wpa_supplicant

          # SSL/TLS tools
          openssl
          nftables

          # Development tools
          python3
          nodejs
          go
          rustc
          cargo

          # Other utilities
          file
          findutils
          gnugrep
          gnused
          gawk
        ];

        extraCommands = ''
          cat > ./entrypoint.sh << 'ENTRYPOINT'
#!/bin/sh
mkdir -p /root/.local/state/zsh /root/.cache /root/.config/zsh.kali 2>/dev/null

# Source host .zshenv but override ZDOTDIR to prevent broken symlinks
if test -f /root/.zshenv; then
  # Get XDG_CONFIG_HOME setting from host
  . /root/.zshenv 2>/dev/null || true
fi

# Override ZDOTDIR to use writable kali directory instead of broken symlink
export ZDOTDIR="/root/.config/zsh.kali"

# Create wrapper .zshrc that sources host configuration
HOST_ZSH_DIR="/root/.config/zsh"
if test -L "$HOST_ZSH_DIR/.zshrc"; then
  BROKEN_TARGET=$(readlink "$HOST_ZSH_DIR/.zshrc" 2>/dev/null)
  if test -f "$BROKEN_TARGET" 2>/dev/null; then
    {
      echo "# Kali zsh config - sourcing host configuration from /nix/store"
      echo "source '$BROKEN_TARGET' 2>/dev/null || true"
      echo ""
      echo "# Kali-specific customizations"
      echo "export ZDOTDIR='/root/.config/zsh.kali'"
      echo "PROMPT='%F{green}[kali]%f %F{blue}%~%f '\$PROMPT"
    } > "$ZDOTDIR/.zshrc" 2>/dev/null
  fi
fi

# Fallback: ensure .zshrc exists
if test ! -f "$ZDOTDIR/.zshrc"; then
  {
    echo "# Kali Docker zsh configuration"
    echo "autoload -Uz compinit && compinit -d /root/.zcompdump 2>/dev/null"
    echo "setopt hist_save_no_dups hist_find_no_dups inc_append_history share_history"
    echo "export HISTSIZE=10000 SAVEHIST=10000"
    echo 'export HISTFILE="$ZDOTDIR/.zsh_history"'
    echo "PROMPT='%F{green}[kali]%f %F{blue}%~%f %# '"
    echo "alias ls='ls --color=auto' && alias ll='ls -la' && alias la='ls -A'"
  } > "$ZDOTDIR/.zshrc"
fi

# Setup desktop environment scripts (VNC + noVNC for browser access)
mkdir -p /root/.vnc 2>/dev/null

# Create Xvfb + Xvnc startup script
{
  cat << 'DESKTOP_SCRIPT'
#!/bin/sh
# Start Kali desktop environment with Xvfb + Xvnc

DISPLAY=:99

echo "Starting Kali Linux desktop environment..."
echo ""

# Clean up any previous instance
rm -f /tmp/.X''${DISPLAY#:}-lock 2>/dev/null || true
sleep 1

# Start Xvfb (Virtual X11 framebuffer display server)
echo "1. Starting Xvfb virtual X server..."
Xvfb ''$DISPLAY -screen 0 1920x1080x24 -ac &
XVFB_PID=$!
sleep 2

# Start Xvnc (VNC server) on the Xvfb display
echo "2. Starting Xvnc (VNC server)..."
DISPLAY=''$DISPLAY Xvnc \
  ''$DISPLAY \
  -geometry 1920x1080 \
  -depth 24 \
  -securitytypes none \
  -rfbport 5900 &
XVNC_PID=$!
sleep 2

# Find and try to start websockify with noVNC
NOVNC_PATH=\$(find /nix/store -type d -name "novnc-*" 2>/dev/null | head -1)
if [ -n "\$NOVNC_PATH" ]; then
  NOVNC_WEB="\''${NOVNC_PATH}/share/webapps/novnc"
  if [ -d "\$NOVNC_WEB" ]; then
    echo "3. Starting websockify with noVNC..."
    websockify --web="\$NOVNC_WEB" 6080 localhost:5900 &
    WS_PID=''$!
    sleep 2
  fi
fi

echo ""
echo "========================================================"
echo "SUCCESS! Kali desktop environment started"
echo "========================================================"
echo ""
echo "X11 Display:        ''$DISPLAY"
echo "VNC Server:         localhost:5900"
echo ""
echo "Access methods:"
echo "  1. Browser (noVNC):  http://localhost:6080/vnc.html"
echo "  2. VNC client:       vncviewer localhost:5900"
echo "  3. X11 GUI apps:     DISPLAY=''$DISPLAY export DISPLAY"
echo ""
echo "Example: Launch Ghidra on host display"
echo "  DISPLAY=:0 ghidra"
echo ""
echo "========================================================"
echo ""

# Keep processes running
wait
DESKTOP_SCRIPT
} > /root/.vnc/start-desktop.sh 2>/dev/null || true
chmod +x /root/.vnc/start-desktop.sh 2>/dev/null || true

# Create simple wrapper for quick X11 GUI app launching
{
  cat << 'GUI_LAUNCH'
#!/bin/sh
# Launch GUI application on host X11 display
# Usage: launch-gui-app <app> [args...]

if [ ''$# -eq 0 ]; then
  echo "Usage: ''$0 <application> [args...]"
  echo "Examples: ''$0 ghidra, ''$0 burpsuite"
  exit 1
fi

export DISPLAY=:0
exec "''$@"
GUI_LAUNCH
} > /root/.vnc/launch-gui-app.sh 2>/dev/null || true
chmod +x /root/.vnc/launch-gui-app.sh 2>/dev/null || true

# Create information script
{
  cat << 'INFO_SCRIPT'
#!/bin/sh
# Display Kali Linux container information

echo "=== Kali Linux Container Information ==="
echo ""
echo "Shell Configuration:"
echo "  SHELL: ''$SHELL"
echo "  ZDOTDIR: ''$ZDOTDIR"
echo "  HISTFILE: ''$HISTFILE"
echo ""
echo "Display/Desktop:"
echo "  DISPLAY: ''$DISPLAY"
echo "  WAYLAND_DISPLAY: ''$WAYLAND_DISPLAY"
echo "  XDG_SESSION_TYPE: ''$XDG_SESSION_TYPE"
echo ""
echo "Tool Management:"
echo "  Mise Config: ''$MISE_CONFIG_DIR"
echo "  Mise Data: ''$MISE_DATA_HOME"
echo ""
echo "History & Shell State:"
echo "  Atuin History: ''$ATUIN_DB_DIR"
echo "  Zsh State: ''$HOME/.local/state/zsh"
echo ""
echo "Available Commands:"
echo "  - /root/.vnc/start-desktop.sh      # Start desktop (VNC + browser)"
echo "  - /root/.vnc/launch-gui-app.sh     # Launch GUI app on host display"
echo "  - kali-info                        # Show this information"
echo ""
echo "Desktop Access Methods (after starting desktop):"
echo "  1. Browser noVNC: http://localhost:6080/vnc.html"
echo "  2. VNC client:    vncviewer localhost:5900"
echo "  3. X11 forwarding (CLI): SSH with -X flag"
echo ""
INFO_SCRIPT
} > /root/.vnc/kali-info.sh 2>/dev/null || true
chmod +x /root/.vnc/kali-info.sh 2>/dev/null || true

# Create a convenience alias
alias kali-info='/root/.vnc/kali-info.sh' 2>/dev/null || true
alias start-desktop='/root/.vnc/start-desktop.sh' 2>/dev/null || true

# Start zsh in the background for docker logs visibility
# Users can still exec into the shell with: docker exec -it kali-pentesting zsh
/bin/zsh -l "$@" &

# Keep container running
exec sleep infinity
ENTRYPOINT
          chmod +x ./entrypoint.sh
        '';

        config = {
          Entrypoint = [ "/entrypoint.sh" ];
          Env = [
            "PATH=/run/current-system/sw/bin:/bin:/usr/bin:/usr/sbin"
            "SHELL=/bin/zsh"
            "TERM=xterm-256color"
          ];
          WorkingDir = "/root";
          Volumes = {
            "/tmp" = {};
            "/root" = {};
          };
          ExposedPorts = {
            "8080/tcp" = {};  # For web proxies like Burp
            "5900/tcp" = {};  # For VNC
            "8000/tcp" = {};  # For HTTP servers
            "8443/tcp" = {};  # For HTTPS servers
          };
        };

        maxLayers = 100;
      };
    };

    # Arion Compose app (Linux only)
    apps.${linuxSystem}.kali-compose = {
      type = "app";
      program = toString (
        pkgsLinux.writeShellScript "arion-kali" ''
          set -e
          export ARION_DOCKER_COMPOSE_DERIVATION=${arion.packages.${linuxSystem}.arion}
          exec ${arion.packages.${linuxSystem}.arion}/bin/arion --file ${./nixos/services/docker-compose/arion-compose.nix} "$@"
        ''
      );
    };

    homeConfigurations = {
      home = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgsWithOverlays;  # オーバーライドしたpkgsを使用
        extraSpecialArgs = {
          inherit inputs;
        };
        modules = [
          ./home-manager/default.nix
        ];
      };
    };

    darwinConfigurations =  {
      all = nix-darwin.lib.darwinSystem {
        system = system;
        modules = [
          ./darwin/default.nix
        ];
      };

      homebrew = nix-darwin.lib.darwinSystem {
        system = system;
        modules = [
          ./darwin/homebrew/default.nix
        ];
      };

      system = nix-darwin.lib.darwinSystem {
        system = system;
        modules = [
          ./darwin/system/default.nix
        ];
      };

      service = nix-darwin.lib.darwinSystem {
        system = system;
        modules = [
          ./darwin/service/default.nix
        ];
      };
    };

    # NixOS configurations (新規追加)
    nixosConfigurations = {
      desktop = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./nixos/configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.miyoshi_s = import ./home-manager;
              extraSpecialArgs = { inherit inputs; };
            };
          }
        ];
      };
    };
  };
}

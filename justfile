[private]
@default: help

# ================== Nix =================#

nix-channel-update:
  #!/usr/bin/env bash
  source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  nix-channel --add https://nixos.org/channels/nixpkgs-unstable
  nix-channel --update

nix-apply:
  #!/usr/bin/env bash
  source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  nix flake update
  nix run nixpkgs#home-manager -- switch --flake .#home --impure

nix-uninstall:
  #!/usr/bin/env bash
  source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  /nix/nix-uninstaller uninstall

nix-darwin-install:
  #!/usr/bin/env bash
  source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  nix --extra-experimental-features "nix-command flakes" run nix-darwin -- switch --flake ./darwin/default.nix

nix-darwin-apply:
  #!/usr/bin/env bash
  source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  nix --extra-experimental-features "nix-command flakes" run nix-darwin -- switch --flake .#darwin --impure

nix-update-all: nix-channel-update nix-apply nix-darwin-apply

# ================ Others ================#

npm-tools:
  #!/usr/bin/env bash
  sudo n latest
  npm i -g npm
  npm i -g gitmoji-cli

paths:
  #!/usr/bin/env bash
  echo $PATH | tr ':' '\n'

@help:
  #!/usr/bin/env bash
  echo "Usage: just <recipe>"
  echo ""
  just --list

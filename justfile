[private]
@default: help

# ================== Nix =================#

nix-channel-update:
  #!/usr/bin/env bash
  source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  nix-channel --add https://nixos.org/channels/nixpkgs-unstable
  nix-channel --update

home-manager-apply:
  #!/usr/bin/env bash
  source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  nix flake update
  nix run nixpkgs#home-manager -- switch --flake .#home --impure

nix-uninstall:
  #!/usr/bin/env bash
  source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  /nix/nix-uninstaller uninstall

nix-darwin-apply:
  #!/usr/bin/env bash
  source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  nix --extra-experimental-features "nix-command flakes" run nix-darwin -- switch --flake .#all --impure

nix-darwin-homebrew-apply:
  #!/usr/bin/env bash
  source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  nix --extra-experimental-features "nix-command flakes" run nix-darwin -- switch --flake .#homebrew --impure

nix-darwin-system-apply:
  #!/usr/bin/env bash
  source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  nix --extra-experimental-features "nix-command flakes" run nix-darwin -- switch --flake .#system --impure

nix-darwin-service-apply:
  #!/usr/bin/env bash
  source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  nix --extra-experimental-features "nix-command flakes" run nix-darwin -- switch --flake .#service --impure

nix-update-all: nix-channel-update home-manager-apply nix-darwin-apply

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

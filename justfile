dotfilesPath := "$HOME/git_repos/github.com/barleytea/dotfiles"

default:
  @just --choose

nix-install:
  #!/usr/bin/env bash
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm
  source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  nix --version
  nix-channel --add https://nixos.org/channels/nixpkgs-unstable
  nix-channel --update

nix-apply:
  #!/usr/bin/env bash
  source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  source $HOME/.zshrc
  # echo "Updating flake..."
  # nix flake update
  # echo "Updating profile..."
  # nix profile upgrade barleytea-packages
  echo "Updating home-manager..."
  nix run nixpkgs#home-manager -- switch --flake .#barleyteaHomeConfig

nix-uninstall:
  #!/usr/bin/env bash
  source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  /nix/nix-uninstaller uninstall

nix-darwin-install:
  #!/usr/bin/env bash
  source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  echo $SHELL
  which nix
  which nix-build
  nix-build https://github.com/LnL7/nix-darwin/archive/master.tar.gz -A installer
  ./result/bin/darwin-installer

nix-darwin-apply:
  #!/usr/bin/env bash
  source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  echo "Updating nix-darwin..."
  nix --extra-experimental-features nix-command run nix-darwin -- switch --flake .#barleytea-darwin

nix-darwin-update:
  #!/usr/bin/env bash
  source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  nix-channel --update darwin
  darwin-rebuild changelog

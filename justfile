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
  nix run . switch

nix-uninstall:
  /nix/nix-uninstaller uninstall

nix-darwin-install:
  #!/usr/bin/env bash
  nix-build https://github.com/LnL7/nix-darwin/archive/master.tar.gz -A installer
  ./result/bin/darwin-installer

nix-darwin-apply:
  #!/usr/bin/env bash
  darwin-rebuild switch

nix-darwin-update:
  #!/usr/bin/env bash
  nix-channel --update darwin
  darwin-rebuild changelog

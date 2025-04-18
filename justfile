[private]
@default: help

# ================== nix ================= #

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

# ================ pre-commit ============ #

pre-commit-init:
  #!/usr/bin/env bash
  pre-commit install

pre-commit-run:
  #!/usr/bin/env bash
  pre-commit run --all-files

# ================ vscode ================ #

# ref: https://scrapbox.io/mrsekut-p/VSCode%E3%81%AE%E8%A8%AD%E5%AE%9A%E3%82%92dotfiles%E3%81%A7%E7%AE%A1%E7%90%86%E3%81%99%E3%82%8B

vscode-apply:
  #!/usr/bin/env bash
  bash vscode/settings/index.sh
  bash vscode/extensions/apply.sh

vscode-insiders-apply:
  #!/usr/bin/env bash
  bash vscode/settings/index_insiders.sh
  bash vscode/extensions/apply_insiders.sh

vscode-save:
  #!/usr/bin/env bash
  bash vscode/extensions/save.sh

# ================ others ================ #

npm-tools:
  #!/usr/bin/env bash
  sudo n latest
  sudo npm i -g npm
  sudo npm i -g commitizen cz-git

zsh:
  #!/usr/bin/env bash
  time (zsh -i -c exit)

paths:
  #!/usr/bin/env bash
  echo $PATH | tr ':' '\n'

@help:
  #!/usr/bin/env bash
  echo "Usage: just <recipe>"
  echo ""
  just --list

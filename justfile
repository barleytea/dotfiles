dotfilesPath := "$HOME/git_repos/github.com/barleytea/dotfiles"

default:
  @just --choose

# ========== Deploying Dotfiles ==========#

list-deploy-targets:
  #!/usr/bin/env bash
  CANDIDATES=($(ls -A | grep '^\..*'))
  EXCLUSIONS=(".git" ".DS_Store" ".gitmodules" ".gitignore")
  DOTFILES=()

  for candidate in "${CANDIDATES[@]}"; do
    skip=false
    for exclusion in "${EXCLUSIONS[@]}"; do
      if [[ "$candidate" == "$exclusion" ]]; then
        skip=true
        break
      fi
    done
    if [ "$skip" = false ]; then
      DOTFILES+=("$candidate")
    fi
  done
  
  echo '===> List of config files to be deployed:'
  echo ''
  for val in "${DOTFILES[@]}"; do
    echo "$val"
  done

deploy:
  #!/usr/bin/env bash
  CANDIDATES=($(ls -A | grep '^\..*'))
  EXCLUSIONS=(".git" ".DS_Store" ".gitmodules" ".gitignore")
  DOTFILES=()

  for candidate in "${CANDIDATES[@]}"; do
    skip=false
    for exclusion in "${EXCLUSIONS[@]}"; do
      if [[ "$candidate" == "$exclusion" ]]; then
        skip=true
        break
      fi
    done
    if [ "$skip" = false ]; then
      DOTFILES+=("$candidate")
    fi
  done
  
  echo '===> Start to deploy config files to home directory.'
  echo ''
  for val in "${DOTFILES[@]}"; do
    ln -sfnv "$(realpath "$val")" "$HOME/$val"
  done

# ================== Nix =================#

nix-install:
  #!/usr/bin/env bash
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm

nix-channel-update:
  source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  nix --version
  nix-channel --add https://nixos.org/channels/nixpkgs-unstable
  nix-channel --update

nix-apply:
  #!/usr/bin/env bash
  source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  echo "Updating flake..."
  nix flake update
  echo "Updating home-manager..."
  nix run nixpkgs#home-manager -- switch --flake .#home --impure

nix-uninstall:
  #!/usr/bin/env bash
  source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  /nix/nix-uninstaller uninstall

nix-darwin-install:
  #!/usr/bin/env bash
  source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  # nix-build https://github.com/LnL7/nix-darwin/archive/master.tar.gz -A installer
  # ./result/bin/darwin-installer
  nix run nix-darwin -- switch --flake ./darwin/default.nix

nix-darwin-apply:
  #!/usr/bin/env bash
  source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  echo "Updating nix-darwin..."
  nix --extra-experimental-features nix-command --extra-experimental-features flakes run nix-darwin -- switch --flake .#darwin --impure

nix-update-all: nix-channel-update nix-apply nix-darwin-apply


# ================ Others ================#

vim:
  #!/usr/bin/env bash
  bash ./vim.sh

npm-tools:
  #!/usr/bin/env bash
  sudo n latest
  npm i -g npm
  npm i -g gitmoji-cli

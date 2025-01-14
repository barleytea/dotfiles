# Installation

- [1. Manually craete a directory that matches the ghq root.](#1-manually-craete-a-directory-that-matches-the-ghq-root)
- [2. Set up nix.conf](#2-set-up-nixconf)
- [3. Install nix](#3-install-nix)
- [4. Update nix channel](#4-update-nix-channel)
- [5. Apply nix config](#5-apply-nix-config)
- [6. Launch zsh](#6-launch-zsh)
- [7. Apply darwin config](#7-apply-darwin-config)

## 1. Craete a directory that matches the ghq root.

```sh
cd ~
mkdir -p git_repos/github.com/barleytea
cd git_repos/github.com/barleytea
git clone https://github.com/barleytea/dotfiles.git
```

## 2. Set up nix.conf

```sh
mkdir -p "$HOME/.config"
echo 'experimental-features = nix-command flakes' > "$HOME/.config/nix.conf"
```

## 3. Install nix

```sh
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm
source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
```

## 4. Update nix channel

```sh
nix-channel --add https://nixos.org/channels/nixpkgs-unstable
nix-channel --update
```

## 5. Apply nix config

```sh
nix flake update
nix run nixpkgs#home-manager -- switch --flake .#home --impure
```

## 6. Launch zsh

```sh
zsh
```

## 7. Apply darwin config

```sh
just nix-darwin-apply
```

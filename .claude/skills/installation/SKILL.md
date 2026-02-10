---
name: installation
description: Step-by-step installation guide for Nix and dotfiles setup including nix.conf configuration, channel updates, home-manager, and nix-darwin
---

# Installation

This guide covers installation for both macOS (using nix-darwin) and NixOS.

**macOS Installation:**
- [1. Create dotfiles directory](#1-craete-a-directory-that-matches-the-ghq-root)
- [2. Set up local nix.conf](#2-set-up-local-nixconf)
- [3. Install nix](#3-install-nix)
- [4. Set up global nix.conf](#4-set-up-global-nixconf)
- [5. Update nix channel](#5-update-nix-channel)
- [6. Apply home-manager config](#6-apply-home-manager-config)
- [7. Launch zsh](#7-launch-zsh)
- [8. Apply darwin config](#8-apply-darwin-config)

**NixOS Installation:**
- [NixOS Setup](#nixos-setup)

## 1. Craete a directory that matches the ghq root.

```sh
cd ~
mkdir -p git_repos/github.com/barleytea
cd git_repos/github.com/barleytea
git clone https://github.com/barleytea/dotfiles.git
```

## 2. Set up local nix.conf

```sh
mkdir -p "$HOME/.config/nix"
echo 'experimental-features = nix-command flakes' > "$HOME/.config/nix/nix.conf"
echo 'use-xdg-base-directories = true' >> "$HOME/.config/nix/nix.conf"
echo 'warn-dirty = false' >> "$HOME/.config/nix/nix.conf"
```

## 3. Install nix

```sh
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm
source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
```

## 4. Set up global nix.conf

1. edit /etc/nix/nix.conf

```sh
sudo vi /etc/nix/nix.conf
```

1. add the following to the file

```sh
extra-trusted-users = miyoshi_s
use-xdg-base-directories = true
```

1. restart nix-daemon

```sh
sudo launchctl unload /Library/LaunchDaemons/org.nixos.nix-daemon.plist
sudo launchctl load /Library/LaunchDaemons/org.nixos.nix-daemon.plist
```

## 5. Update nix channel

```sh
nix-channel --add https://nixos.org/channels/nixpkgs-unstable
nix-channel --update
```

## 6. Apply home-manager config

```sh
cd ~/git_repos/github.com/barleytea/dotfiles/darwin
nix flake update
nix run nixpkgs#home-manager -- switch --flake .#home --impure
```

## 7. Launch zsh

```sh
zsh
```

## 8. Apply darwin config

```sh
cd ~/git_repos/github.com/barleytea/dotfiles
make nix-darwin-apply
```

---

## NixOS Setup

For NixOS systems, the installation process is different as NixOS manages the entire system configuration.

### 1. Create dotfiles directory

```sh
cd ~
mkdir -p git_repos/github.com/barleytea
cd git_repos/github.com/barleytea
git clone https://github.com/barleytea/dotfiles.git
```

### 2. Set up local nix.conf

```sh
mkdir -p "$HOME/.config/nix"
echo 'experimental-features = nix-command flakes' > "$HOME/.config/nix/nix.conf"
echo 'use-xdg-base-directories = true' >> "$HOME/.config/nix/nix.conf"
echo 'warn-dirty = false' >> "$HOME/.config/nix/nix.conf"
```

### 3. Copy hardware configuration

```sh
cd ~/git_repos/github.com/barleytea/dotfiles/nixos
sudo nixos-generate-config --show-hardware-config > hardware-configuration.nix
```

### 4. Update system configuration

Edit `nixos/configuration.nix` and `nixos/flake.nix` to match your system.

### 5. Build and apply NixOS configuration

```sh
cd ~/git_repos/github.com/barleytea/dotfiles
sudo nixos-rebuild switch --flake ./nixos#desktop
```

This command applies both system and home-manager configurations.

### 6. Reboot

```sh
sudo reboot
```

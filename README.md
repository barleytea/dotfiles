## Installation

Manually craete a directory that matches the ghq root.

```sh
cd ~
mkdir -p git_repos/github.com/barleytea
cd git_repos/github.com/barleytea
git clone https://github.com/barleytea/dotfiles.git
```

### Set up nix.conf

```sh
mkdir -p "$HOME/.config"
echo 'experimental-features = nix-command flakes' > "$HOME/.config/nix.conf"
echo 'use-xdg-base-directories = true' >> ~/.config/nix.conf
```

### Install nix

```sh
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm
source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
```

### Update nix channel

```sh
nix-channel --add https://nixos.org/channels/nixpkgs-unstable
nix-channel --update
```

### Apply nix config

```sh
nix flake update
nix run nixpkgs#home-manager -- switch --flake .#home --impure
```

### Launch zsh (fish)

```sh
zsh
```

### Apply darwin config

```sh
just nix-darwin-apply
```

## Operation

### Update Home Settings

```sh
just home-manager-apply
```

### Update Darwin Settings

```sh
just nix-darwin-apply
```

### Update All Settings

```sh
just nix-update-all
```

### Install a new package

```sh
nix profile install nixpkgs#hoge
```

### Rollback

1. Check generations 

    ```sh
    nix-env --list-generations
    ```

    ```
    1   2024-10-17 10:19:29   
    2   2024-10-17 11:55:16   
    3   2024-10-17 19:19:37   
    4   2024-11-06 18:37:37   
    5   2024-11-06 18:52:58   (current)
    ```

1. Rollback

    ```sh
    nix-env --rollback
    ```

    or

    ```sh
    nix-env --switch-generation 3
    ```

## Shell Environment

The default shell is zsh, but fish is launched within .zshrc

```sh
if [[ -o interactive ]]; then
    exec fish
fi
```

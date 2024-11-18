## Installation

Manually craete a directory that matches the ghq root.

```sh
cd ~
mkdir -p git_repos/github.com/barleytea
cd git_repos/github.com/barleytea
git clone https://github.com/barleytea/dotfiles.git
```

### Install just

```sh
bash ./just-install.sh
```

### Install nix

```sh
just nix-install
```

### Install nix-darwin

```sh
just nix-darwin-install
```

### Apply nix config

```sh
just nix-apply
just nix-darwin-apply
```

### Deploy dotfiles symbolic link

```sh
just deploy
```

### Install vim-related stuffs

```sh
just set-up-vim
```

## Operation

### Update all packages

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

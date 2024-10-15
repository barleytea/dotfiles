# Installation

Manually craete a directory that matches the ghq root.

```bash
$ cd ~
$ mkdir -p git_repos/github.com/barleytea
$ cd git_repos/github.com/barleytea
$ git clone https://github.com/barleytea/dotfiles.git
```

## install just

```sh
$ bash ./just-install.sh
```

## install nix

```sh
$ just nix-install
```

## install nix-darwin

```sh
$ just nix-darwin-install
```

## apply nix config

```sh
$ just nix-apply
$ just nix-darwin-apply
```

* Deploy dotfiles symbolic link
* Install apps via Homebrew
* Install vim-related stuffs
```bash
$ cd dotfiles && make all
```

## Shell Environment

The default shell is zsh, but fish is launched within .zshrc

```sh
if [[ -o interactive ]]; then
    exec fish
fi
```

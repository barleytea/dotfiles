# dotfiles

## Install

Download installation materials.
```bash
$ cd ~
$ mkdir -p git_repos/github.com/barleytea
$ cd git_repos/github.com/barleytea
$ git clone https://github.com/barleytea/dotfiles.git
```

Set up:
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

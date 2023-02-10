#!/bin/bash -ux

THIS_DIR=$(cd $(dirname $0); pwd)

curl -fLo $THIS_DIR/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
ln -s $THIS_DIR/.vim $HOME/.config/nvim
ln -s $THIS_DIR/.vimrc $HOME/.config/nvim/init.vim
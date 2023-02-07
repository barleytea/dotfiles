#!/bin/bash -ux

THIS_DIR=$(cd $(dirname $0); pwd)

curl -fLo $THIS_DIR/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
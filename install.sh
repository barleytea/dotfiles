#!/bin/bash -ux

THIS_DIR=$(cd $(dirname $0); pwd)

echo "start setup..."
cd $HOME

#============ brew ============#

if [ $(uname) = Darwin ]; then
	echo "installing Homebrew ..."
	which brew >/dev/null 2>&1 || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
else
	echo "installing Linuxbrew ..."
	which brew >/dev/null 2>&1 || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Linuxbrew/install/master/install.sh)"
	export PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/bin:$PATH"
fi

cd $THIS_DIR

echo "run brew doctor ..."
which brew >/dev/null 2>&1 && brew doctor

echo "run brew update ..."
brew update

echo "ok. run brew upgrade ..."
brew upgrade

brew bundle

brew cleanup

#============ vim =============#

curl -fLo $THIS_DIR/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

#============ fish ============#

# install fisher
curl https://git.io/fisher --create-dirs -sLo $THIS_DIR/.config/fish/functions/fisher.fish

# install plugin-peco for fish
fisher add oh-my-fish/plugin-peco

# install z for fish
fisher add jethrokuan/z

# install fish-bd for fish
fisher add 0rax/fish-bd

# install fish-peco_select_ghq_repository for fish
fisher add yoshiori/fish-peco_select_ghq_repository

# install fish-peco_recentd
fisher add tsu-nera/fish-peco_recentd

# install fish-ghq
fisher add decors/fish-ghq

#==============================#

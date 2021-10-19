#!/bin/bash -ux

THIS_DIR=$(cd $(dirname $0); pwd)

git submodule init
git submodule update

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

curl https://raw.githubusercontent.com/Shougo/dein.vim/master/bin/installer.sh > $HOME/.vim/bundles/installer.sh
sh $HOME/.vim/bundles/installer.sh $HOME.vim/bundles

#============ fish ============#

# install fisher
curl https://git.io/fisher --create-dirs -sLo ~/.config/fish/functions/fisher.fish

# install plugin-peco for fish
fisher install oh-my-fish/plugin-peco

# install z for fish
fisher install jethrokuan/z

# install fish-bd for fish
fisher add 0rax/fish-bd

# install fish-peco_select_ghq_repository for fish
fisher add yoshiori/fish-peco_select_ghq_repository

# install fish-peco_recentd
fisher add tsu-nera/fish-peco_recentd

# install fish-ghq
fisher install decors/fish-ghq

#==============================#

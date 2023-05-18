#!/bin/bash -ux

THIS_DIR=$(cd $(dirname $0); pwd)

echo "THIS_DIR ..."
echo $THIS_DIR
echo "HOME ..."
echo $HOME

cd $HOME

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
# which brew >/dev/null 2>&1 && brew doctor

echo "run brew update ..."
# brew update

echo "ok. run brew upgrade ..."
# brew upgrade

echo "run brew bundle ..."
brew bundle --global

echo "run brew cleanup ..."
brew cleanup
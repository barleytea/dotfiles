export ZSH=/Users/miyoshi_s/.oh-my-zsh
export PATH="$HOME/.jenv/bin:$PATH"
eval "$(jenv init -)"
export M2_HOME=/usr/local/Cellar/maven/3.5.2/
export M2=$M2_HOME/bin
export PATH=$M2:$JAVA_HOME:$PATH

ZSH_THEME="bullet-train"

plugins=(
  git
  osx
  zsh-syntax-highlighting
  zsh-completions
)

autoload -U compinit && compinit -u

source $ZSH/oh-my-zsh.sh

if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='mvim'
fi

alias dd='cd ../'
alias ls='ls -G'
alias ll='ls -alG'

alias mvim=/Applications/MacVim.app/Contents/bin/mvim "$@"
if [ -f $(brew --prefix)/etc/brew-wrap ];then
  source $(brew --prefix)/etc/brew-wrap
fi

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

export PATH="$PYENV_ROOT/bin:$PATH"
export PYENV_ROOT="$HOME/.pyenv"
eval "$(pyenv init -)"
export PATH="$HOME/.anyenv/bin:$PATH"
eval "$(anyenv init -)"
for D in `ls $HOME/.anyenv/envs`
do
    export PATH="$HOME/.anyenv/envs/$D/shims:$PATH"
done

setopt NO_BEEP

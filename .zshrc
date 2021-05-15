# GENERAL {{{

  setopt no_beep
  bindkey -v

  setopt share_history
  setopt hist_reduce_blanks
  setopt hist_ignore_all_dups

# }}}

# ENVIRONMENT VALUES {{{

  # zplug
  export ZPLUG_HOME=/usr/local/opt/zplug

  # maven
  export M2_HOME=/usr/local/Cellar/maven/3.5.2/
  export M2=$M2_HOME/bin
  export PATH=$M2:$JAVA_HOME:$PATH

  # editor
  if [[ -n $SSH_CONNECTION ]]; then
    export EDITOR="vim"
  ele
    export EDITOR="mvim"
  fi

  #jenv
  export PATH="$HOME/.jenv/bin:$PATH"
  eval "$(jenv init -)"

  # pyenv
  export PATH="$PYENV_ROOT/bin:$PATH"
  export PYENV_ROOT="$HOME/.pyenv"
  eval "$(pyenv init -)"

  # anyenv
  export PATH="$HOME/.anyenv/bin:$PATH"
  eval "$(anyenv init -)"
  for D in `ls $HOME/.anyenv/envs`
  do
    export PATH="$HOME/.anyenv/envs/$D/shims:$PATH"
  done

  # rbenv
  export PATH="$HOME/.rbenv/shims$PATH"
  eval "$(rbenv init -)"

  # grep
  export PATH="/usr/local/opt/grep/libexec/gnubin:$PATH"
  export MANPATH="/usr/local/opt/grep/libexec/gnuman:$MANPATH"

  # homebrew
  export PATH="/usr/local/sbin:$PATH"

  # rust
  export PATH="$HOME/.cargo/bin:$PATH"

  # flutter
  export PATH="$PATH:$HOME/flutter_workspace/flutter/bin"

  # nvm
  export NVM_DIR="$HOME/.nvm"
  [ -s "/usr/local/opt/nvm/nvm.sh" ] && . "/usr/local/opt/nvm/nvm.sh"  # This loads nvm
  [ -s "/usr/local/opt/nvm/etc/bash_completion.d/nvm" ] && . "/usr/local/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion

  # go
  export GOPATH=$HOME/go

  # command history
  HISTFILE=$HOME/.zsh-history
  HISTSIZE=100000
  SAVEHIST=100000

# }}}

# IMPORTS {{{

  source $ZPLUG_HOME/init.zsh
  if [ -f $(brew --prefix)/etc/brew-wrap ];then
    source $(brew --prefix)/etc/brew-wrap
  fi

# }}}

# PLUGINS {{{

  zplug "bhilburn/powerlevel9k", use:"powerlevel9k.zsh-theme", as:theme
  zplug "plugins/git", from:oh-my-zsh
  zplug "zsh-users/zsh-completions"
  zplug "zsh-users/zsh-history-substring-search"
  zplug "zsh-users/zsh-autosuggestions"
  zplug "zsh-users/zsh-syntax-highlighting"

  zplug load --verbose

# }}}

# COMPLEMENT {{{

  autoload -U compinit; compinit -C
  zstyle ':completion:*' matcher-list '' 'm:{a-z}={A-Z} r:|[-_.]=**' '+m:{A-Z}={a-z} r:|[-_.]=**'

  setopt correct
  setopt correct_all
  setopt hist_expand
  setopt list_types
  setopt auto_list
  setopt auto_menu
  setopt list_packed
  setopt auto_param_keys
  setopt auto_param_slash
  setopt mark_dirs
  setopt auto_cd
  setopt nolistbeep

# }}}

# FUNCTIONS {{{

  function mkcd() {
    if [[ -d $1 ]]; then
      echo "It already exsits! Cd to the directory."
      cd $1
    else
      mkdir -p $1 && cd $1
    fi
  }

  function  fgrep() {
    find . -type f -print | xargs grep -n --binary-files=without-match $@
  }

  function chpwd() { ls }

# }}}

# ALIAS {{{

  alias mvim=/Applications/MacVim.app/Contents/bin/mvim "$@"
  alias reload="source ~/.zshrc"
  alias vsc="code"

  alias repos='ghq list -p | peco'
  alias repo='cd $(repos)'

  alias rgrep='grep -r --color=always --exclude-dir={.svn,tmp,tools,docs,.buildtool} --with-filename --line-number'

  if [[ $(command -v exa) ]]; then
    alias e='exa --icons --git'
    alias l=e
    alias ls=e
    alias ea='exa -a --icons --git'
    alias la=ea
    alias ee='exa -aahl --icons --git'
    alias ll=ee
    alias et='exa -T -L 3 -a -I "node_modules|.git|.cache" --icons'
    alias lt=et
    alias eta='exa -T -a -I "node_modules|.git|.cache" --color=always --icons | less -r'
    alias lta=eta
    alias l='clear && ls'
  fi

# }}}

# COLORS {{{

  autoload -Uz add-zsh-hook
  autoload -U colors
  colors

# }}}

# POWERLEVEL9K {{{

  POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(time context dir vcs)
  #POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(kubecontext)
  POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=()
  POWERLEVEL9K_TIME_FORMAT="%D{%m\/%d %H:%M}"
  POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX="\u25B8 "

# }}}

# SVN {{{

  export SVN_EDITOR=vim

# }}}

# LOAD .zshrc_local {{{

  [ -f ~/.zshrc_local ] && source ~/.zshrc_local

# }}}

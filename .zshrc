# GENERAL {{{

  setopt no_beep
  bindkey -v

  setopt share_history
  setopt hist_reduce_blanks
  setopt hist_ignore_all_dups

# }}}

# ENVIRONMENT VALUES {{{

  # zsh
  export ZPLUG_HOME=/usr/local/opt/zplug
  POWERLEVEL9K_MODE='nerdfont-complete'
  POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(time dir vcs)
  POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=()
  POWERLEVEL9K_DISABLE_RPROMPT=true
  POWERLEVEL9K_TIME_FORMAT="%D{%m\/%d %H:%M}"
  POWERLEVEL9K_TIME_FOREGROUND='white'
  POWERLEVEL9K_TIME_BACKGROUND='background'
  POWERLEVEL9K_PROMPT_ADD_NEWLINE=true
  POWERLEVEL9K_PROMPT_ON_NEWLINE=true
  POWERLEVEL9K_RPROMPT_ON_NEWLINE=false
  POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX=""
  POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX="\u25B8 "
  POWERLEVEL9K_LEFT_SEGMENT_SEPARATOR=''
  POWERLEVEL9K_RIGHT_SEGMENT_SEPARATOR=''

  # maven
  export M2_HOME=/usr/local/Cellar/maven/3.5.2/
  export M2=$M2_HOME/bin
  export PATH=$M2:$JAVA_HOME:$PATH

  # editor
  if [[ -n $SSH_CONNECTION ]]; then
    export EDITOR="vim"
  else
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

  # command history
  HISTFILE=$HOME/.zsh-history
  HISTSIZE=100000
  SAVEHIST=100000

# }}}

# IMPORTS {{{

  source $ZPLUG_HOME/init.zsh
  source ~/.powerlevel9k/powerlevel9k.zsh-theme
  if [ -f $(brew --prefix)/etc/brew-wrap ];then
    source $(brew --prefix)/etc/brew-wrap
  fi

# }}}

# PLUGINS {{{


# }}}

# COMPLEMENT {{{

  autoload -U compinit
  compinit -u
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
  zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

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

  alias dd="cd ../"
  alias ls="ls -G"
  alias ll="ls -alG"

  alias mvim=/Applications/MacVim.app/Contents/bin/mvim "$@"
  alias reload="source ~/.zshrc"

# }}}

# COLORS {{{

  autoload -Uz add-zsh-hook
  autoload -U colors
  colors

# }}}

# LOAD .zshrc_local {{{

  [ -f ~/.zshrc.local ] && source ~/.zshrc_local

# }}}

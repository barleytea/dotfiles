# GENERAL {{{

  setopt no_beep
  bindkey -v

  setopt share_history
  setopt hist_reduce_blanks
  setopt hist_ignore_all_dups

# }}}

# ENVIRONMENT VALUES {{{
  # grep
  export PATH="/usr/local/opt/grep/libexec/gnubin:$PATH"
  #zplug
  export ZPLUG_HOME=$HOME/.zplug

  # command history
  HISTFILE=$HOME/.zsh-history
  HISTSIZE=100000
  SAVEHIST=100000

  export DISPLAY=:1.0
  export GOPATH=$HOME/dev/go
  export PATH=$PATH:$GOPATH/bin
  export PATH=$PATH:/usr/local/bin

# }}}

# IMPORTS {{{

  source $ZPLUG_HOME/init.zsh

# }}}

# PLUGINS {{{

  zplug "bhilburn/powerlevel9k", use:"powerlevel9k.zsh-theme", as:theme
  zplug "plugins/git", from:oh-my-zsh
  zplug "zsh-users/zsh-completions"
  zplug "zsh-users/zsh-history-substring-search"
  zplug "zsh-users/zsh-autosuggestions"
  zplug "zsh-users/zsh-syntax-highlighting"
  # Install plugins if there are plugins that have not been installed
  if ! zplug check --verbose; then
    printf "Install? [y/N]: "
    if read -q; then
      echo; zplug install
    fi
  fi

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
  alias ls="ls -l --color=always"
  alias ll="ls -lA --color=always"
  alias reload="source ~/.zshrc"
  alias vsc="code"

  alias repos='ghq list -p | peco'
  alias repo='cd $(repos)'

  alias rgrep='grep -r --color=always --exclude-dir={.svn,tmp,tools,docs,.buildtool} --with-filename --line-number'
# }}}

# COLORS {{{

  autoload -Uz add-zsh-hook
  autoload -U colors
  colors

# }}}

# POWERLEVEL9K {{{

  POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(time context dir vcs)
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


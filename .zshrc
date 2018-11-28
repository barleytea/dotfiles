# GENERAL {{{

  setopt no_beep
  bindkey -v

  setopt share_history
  setopt hist_reduce_blanks
  setopt hist_ignore_all_dups

# }}}

# ENVIRONMENT VALUES {{{

  case ${OSTYPE} in
    darwin*)
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
      export PATH="$HOME/.rbenv/bin:$PATH"
      eval "$(rbenv init -)"
      ;;
    linux*)
      #zplug
      export ZPLUG_HOME=$HOME/.zplug
      ;;
  esac

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

  case ${OSTYPE} in
    darwin*)
      alias ls="colorls -l --sd"
      alias ll="colorls -lA --sd"
      alias lgs="colorls -lA --sd --gs"
      alias lgst="colorls -lA --sd --gs --tree"
      alias mvim=/Applications/MacVim.app/Contents/bin/mvim "$@"
      ;;
    linux*)
      alias ls="ls -l --color=always"
      alias ll="ls -lA --color=always"
      ;;
  esac
  alias reload="source ~/.zshrc"
  alias vsc="code"

  alias repos='ghq list -p | peco'
  alias g='cd $(repos)'
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

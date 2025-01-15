# NIX ENV {{{
  if [ -e "/nix/var/nix/profiles/per-user/$USER/home-manager/etc/profile.d/hm-session-vars.sh" ]; then
    . "/nix/var/nix/profiles/per-user/$USER/home-manager/etc/profile.d/hm-session-vars.sh"
  fi
# }}}

# XDG {{{
  export XDG_CONFIG_HOME=$HOME/.config
  export XDG_CACHE_HOME=$HOME/.cache
  export XDG_DATA_HOME=$HOME/.local/share
  export XDG_STATE_HOME=$HOME/.local/state
  export ZDOTDIR=$HOME/.config/zsh
# }}}

# USER {{{
  export USER=$(whoami)
  export DARWIN_USER=$(whoami)
# }}}

# PATH {{{
  if [ "$(uname)" = "Linux" ]; then
    export PATH="/home/linuxbrew/.linuxbrew/bin:$PATH"
  elif [ "$(uname)" = "Darwin" ]; then
    export PATH="/opt/homebrew/bin:$PATH"
  fi
  export PATH="$XDG_STATE_HOME/nix/profiles/profile/bin:$PATH"
  export PATH="$HOME/.cargo/bin:$PATH"
  export PATH="$HOME/fultter/bin:$PATH"
  export PATH="$HOME/go/bin:$PATH"
  export PATH="$HOME/.local/bin:$PATH"
# }}}

# GENERAL {{{
  setopt no_beep
  bindkey -v
  setopt share_history
  setopt hist_reduce_blanks
  setopt hist_ignore_all_dups
  setopt auto_cd
  HISTSIZE=100000
  SAVEHIST=100000
# }}}

# COMPLEMENT {{{
  autoload -Uz compinit
  zstyle ':completion:*' matcher-list '' 'm:{a-z}={A-Z} r:|[-_.]=**' '+m:{A-Z}={a-z} r:|[-_.]=**'
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
  compinit -d "$XDG_CACHE_HOME"/zsh/zcompdump-"$ZSH_VERSION"
# }}}

# HISTORY {{{
  export LESSHISTFILE="$XDG_STATE_HOME"/less/history
  export HISTFILE="$XDG_STATE_HOME"/zsh/zsh-history
# }}}

# FUNCTIONS {{{
  function mkcd() {
    if [[ -d $1 ]]; then
      cd $1
    else
      mkdir -p $1 && cd $1
    fi
  }

  function ghq_repository_search() {
    local select=$(ghq list --full-path | fzf --preview "bat --color=always --style=header,grid --line-range :80 {}/README.*")
    if [[ -n "$select" ]]; then
      cd "$select"
      zle reset-prompt
    fi
  }

  function peco_select_history() {
    local select=$(history | fzf)
    if [[ -n "$select" ]]; then
      BUFFER="$select"
      zle accept-line
    fi
  }

  zle -N ghq_repository_search
# }}}

# KEYBIND {{{
  bindkey '^G' ghq_repository_search
# }}}

# ALIAS {{{
  alias reload='source $HOME/.config/zsh/.zshrc'
  alias vsc="code"
  alias rgrep='grep -r --color=always --exclude-dir={.svn,tmp,tools,docs,.buildtool} --with-filename --line-number'
  alias proot='cd $(git rev-parse --show-toplevel)'
  alias vim=nvim
  alias g=git
  alias gmc='gitmoji -c'
  alias gcz='git cz'
  alias wget='wget --hsts-file="$XDG_DATA_HOME/wget-hsts"'

  if [[ $(command -v eza) ]]; then
    alias e='eza --icons --git'
    alias l=e
    alias ls=e
    alias ea='eza -a --icons --git'
    alias la=ea
    alias ee='eza -aahl --icons --git'
    alias ll=ee
    alias et='eza -T -L 3 -a -I "node_modules|.git|.cache" --icons'
    alias lt=et
    alias eta='eza -T -a -I "node_modules|.git|.cache" --color=always --icons | less -r'
    alias lta=eta
    alias l='clear && ls'
  fi
# }}}

# NIX {{{
  export NIX_PATH=$XDG_STATE_HOME/nix/defexpr/channels:/nix/var/nix/profiles/per-user/root/channels${NIX_PATH:+:$NIX_PATH}
  if [ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  fi
  export NIX_CONF_DIR=$XDG_CONFIG_HOME
# }}}

# Go {{{
  export GOPATH="$XDG_DATA_HOME"/go
# }}}

# Rust {{{
  export RUSTUP_HOME=$XDG_DATA_HOME/rustup
  export CARGO_HOME=$XDG_DATA_HOME/cargo
# }}}

# MISC {{{
  if [[ $TERM != "dumb" && -x "$(command -v starship)" ]]; then
    eval "$(starship init zsh)"
  fi
  eval "$(sheldon source)"
  eval "$(atuin init zsh)"
# }}}

# LOAD .zshrc_local {{{
  if [[ -f ~/.zshrc_local ]]; then
    echo ".zshrc_local loaded."
    source ~/.zshrc_local
  fi
# }}}

# fish {{{
#   if [[ -o interactive ]]; then
#     echo "fish executed."
#     exec fish
#   else
#     echo "not interactive"
#   fi
# }}}

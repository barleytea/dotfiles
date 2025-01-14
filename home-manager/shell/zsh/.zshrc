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
  export PATH="$HOME/.nix-profile/bin:$PATH"
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
  HISTFILE=$HOME/.zsh-history
  HISTSIZE=100000
  SAVEHIST=100000
# }}}

# COMPLEMENT {{{
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

# ALIAS {{{
  alias reload="source ~/.zshrc"
  alias vsc="code"
  alias rgrep='grep -r --color=always --exclude-dir={.svn,tmp,tools,docs,.buildtool} --with-filename --line-number'
  alias proot='cd $(git rev-parse --show-toplevel)'
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
    alias vim=nvim
    alias g=git
    alias gmc='gitmoji -c'
  fi
# }}}

# NIX {{{
  export NIX_PATH=$HOME/.nix-defexpr/channels:/nix/var/nix/profiles/per-user/root/channels${NIX_PATH:+:$NIX_PATH}
  if [ -e $HOME/.nix-profile/etc/profile.d/nix.sh ]; then
    . $HOME/.nix-profile/etc/profile.d/nix.sh;
  fi
  export NIX_CONF_DIR=$HOME/.config
# }}}

# KEYBIND {{{
  bindkey '^G' ghq_repository_search
# }}}

# MISC {{{
  eval "$(starship init zsh)"
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

# PATH {{{
  if [ "$(uname)" = "Linux" ]; then
    export PATH="/home/linuxbrew/.linuxbrew/bin:$PATH"
  fi
# }}}

# GENERAL {{{
  setopt no_beep
  bindkey -v
  setopt share_history # コマンド履歴ファイルを共有する
  setopt hist_reduce_blanks # 余計な空白を詰めて記録する
  setopt hist_ignore_all_dups # 直前と同じコマンドラインはヒストリに追加しない
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
# }}}

# ALIAS {{{
  alias reload="source ~/.zshrc"
  alias vsc="code"
  alias rgrep='grep -r --color=always --exclude-dir={.svn,tmp,tools,docs,.buildtool} --with-filename --line-number'
  if [[ $(command -v eza) ]]; then
    alias e='eza --icons --git'
    alias l=e
    alias ls=e
    alias ea='eza -a --icons --git'
    alias la=ea
    alias ee='eza -aahl --icons --git'f
    alias ll=ee
    alias et='eza -T -L 3 -a -I "node_modules|.git|.cache" --icons'
    alias lt=et
    alias eta='eza -T -a -I "node_modules|.git|.cache" --color=always --icons | less -r'
    alias lta=eta
    alias l='clear && ls'
  fi
# }}}

# MISC {{{
  [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
# }}}

eval "$(starship init zsh)"

# fish {{{
  if [[ -o interactive ]]; then
      exec fish
  fi
# }}}

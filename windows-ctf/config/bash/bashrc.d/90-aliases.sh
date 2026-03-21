#!/usr/bin/env bash
# Aliases (equivalent to aliases.zsh)

# General aliases
alias reload='source ${HOME}/.bashrc'
alias rgrep='grep -r --color=always --exclude-dir={.svn,tmp,tools,docs,.buildtool} --with-filename --line-number'
alias proot='cd $(git rev-parse --show-toplevel)'
alias g=git
alias gcz='git cz'
alias wget='wget --hsts-file="${XDG_DATA_HOME:-${HOME}/.local/share}/wget-hsts"'
alias wttr='curl -H "Accept-Language: ${LANG%_*}" --compressed "wttr.in/Tokyo"'

# tmux aliases
alias tls='tmux ls'
alias ta='tmux attach'
alias tac='tmux new-session -A -s main'

# eza aliases
if command -v eza >/dev/null 2>&1; then
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

# bat alias
if command -v bat >/dev/null 2>&1; then
  alias cat='bat --paging=never'
fi

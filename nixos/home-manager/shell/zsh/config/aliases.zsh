# General aliases
alias reload='source $HOME/.config/zsh/.zshrc'
alias rgrep='grep -r --color=always --exclude-dir={.svn,tmp,tools,docs,.buildtool} --with-filename --line-number'
alias proot='cd $(git rev-parse --show-toplevel)'
alias vim=nvim
alias g=git
alias gcz='git cz'
alias wget='wget --hsts-file="$XDG_DATA_HOME/wget-hsts"'
alias wttr='(){ curl -H "Accept-Language: ${LANG%_*}" --compressed "wttr.in/${1:-Tokyo}" }'
alias zjl='zellij ls'
alias zja='zellij attach'
alias zjac='zellij attach --create'

# eza aliases
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

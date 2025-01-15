# Create directory and cd into it
function mkcd() {
  if [[ -d $1 ]]; then
    cd $1
  else
    mkdir -p $1 && cd $1
  fi
}

# Search and cd into ghq repository
function ghq_repository_search() {
  local select=$(ghq list --full-path | fzf --preview "bat --color=always --style=header,grid --line-range :80 {}/README.*")
  if [[ -n "$select" ]]; then
    cd "$select"
    zle reset-prompt
  fi
}

# Search command history
function peco_select_history() {
  local select=$(history | fzf)
  if [[ -n "$select" ]]; then
    BUFFER="$select"
    zle accept-line
  fi
}

zle -N ghq_repository_search

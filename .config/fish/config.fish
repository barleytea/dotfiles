eval (hub alias -s)

function fish_user_key_bindings
  bind \cr 'peco_select_history (commandline -b)'
  bind \cx\ck peco_kill
  bind \c] 'stty sane; peco_select_ghq_repository'
  bind \cx\cr peco_recentd
end

# alias

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

# commandline
set fish_color_normal         brwhite
set fish_color_autosuggestion brblack
set fish_color_cancel         brcyan
set fish_color_command        brgreen
set fish_color_comment        brblack
set fish_color_cwd            brred
set fish_color_end            brwhite
set fish_color_error          brred
set fish_color_escape         brcyan
set fish_color_host           brpurple
set fish_color_host_remote    bryellow
set fish_color_match          brcyan --underline
set fish_color_operator       brpurple
set fish_color_param          brred
set fish_color_quote          brgreen
set fish_color_redirection    brcyan
set fish_color_search_match   --background=brblack
set fish_color_selection      --background=brblack
set fish_color_user           brblue

# pager
set fish_pager_color_progress              brblack --italics
set fish_pager_color_secondary_background  # null
set fish_pager_color_secondary_completion  brblack
set fish_pager_color_secondary_description brblack
set fish_pager_color_secondary_prefix      brblack
set fish_pager_color_selected_background   --background=brblack
set fish_pager_color_selected_completion   bryellow
set fish_pager_color_selected_description  bryellow
set fish_pager_color_selected_prefix       bryellow

# path

set -U fish_user_paths $fish_user_paths $HOME/.cargo/bin
set -U fish_user_paths $fish_user_paths $HOME/flutter/bin

starship init fish | source

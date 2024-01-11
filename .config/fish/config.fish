eval (hub alias -s)

if not functions -q fisher
  curl -sL https://git.io/fisher | source && fisher install jorgebucaran/fisher
end

function fish_user_key_bindings
  bind \cr 'peco_select_history (commandline -b)'
  bind \cx\ck peco_kill
  bind \c] 'stty sane; peco_select_ghq_repository'
  bind \cx\cr peco_recentd
end

function mkcd
  mkdir -p $argv[1]; cd $argv[1]
end

# alias

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

starship init fish | source

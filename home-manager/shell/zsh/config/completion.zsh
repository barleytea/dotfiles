# Load completion system
autoload -Uz compinit

# Completion styles
zstyle ':completion:*' matcher-list '' 'm:{a-z}={A-Z} r:|[-_.]=**' '+m:{A-Z}={a-z} r:|[-_.]=**'

# Completion options
setopt hist_expand
setopt list_types
setopt auto_list
setopt auto_menu
setopt list_packed
setopt auto_param_keys
setopt auto_param_slash
setopt mark_dirs
setopt nolistbeep

# Initialize completion
if [ ! -d "${XDG_CACHE_HOME}/zsh" ]; then
  mkdir -p "${XDG_CACHE_HOME}/zsh"
fi
compinit -d "${XDG_CACHE_HOME}/zsh/zcompdump-${ZSH_VERSION}"

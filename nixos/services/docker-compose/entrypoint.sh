#!/bin/sh
# Entrypoint script for Kali Docker container
# This script ensures zsh configuration is properly initialized

set -e

# Create necessary directories
mkdir -p /root/.local/state/zsh
mkdir -p /root/.cache

# Source the mounted zshenv if it exists to get XDG and ZDOTDIR
if [ -f /root/.zshenv ]; then
  . /root/.zshenv
fi

# Create a basic .zshrc in ZDOTDIR if host's symlink doesn't work
if [ -d "$ZDOTDIR" ] && [ ! -f "$ZDOTDIR/.zshrc" ]; then
  cat > "$ZDOTDIR/.zshrc" << 'EOF'
# Basic Zsh configuration for Kali Docker container
# This is a fallback when host symlinks are not available

# Enable completion
autoload -Uz compinit
compinit -d /root/.zcompdump

# Basic options
setopt hist_save_no_dups hist_find_no_dups inc_append_history share_history
export HISTSIZE=10000 SAVEHIST=10000
export HISTFILE="$ZDOTDIR/.zsh_history"

# Basic prompt
PROMPT='%F{green}[kali]%f %F{blue}%~%f %# '

# Aliases
alias ls='ls --color=auto'
alias ll='ls -la'
alias la='ls -A'

# Basic PATH setup for Nix tools
if [ -d /nix/store ]; then
  # Add commonly used nix tools to PATH
  export PATH="/run/current-system/sw/bin:$PATH"
  export PATH="/nix/var/nix/profiles/profile/bin:$PATH"
fi

EOF
fi

# Source mounted config if it exists (allows real config to override)
if [ -f "$ZDOTDIR/.zshrc" ]; then
  # Already have a config from mount or just created
  :
fi

# Initialize zsh completion directory if needed
zsh -c 'compinit -d /root/.zcompdump' 2>/dev/null || true

# Execute the main shell
exec /bin/zsh -l "$@"

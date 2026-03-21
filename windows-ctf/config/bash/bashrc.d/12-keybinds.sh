#!/usr/bin/env bash
# Key bindings (equivalent to keybinds.zsh, using bind -x)

# Ctrl+G: ghq repository search
bind -x '"\C-g": ghq_repository_search' 2>/dev/null

# Ctrl+W: worktree search
bind -x '"\C-w": worktree_search' 2>/dev/null

# Enable vi mode (equivalent to bindkey -v)
# Note: uncomment the line below to enable vi mode in readline
# set -o vi

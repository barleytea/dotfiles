#!/usr/bin/env bash
# Key bindings (equivalent to keybinds.zsh, using bind -x)

# Ctrl+G: ghq repository search
# 二段構成: \C-x\C-g で bind -x 呼び出し → READLINE_LINEにcdを注入 → \C-mで自動実行
bind -x '"\C-x\C-g": ghq_repository_search' 2>/dev/null
bind '"\C-g": "\C-x\C-g\C-m"' 2>/dev/null

# Ctrl+W: worktree search
bind -x '"\C-x\C-w": worktree_search' 2>/dev/null
bind '"\C-w": "\C-x\C-w\C-m"' 2>/dev/null

# Enable vi mode (equivalent to bindkey -v)
# Note: uncomment the line below to enable vi mode in readline
# set -o vi

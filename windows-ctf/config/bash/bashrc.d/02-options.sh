#!/usr/bin/env bash
# Shell options (equivalent to options.zsh)

# Auto-cd without 'cd' command
shopt -s autocd 2>/dev/null

# Case-insensitive globbing
shopt -s nocaseglob 2>/dev/null

# Append to history instead of overwriting
shopt -s histappend 2>/dev/null

# Check window size after each command
shopt -s checkwinsize 2>/dev/null

# No beep
bind 'set bell-style none' 2>/dev/null

# History settings (equivalent to setopt share_history, hist_ignore_all_dups)
export HISTSIZE=100000
export HISTFILESIZE=100000
export HISTCONTROL=ignoredups:erasedups

# Share history across sessions (equivalent to setopt share_history)
export PROMPT_COMMAND="${PROMPT_COMMAND:+${PROMPT_COMMAND}; }history -a"

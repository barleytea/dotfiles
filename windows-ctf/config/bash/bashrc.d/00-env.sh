#!/usr/bin/env bash
# Environment variables (equivalent to env.zsh)

# XDG Base Directory
export XDG_CONFIG_HOME="${HOME}/.config"
export XDG_DATA_HOME="${HOME}/.local/share"
export XDG_STATE_HOME="${HOME}/.local/state"
export XDG_CACHE_HOME="${HOME}/.cache"

# Fallback when remote hosts lack Ghostty's terminfo.
if [ "$TERM" = "xterm-ghostty" ]; then
  if command -v infocmp >/dev/null 2>&1; then
    infocmp -x xterm-ghostty >/dev/null 2>&1 || export TERM=xterm-256color
  else
    export TERM=xterm-256color
  fi
fi

# User
export USER=$(whoami)

# History
export HISTFILE="${XDG_STATE_HOME}/bash/bash_history"

# Less
export LESSHISTFILE="${XDG_STATE_HOME}/less/history"

# git
export GIT_EDITOR=vim
export VISUAL=vim
export EDITOR=vim

# Go
export GOPATH="${XDG_DATA_HOME}/go"

# Rust
export RUSTUP_HOME="${XDG_DATA_HOME}/rustup"
export CARGO_HOME="${XDG_DATA_HOME}/cargo"

# Docker
export DOCKER_CONFIG="${XDG_CONFIG_HOME}/docker"

# mise
export MISE_USE_TOML=1
export MISE_EXPERIMENTAL=1
export MISE_DATA_DIR="${XDG_DATA_HOME}/mise"
export MISE_CONFIG_DIR="${XDG_CONFIG_HOME}/mise"
export MISE_CACHE_DIR="${XDG_CACHE_HOME}/mise"

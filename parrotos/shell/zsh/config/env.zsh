# XDG Base Directory

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
export HISTFILE="$XDG_STATE_HOME"/zsh/zsh-history

# Less
export LESSHISTFILE="$XDG_STATE_HOME"/less/history

# git
export GIT_EDITOR=vim
export VISUAL=vim
export EDITOR=vim

# Docker
export DOCKER_CONFIG="$XDG_CONFIG_HOME"/docker

# Go
export GOPATH="$XDG_DATA_HOME"/go

# Rust
export RUSTUP_HOME="$XDG_DATA_HOME"/rustup
export CARGO_HOME="$XDG_DATA_HOME"/cargo

# Haskell
export STACK_ROOT="$XDG_DATA_HOME"/stack

# claude
export ANTHROPIC_MODEL='opusplan'

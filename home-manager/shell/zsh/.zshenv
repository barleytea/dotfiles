# XDG Base Directory
export XDG_CONFIG_HOME=$HOME/.config
export XDG_CACHE_HOME=$HOME/.cache
export XDG_DATA_HOME=$HOME/.local/share
export XDG_STATE_HOME=$HOME/.local/state
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"

# Path
export PATH="$XDG_STATE_HOME/nix/profiles/profile/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
export PATH="$HOME/go/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"

# Go
export GOPATH="$XDG_DATA_HOME"/go

# Rust
export RUSTUP_HOME=$XDG_DATA_HOME/rustup
export CARGO_HOME=$XDG_DATA_HOME/cargo

# History
export HISTFILE="$XDG_STATE_HOME"/zsh/zsh-history

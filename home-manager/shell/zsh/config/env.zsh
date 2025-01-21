# XDG Base Directory

# User
export USER=$(whoami)
export DARWIN_USER=$(whoami)

# Nix
if [ -d "$XDG_STATE_HOME/nix/defexpr/channels" ]; then
  export NIX_PATH=$XDG_STATE_HOME/nix/defexpr/channels${NIX_PATH:+:$NIX_PATH}
fi

if [ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi
export NIX_CONF_DIR=$XDG_CONFIG_HOME

# asdf
export ASDF_DATA_DIR="$XDG_DATA_HOME"/asdf

# Go
export GOPATH="$XDG_DATA_HOME"/go

# Rust
export RUSTUP_HOME="$XDG_DATA_HOME"/rustup
export CARGO_HOME="$XDG_DATA_HOME"/cargo

# History
export HISTFILE="$XDG_STATE_HOME"/zsh/zsh-history

# Less
export LESSHISTFILE="$XDG_STATE_HOME"/less/history

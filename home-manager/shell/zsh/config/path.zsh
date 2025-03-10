# Homebrew
if [ "$(uname)" = "Linux" ]; then
  export PATH="/home/linuxbrew/.linuxbrew/bin:$PATH"
elif [ "$(uname)" = "Darwin" ]; then
  export PATH="/opt/homebrew/bin:$PATH"
fi

# Nix
export PATH="$XDG_STATE_HOME/nix/profiles/profile/bin:$PATH"

# cargo
export PATH="$HOME/.cargo/bin:$PATH"

# go
export PATH="$HOME/go/bin:$PATH"
export PATH="$HOME/.local/share/go/bin:$PATH"

# local
export PATH="$HOME/.local/bin:$PATH"

# asdf
export PATH="$HOME/.asdf/bin:$PATH"

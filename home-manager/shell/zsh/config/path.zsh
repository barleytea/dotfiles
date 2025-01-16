# Homebrew
if [ "$(uname)" = "Linux" ]; then
  export PATH="/home/linuxbrew/.linuxbrew/bin:$PATH"
elif [ "$(uname)" = "Darwin" ]; then
  export PATH="/opt/homebrew/bin:$PATH"
fi

# asdf
export PATH="$HOME/.asdf/bin:$PATH"

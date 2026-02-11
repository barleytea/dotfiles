if [[ $TERM != "dumb" && -x "$(command -v starship)" ]]; then
  eval "$(starship init zsh)"
fi

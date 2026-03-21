#!/usr/bin/env bash
# Starship prompt (equivalent to starship.zsh)

if [[ "$TERM" != "dumb" ]] && command -v starship >/dev/null 2>&1; then
  eval "$(starship init bash)"
fi

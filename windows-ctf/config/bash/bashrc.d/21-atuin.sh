#!/usr/bin/env bash
# Atuin shell history (equivalent to atuin.zsh)

if command -v atuin >/dev/null 2>&1; then
  eval "$(atuin init bash --disable-up-arrow)"
fi

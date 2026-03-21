#!/usr/bin/env bash
# Zoxide smart cd (equivalent to zoxide.zsh)

if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init bash)"
fi

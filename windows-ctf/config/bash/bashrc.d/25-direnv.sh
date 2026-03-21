#!/usr/bin/env bash
# direnv (equivalent to direnv.zsh)

if command -v direnv >/dev/null 2>&1; then
  eval "$(direnv hook bash)"
fi

#!/usr/bin/env bash
# mise runtime manager (equivalent to mise.zsh)

if [[ $- == *i* ]] && command -v mise >/dev/null 2>&1; then
  eval "$(mise activate bash)"
fi

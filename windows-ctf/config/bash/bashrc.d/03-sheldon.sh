#!/usr/bin/env bash
# Load Bash plugins managed by Sheldon before the other shell integrations.

[[ $- == *i* ]] || return 0

if command -v sheldon >/dev/null 2>&1; then
  eval "$(sheldon source)"
fi

#!/usr/bin/env bash
# SSH agent auto-start

if [[ -z "$SSH_AUTH_SOCK" ]] || [[ ! -S "$SSH_AUTH_SOCK" ]]; then
  eval "$(ssh-agent -s)" > /dev/null
  ssh-add "$HOME/.ssh/id_ed25519" 2>/dev/null || true
fi

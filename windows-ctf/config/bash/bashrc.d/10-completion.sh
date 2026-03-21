#!/usr/bin/env bash
# bash-completion setup (equivalent to sheldon plugins + completion.zsh)

# Load system bash-completion
if [[ -f /usr/share/bash-completion/bash_completion ]]; then
  source /usr/share/bash-completion/bash_completion
elif [[ -f /etc/bash_completion ]]; then
  source /etc/bash_completion
fi

# Ensure completion cache dir exists
mkdir -p "${XDG_CACHE_HOME:-${HOME}/.cache}/bash"

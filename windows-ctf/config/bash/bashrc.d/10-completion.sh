#!/usr/bin/env bash
# bash-completion setup (equivalent to sheldon plugins + completion.zsh)

# Load the system completion definitions once. Using a default completion
# function for lazy loading suppresses Bash's built-in filename completion and
# does not retry the first completion after bash-completion has been loaded.
if ! type _init_completion &>/dev/null; then
  if [[ -r /usr/share/bash-completion/bash_completion ]]; then
    source /usr/share/bash-completion/bash_completion
  elif [[ -r /etc/bash_completion ]]; then
    source /etc/bash_completion
  fi
fi

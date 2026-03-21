#!/usr/bin/env bash
# fzf key bindings and completion

# Load fzf bash integration
if [[ -f /usr/share/doc/fzf/examples/key-bindings.bash ]]; then
  source /usr/share/doc/fzf/examples/key-bindings.bash
elif [[ -f /usr/share/fzf/key-bindings.bash ]]; then
  source /usr/share/fzf/key-bindings.bash
fi

if [[ -f /usr/share/doc/fzf/examples/completion.bash ]]; then
  source /usr/share/doc/fzf/examples/completion.bash
elif [[ -f /usr/share/fzf/completion.bash ]]; then
  source /usr/share/fzf/completion.bash
fi

# fzf default options
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'

# Use fd if available for fzf file search
if command -v fd >/dev/null 2>&1; then
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi

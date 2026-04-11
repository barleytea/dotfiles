#!/usr/bin/env bash
# bash-completion setup (equivalent to sheldon plugins + completion.zsh)

# Ensure completion cache dir exists
mkdir -p "${XDG_CACHE_HOME:-${HOME}/.cache}/bash"

# 遅延ロード: 初回 Tab キー時にのみ bash-completion を読み込む
_load_bash_completion() {
  if [[ -f /usr/share/bash-completion/bash_completion ]]; then
    source /usr/share/bash-completion/bash_completion
  elif [[ -f /etc/bash_completion ]]; then
    source /etc/bash_completion
  fi
  # 自身を解除
  complete -r _load_bash_completion 2>/dev/null || true
}

# まだロードされていない場合のみフックをセット
if ! type _init_completion &>/dev/null; then
  complete -D -F _load_bash_completion
fi

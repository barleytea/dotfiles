#!/usr/bin/env bash
# Starship prompt (equivalent to starship.zsh)

_is_wsl() {
  [[ -r /proc/sys/kernel/osrelease ]] &&
    grep -qi "microsoft" /proc/sys/kernel/osrelease
}

if [[ "$TERM" == "dumb" ]]; then
  return 0
fi

if _is_wsl; then
  # WSL では starship が毎プロンプトで外部プロセスを起動し、
  # Git / ランタイム検出と組み合わさると体感遅延が出やすい。
  # Bash ネイティブの静的な prompt に切り替えて待ち時間をなくす。
  PS1='\[\e[1;32m\]┌───────────────────\n│\[\e[0m\]\w \[\e[2m\]\A\[\e[0m\]\n\[\e[1;32m\]└─>\[\e[0m\] '
elif command -v starship >/dev/null 2>&1; then
  eval "$(starship init bash)"
fi

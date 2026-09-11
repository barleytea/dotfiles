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
  # ただし git ブランチ名だけは軽量なので \$(...) 展開で表示する。
  _git_branch_ps1() {
    local branch
    branch=$(git symbolic-ref --short HEAD 2>/dev/null) ||
      branch=$(git rev-parse --short HEAD 2>/dev/null)
    [[ -n "$branch" ]] && printf ' \e[1;35m(%s)\e[0m' "$branch"
  }
  PS1='\[\e[1;32m\]┌───────────────────\n│\[\e[0m\]\w$(_git_branch_ps1) \[\e[2m\]\A\[\e[0m\]\n\[\e[1;32m\]└─>\[\e[0m\] '
elif command -v starship >/dev/null 2>&1; then
  eval "$(starship init bash)"
fi

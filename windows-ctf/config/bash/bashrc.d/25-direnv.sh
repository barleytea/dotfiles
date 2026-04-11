#!/usr/bin/env bash
# direnv (equivalent to direnv.zsh)

if command -v direnv >/dev/null 2>&1; then
  _is_wsl() {
    [[ -r /proc/sys/kernel/osrelease ]] &&
      grep -qi "microsoft" /proc/sys/kernel/osrelease
  }

  # WSL の Bash で標準の direnv hook を使うと、毎プロンプトごとに
  # `direnv export bash` が実行されて待ち時間が目立つ。
  # `.envrc` のあるディレクトリに入った時、出た時、または `.envrc`
  # が更新された時だけ direnv を実行して負荷を抑える。
  _direnv_find_envrc() {
    local dir="${PWD}"

    while true; do
      if [[ -f "${dir}/.envrc" ]]; then
        printf '%s\n' "${dir}/.envrc"
        return 0
      fi

      [[ "${dir}" == "/" ]] && return 1
      dir="${dir%/*}"
      [[ -z "${dir}" ]] && dir="/"
    done
  }

  __DIRENV_WSL_LAST_PWD=""
  __DIRENV_WSL_LAST_ENVRC=""
  __DIRENV_WSL_LAST_ENVRC_MTIME="0"

  _direnv_prompt_hook_wsl() {
    local envrc=""
    local envrc_mtime="0"

    if [[ "${PWD}" == "${__DIRENV_WSL_LAST_PWD}" ]] &&
       [[ -z "${__DIRENV_WSL_LAST_ENVRC}" ]]; then
      return 0
    fi

    envrc="$(_direnv_find_envrc 2>/dev/null || true)"

    if [[ -n "${envrc}" ]]; then
      envrc_mtime="$(stat -c '%Y' "${envrc}" 2>/dev/null || printf '0')"
    fi

    if [[ "${PWD}" == "${__DIRENV_WSL_LAST_PWD}" ]] &&
       [[ "${envrc}" == "${__DIRENV_WSL_LAST_ENVRC}" ]] &&
       [[ "${envrc_mtime}" == "${__DIRENV_WSL_LAST_ENVRC_MTIME}" ]]; then
      return 0
    fi

    __DIRENV_WSL_LAST_PWD="${PWD}"
    __DIRENV_WSL_LAST_ENVRC="${envrc}"
    __DIRENV_WSL_LAST_ENVRC_MTIME="${envrc_mtime}"

    eval "$(direnv export bash)"
  }

  if _is_wsl; then
    PROMPT_COMMAND="${PROMPT_COMMAND:+${PROMPT_COMMAND}; }_direnv_prompt_hook_wsl"
  else
    eval "$(direnv hook bash)"
  fi
fi

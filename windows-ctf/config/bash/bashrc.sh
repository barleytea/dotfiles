#!/usr/bin/env bash
# Main bash config entry point
# Source all files in bashrc.d/ in order

BASH_CONFIG_DIR="${HOME}/.config/bash/bashrc.d"

if [[ -d "${BASH_CONFIG_DIR}" ]]; then
  for _f in "${BASH_CONFIG_DIR}"/*.sh; do
    [[ -f "$_f" ]] && source "$_f"
  done
  unset _f
fi

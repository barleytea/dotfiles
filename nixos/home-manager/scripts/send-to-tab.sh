#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <tab_name> <command...>"
  exit 1
fi

tab_name="$1"
shift
text="$*"

current_index=""
current_line=$(zellij action query-tab-names 2>/dev/null | grep -F "(current)" | head -n 1 || true)
if [[ -n "$current_line" ]]; then
  current_index=$(echo "$current_line" | sed -E 's/^[^0-9]*([0-9]+).*/\1/; t; d')
fi

zellij action go-to-tab-name "$tab_name"
zellij action write-chars "$text"
zellij action write 13

if [[ -n "$current_index" ]]; then
  zellij action go-to-tab "$current_index"
fi

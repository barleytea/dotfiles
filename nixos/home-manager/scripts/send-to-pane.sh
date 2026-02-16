#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <pane_id> <command...>"
  exit 1
fi

pane_id="$1"
shift
text="$*"

if ! [[ "$pane_id" =~ ^[0-9]+$ ]]; then
  echo "pane_id must be numeric"
  exit 1
fi

payload=$(jq -nc --argjson pane_id "$pane_id" --arg text "$text" '{"pane_id":$pane_id,"text":$text,"send_enter":true}')

zellij action pipe \
  --plugin "https://github.com/atani/zellij-send-keys/releases/latest/download/zellij-send-keys.wasm" \
  --name send_keys \
  -- "$payload"

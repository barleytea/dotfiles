#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 2 ]]; then
  printf 'usage: %s <hooks.json> <addition.json>\n' "$0" >&2
  exit 2
fi

target=$1
addition=$2
if [[ -L "$target" ]]; then
  printf 'refusing to replace a symlink: %s\n' "$target" >&2
  exit 1
fi
command=$(jq -er '.hooks.PreToolUse[0].hooks[0].command' "$addition")
directory=$(dirname "$target")
mkdir -p "$directory"
temporary=$(mktemp "$target.tmp.XXXXXX")
trap 'rm -f "$temporary"' EXIT

filter='
  def strip_owned($command):
    if (.hooks | type) != "object" or (.hooks.PreToolUse | type) != "array" then .
    else
      .hooks.PreToolUse = [
        .hooks.PreToolUse[]
        | if (.hooks | type) == "array" then
            .hooks = [.hooks[] | select(.command != $command)]
            | select((.hooks | length) > 0)
          else . end
      ]
    end;
  (if type == "object" then . else {} end)
  | strip_owned($command)
  | .hooks = (.hooks // {})
  | .hooks.PreToolUse = ((.hooks.PreToolUse // []) + $addition[0].hooks.PreToolUse)
'

if [[ -f "$target" ]]; then
  jq --arg command "$command" --slurpfile addition "$addition" "$filter" "$target" > "$temporary"
else
  jq --null-input --arg command "$command" --slurpfile addition "$addition" "$filter" > "$temporary"
fi

chmod 600 "$temporary"
mv -f "$temporary" "$target"

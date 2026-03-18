#!/bin/bash
# Claude Code Stop hook: cmux が動いている場合のみ difit-cmux を起動

CMUX="/Applications/cmux.app/Contents/Resources/bin/cmux"
DIFIT_PORT="${DIFIT_PORT:-4966}"

[[ ! -x "$CMUX" ]] && exit 0
command -v jq &>/dev/null || exit 0

HOOK_CWD=$(cat - | jq -r '.cwd // empty')
[[ -z "$HOOK_CWD" ]] && exit 0

git -C "$HOOK_CWD" rev-parse --git-dir &>/dev/null 2>&1 || exit 0

# コード変更がない場合はスキップ
git -C "$HOOK_CWD" diff --quiet HEAD 2>/dev/null && exit 0

pgrep -x "cmux" &>/dev/null 2>&1 || exit 0

# difit が既に動作中ならスキップ
lsof -ti:"$DIFIT_PORT" &>/dev/null 2>&1 && exit 0

exec "${HOME}/.local/bin/difit-cmux" &>/dev/null

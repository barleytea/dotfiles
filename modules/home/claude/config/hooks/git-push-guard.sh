#!/usr/bin/env bash
# git push を実行する前に危険なパターンをブロックする PreToolUse hook。
# settings.json 側で matcher: "Bash", if: "Bash(git push:*)" によって
# git push 系のコマンドのときだけ呼ばれる。
set -euo pipefail

input=$(cat)
command=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')

# if フィルタでほぼ絞られているはずだが念のため素通りさせる
if [[ "$command" != *"git push"* ]]; then
  echo '{}'
  exit 0
fi

deny() {
  local reason="$1"
  jq -n --arg reason "$reason" \
    '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $reason}}'
  exit 0
}

# force push 系（--force / --force-with-lease / --force-if-includes / -f）は常に拒否
if printf '%s' "$command" | grep -Eq -- '(--force(-with-lease|-if-includes)?\b|(^|[[:space:]])-f([[:space:]]|$))'; then
  deny "force push はブロックされています（--force/-f/--force-with-lease 等）。必要な場合はユーザー自身が実行してください。"
fi

# push 先に main/master を明示指定している場合
if printf '%s' "$command" | grep -Eq '(^|[[:space:]])(main|master)([[:space:]]|:|$)'; then
  deny "main/master への直接 push はブロックされています。ブランチを切って PR 経由にしてください。"
fi

# 明示指定がなくても、現在のブランチが main/master ならブロック
current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
if [[ "$current_branch" == "main" || "$current_branch" == "master" ]]; then
  deny "現在 ${current_branch} ブランチにいます。main/master への直接 push はブロックされています。ブランチを切ってください。"
fi

echo '{}'

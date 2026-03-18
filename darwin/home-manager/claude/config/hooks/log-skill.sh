#!/bin/bash
# PreToolUse hook: Skill ツールの利用をログに記録
# stdin: { tool_name, tool_input: { skill, args }, session_id, ... }

payload=$(cat)

skill=$(jq -r '.tool_input.skill' <<< "$payload")
args=$(jq -r '.tool_input.args // ""' <<< "$payload")

echo "$(date -u +%s) $USER $skill $args" >> ~/.claude/skill-usage.log

#!/bin/bash
# Stop hook: セッション終了時にセッション情報をファイルに保存
# stdin: Stop hook の JSON payload (transcript_path 等を含む)

SESSION_DIR="$HOME/.claude/session-logs"
mkdir -p "$SESSION_DIR"

TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
LOGFILE="$SESSION_DIR/$TIMESTAMP.json"

cat - > "$LOGFILE"

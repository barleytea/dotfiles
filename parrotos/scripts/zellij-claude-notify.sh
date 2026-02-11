#!/usr/bin/env bash
# Zellij Claude Code notification script
# Sends visual and audible notifications when Claude Code needs attention

set -euo pipefail

NOTIFICATION_TYPE="${1:-default}"
ICON=""
MESSAGE="Claude"

case "$NOTIFICATION_TYPE" in
  permission)
    ICON="🔔"
    MESSAGE="Permission Required"
    ;;
  completed)
    ICON="✅"
    MESSAGE="Task Completed"
    ;;
  idle)
    ICON="⏸️"
    MESSAGE="Waiting..."
    ;;
  error)
    ICON="❌"
    MESSAGE="Error Occurred"
    ;;
  *)
    ICON="💬"
    MESSAGE="Attention"
    ;;
esac

# Zellijタブ名の先頭に通知マークを追加（Zellij内で実行されている場合のみ）
if command -v zellij &> /dev/null && [ -n "${ZELLIJ:-}" ]; then
  # 現在のタブのインデックスを取得（ZELLIJ_TAB_INDEXは0始まり、sedは1始まり）
  TAB_LINE=$((ZELLIJ_TAB_INDEX + 1))

  # query-tab-namesの出力から、現在のタブのインデックスに対応する行を取得
  CURRENT_TAB_NAME=$(zellij action query-tab-names 2>/dev/null | sed -n "${TAB_LINE}p" | sed 's/^🔔 //')

  # タブ名の先頭に🔔を追加
  zellij action rename-tab "🔔 ${CURRENT_TAB_NAME}"

  # マーカーファイルを作成（元のタブ名を記録 - 🔔なし）
  MARKER_FILE="/tmp/zellij-notify-${ZELLIJ_SESSION_NAME}-${ZELLIJ_PANE_ID}"
  echo "${CURRENT_TAB_NAME}" > "${MARKER_FILE}"
fi

# Bell送信（ターミナル通知）
printf '\a'

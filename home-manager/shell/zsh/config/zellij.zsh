if [[ -z "$ZELLIJ" ]]; then
  active_sessions=$(zellij list-sessions 2>/dev/null | grep -v "EXITED" | wc -l)

  if [[ $active_sessions -gt 0 ]]; then
    exec zellij attach -c
  else
    exec zellij
  fi
fi

# Claude Code通知マーカーをクリアする（precmd hook）
function zellij_clear_notification_marker() {
  if [[ -n "${ZELLIJ:-}" ]] && [[ -n "${ZELLIJ_PANE_ID:-}" ]]; then
    # 現在のペインのマーカーファイルをチェック
    local marker_file="/tmp/zellij-notify-${ZELLIJ_SESSION_NAME}-${ZELLIJ_PANE_ID}"

    if [[ -f "${marker_file}" ]]; then
      # マーカーファイルから元のタブ名を取得
      local original_tab_name=$(cat "${marker_file}" 2>/dev/null)

      # 元のタブ名に戻す（🔔を削除）
      if [[ -n "${original_tab_name}" ]]; then
        zellij action rename-tab "${original_tab_name}" 2>/dev/null || true
      fi

      rm -f "${marker_file}"
    fi
  fi
}

# precmdフックに追加（プロンプト表示前に実行される）
autoload -Uz add-zsh-hook
add-zsh-hook precmd zellij_clear_notification_marker

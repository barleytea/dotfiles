alias zw='zellij --layout webdev'

# Alacrittyの場合のみZellijを自動起動
# CI環境、Zellij内、またはAlacritty以外のターミナルでは起動しない
if [[ -z "$ZELLIJ" ]] && [[ -z "$CI" ]] && [[ "$TERM_PROGRAM" == "alacritty" ]]; then
  active_sessions=$(zellij list-sessions 2>/dev/null | grep -v "EXITED" | wc -l)

  if [[ $active_sessions -gt 0 ]]; then
    exec zellij attach -c
  else
    exec zellij
  fi
fi

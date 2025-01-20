if [[ -z "$ZELLIJ" ]]; then
  active_sessions=$(zellij list-sessions 2>/dev/null | grep -v "EXITED" | wc -l)
  
  if [[ $active_sessions -gt 0 ]]; then
    exec zellij attach -c
  else
    exec zellij
  fi
fi

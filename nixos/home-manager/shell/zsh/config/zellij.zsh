_zellij_shorten_tab_name() {
  local name="$1"
  [[ -z "$name" ]] && name="tab"
  if (( ${#name} > 16 )); then
    name="${name[1,16]}"
  fi
  print -r -- "$name"
}

_zellij_existing_tab_names() {
  zellij action query-tab-names 2>/dev/null | sed -E 's/^[[:space:]]*[0-9]+[[:space:]]+//; s/[[:space:]]+\(current\)$//; s/^"//; s/"$//' || true
}

_zellij_unique_tab_name() {
  local base candidate suffix candidate_base_len index existing_names
  base="$(_zellij_shorten_tab_name "$1")"
  existing_names="$(_zellij_existing_tab_names)"

  candidate="$base"
  if ! print -r -- "$existing_names" | grep -Fxq -- "$candidate"; then
    print -r -- "$candidate"
    return
  fi

  index=2
  while true; do
    suffix="#${index}"
    candidate_base_len=$((16 - ${#suffix}))
    (( candidate_base_len < 1 )) && candidate_base_len=1
    candidate="${base[1,candidate_base_len]}${suffix}"
    if ! print -r -- "$existing_names" | grep -Fxq -- "$candidate"; then
      print -r -- "$candidate"
      return
    fi
    ((index++))
  done
}

_zellij_confirm_replace() {
  local layout_name="${1:-tab}" answer
  echo -n "♻️  Replace current tab with new $layout_name tab? [y/N]: "
  read -r answer
  [[ "$answer" =~ ^[Yy]$ ]]
}

_zellij_replace_sentinel_name() {
  print -r -- "__zw-replace-${RANDOM}-${EPOCHSECONDS}"
}

zw() {
  local base_name tab_name should_replace=false sentinel_name=""

  if [[ -z "$ZELLIJ" ]]; then
    zellij --layout webdev
    return
  fi

  base_name="${PWD:t}"
  tab_name="$(_zellij_unique_tab_name "$base_name")"

  if _zellij_confirm_replace "webdev"; then
    should_replace=true
    sentinel_name="$(_zellij_replace_sentinel_name)"
    if ! zellij action rename-tab "$sentinel_name"; then
      echo "⚠️  Could not mark current tab. Replace skipped."
      should_replace=false
    fi
  fi

  zellij action new-tab --layout webdev --cwd "$PWD" --name "$tab_name"

  if [[ "$should_replace" == "true" ]]; then
    if zellij action go-to-tab-name "$sentinel_name"; then
      zellij action close-tab
    else
      echo "⚠️  Failed to focus marked tab (${sentinel_name}). Replace skipped."
    fi
  fi
}

zi() {
  local base_name tab_name should_replace=false sentinel_name=""

  if [[ -z "$ZELLIJ" ]]; then
    zellij --layout investigate
    return
  fi

  base_name="investigate_${PWD:t}"
  tab_name="$(_zellij_unique_tab_name "$base_name")"

  if _zellij_confirm_replace "investigate"; then
    should_replace=true
    sentinel_name="$(_zellij_replace_sentinel_name)"
    if ! zellij action rename-tab "$sentinel_name"; then
      echo "⚠️  Could not mark current tab. Replace skipped."
      should_replace=false
    fi
  fi

  zellij action new-tab --layout investigate --cwd "$PWD" --name "$tab_name"

  if [[ "$should_replace" == "true" ]]; then
    if zellij action go-to-tab-name "$sentinel_name"; then
      zellij action close-tab
    else
      echo "⚠️  Failed to focus marked tab (${sentinel_name}). Replace skipped."
    fi
  fi
}

# Alacrittyの場合のみZellijを自動起動
# Zellij内、またはAlacritty以外のターミナルでは起動しない
if [[ -z "$ZELLIJ" ]] && ( [[ "$TERM_PROGRAM" == "alacritty" ]] || [[ -n "$ALACRITTY_SOCKET" ]] ); then
  active_sessions=$(zellij list-sessions 2>/dev/null | grep -v "EXITED" | wc -l)

  if [[ $active_sessions -gt 0 ]]; then
    exec zellij attach -c
  else
    exec zellij
  fi
fi

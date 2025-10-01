#!/usr/bin/env bash
# home-manager-diff-activation.sh
# 旧来の activationPackage ベースの差分確認 (閉包は generation より狭い)
# SHOW_ALL=1 で全パス表示 / QUIET=1 で静音化
set -uo pipefail  # set -e を外して非致命エラーでの停止を防止

info() { [ "${QUIET:-0}" = 1 ] && return 0; printf '%s\n' "$*"; }
step() { [ "${QUIET:-0}" = 1 ] && return 0; printf '[%s] %s\n' "$1" "$2"; }
err() { printf 'ERROR: %s\n' "$*" >&2; }

TMPDIR="$(mktemp -d)"; trap 'rm -rf "$TMPDIR"' EXIT INT TERM

step 1 "build activation package"
NEW_PATH=$(nix build .#homeConfigurations.home.activationPackage --no-link --print-out-paths --impure | tail -n1 | tr -d ' ')
[ -n "$NEW_PATH" ] && [ -e "$NEW_PATH" ] || { err "failed to obtain activation package path"; exit 1; }
info "NEW_PATH=$NEW_PATH"

step 2 "detect current profile path"
CUR_PATH=$(readlink -f "$HOME/.local/state/nix/profiles/home-manager" 2>/dev/null || true)
if [ -z "$CUR_PATH" ]; then CUR_PATH=$(home-manager path 2>/dev/null || true); fi
if [ -z "$CUR_PATH" ]; then CUR_PATH=$(readlink -f "$HOME/.nix-profile" 2>/dev/null || true); fi
if [ -z "$CUR_PATH" ]; then CUR_PATH=$(nix profile list 2>/dev/null | awk '/home-manager/ {print $4; exit}' | xargs -r readlink -f 2>/dev/null || true); fi
info "CUR_PATH=${CUR_PATH:-'(not found)'}"
if [ -z "$CUR_PATH" ]; then
  COUNT=$(nix path-info -r "$NEW_PATH" | wc -l | tr -d ' ')
  info "current profile not found; new closure size paths: $COUNT"
  exit 0
fi

step 3 "closure diff (approx)"
if ! nix store diff-closures "$CUR_PATH" "$NEW_PATH"; then info '(diff-closures non-zero exit ignored)'; fi

step 4 "added / removed (activation closure)"
nix path-info -r "$CUR_PATH" | sort > "$TMPDIR/cur.txt"
nix path-info -r "$NEW_PATH" | sort > "$TMPDIR/new.txt"
comm -13 "$TMPDIR/cur.txt" "$TMPDIR/new.txt" > "$TMPDIR/added.txt"
comm -23 "$TMPDIR/cur.txt" "$TMPDIR/new.txt" > "$TMPDIR/removed.txt"
ADDED_COUNT=$(grep -cv '^$' "$TMPDIR/added.txt" 2>/dev/null || true)
REM_COUNT=$(grep -cv '^$' "$TMPDIR/removed.txt" 2>/dev/null || true)
case "$ADDED_COUNT" in '' ) ADDED_COUNT=0 ;; esac
case "$REM_COUNT" in '' ) REM_COUNT=0 ;; esac
info "added: $ADDED_COUNT  removed: $REM_COUNT"

show_paths() {
  local file=$1 label=$2 count=$3
  [ "$count" -eq 0 ] && return 0
  echo "--- $label ---"
  if [ "${SHOW_ALL:-0}" = 1 ]; then
    cat "$file"
  else
    head -n 20 "$file"
    [ "$count" -gt 20 ] && echo '  ...'
  fi
}
show_paths "$TMPDIR/added.txt"   "added paths" "$ADDED_COUNT"
show_paths "$TMPDIR/removed.txt" "removed paths" "$REM_COUNT"

step 5 "activation script diff"
CUR_ACT=$(find "$CUR_PATH" -maxdepth 4 -type f -name activate 2>/dev/null | head -n1 || true)
NEW_ACT=$(find "$NEW_PATH" -maxdepth 4 -type f -name activate 2>/dev/null | head -n1 || true)
if [ -n "$CUR_ACT" ] && [ -n "$NEW_ACT" ]; then
  if cmp -s "$CUR_ACT" "$NEW_ACT"; then
    info "activation: no change"
  else
    diff -u "$CUR_ACT" "$NEW_ACT" || true
  fi
else
  info "activation script not found (skipped)"
fi

step done "complete"
exit 0

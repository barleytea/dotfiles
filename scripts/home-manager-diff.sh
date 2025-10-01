#!/usr/bin/env bash
# home-manager-diff.sh
# 現行 home-manager generation と 新しい generation の差分を多角的に表示するスクリプト
# - closure diff (nix store diff-closures)
# - added / removed derivations summary (top 20)
# - activation script diff (heuristic)
# 追加機能:
#   SHOW_ALL=1 環境変数を指定すると added/removed の全パスを表示
#   QUIET=1    で説明行を最小化
# 依存: nix, home-manager (flake), coreutils, diff, find, awk, comm, sort
set -uo pipefail  # 'set -e' は誤検出で途中終了するため外す

info() { [ "${QUIET:-0}" = 1 ] && return 0; printf '%s\n' "$*"; }
step() { [ "${QUIET:-0}" = 1 ] && return 0; printf '[%s] %s\n' "$1" "$2"; }
err() { printf 'ERROR: %s\n' "$*" >&2; }

TMPDIR="$(mktemp -d)"
cleanup() { rm -rf "$TMPDIR" || true; }
trap cleanup EXIT INT TERM

# --- Step 1: build new generation ---
step 1 "build new generation (home-manager build)"
# home-manager build は result -> generation シンボリックリンクを作る
if ! nix run nixpkgs#home-manager -- build --flake .#home --impure >/dev/null; then
  err "home-manager build failed"; exit 2
fi
NEW_GEN_PATH=$(readlink -f result || true)
[ -n "$NEW_GEN_PATH" ] || { err "failed to resolve new generation path"; exit 2; }
info "NEW_GEN_PATH=$NEW_GEN_PATH"

# --- Step 2: detect current generation ---
step 2 "detect current active generation"
CUR_GEN_PATH=$(readlink -f "$HOME/.local/state/nix/profiles/home-manager" 2>/dev/null || true)
if [ -z "$CUR_GEN_PATH" ]; then CUR_GEN_PATH=$(readlink -f "$HOME/.nix-profile" 2>/dev/null || true); fi
if [ -z "$CUR_GEN_PATH" ]; then
  info "no current generation -> only new closure size"
  COUNT=$(nix path-info -r "$NEW_GEN_PATH" | wc -l | tr -d ' ')
  info "new closure paths: $COUNT"
  exit 0
fi
info "CUR_GEN_PATH=$CUR_GEN_PATH"

if [ "$CUR_GEN_PATH" = "$NEW_GEN_PATH" ]; then
  info "new generation identical to current (paths same)"
  exit 0
fi

# --- Step 3: store closure diff ---
step 3 "store closure diff"
if ! nix store diff-closures "$CUR_GEN_PATH" "$NEW_GEN_PATH"; then
  info "(diff-closures non-zero exit ignored)"
fi

# --- Step 4: added / removed derivations ---
step 4 "collect added / removed derivations"
nix path-info -r "$CUR_GEN_PATH" | sort > "$TMPDIR/cur.txt"
nix path-info -r "$NEW_GEN_PATH" | sort > "$TMPDIR/new.txt"
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

# --- Step 5: activation script diff (heuristic) ---
step 5 "activation script textual diff"
CUR_ACT=$(find "$CUR_GEN_PATH" -maxdepth 5 -type f -name activate 2>/dev/null | head -n1 || true)
NEW_ACT=$(find "$NEW_GEN_PATH" -maxdepth 5 -type f -name activate 2>/dev/null | head -n1 || true)
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

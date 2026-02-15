#!/usr/bin/env bash
# Synchronize VSCode settings files from dotfiles to local user directory.

set -euo pipefail

OS=$(uname -s)
DOTFILES_DIR="$HOME/git_repos/github.com/barleytea/dotfiles"
VSCODE_SETTINGS_DIR="$DOTFILES_DIR/vscode/settings"

case "$OS" in
  Darwin)
    VSCODE_USER_DIR="$HOME/Library/Application Support/Code/User"
    ;;
  Linux)
    VSCODE_USER_DIR="$HOME/.config/Code/User"
    ;;
  *)
    echo "Unsupported OS: $OS"
    exit 1
    ;;
esac

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

backup_file() {
  if [ -f "$1" ]; then
    cp "$1" "$1.bak"
    log "Created backup: $1.bak"
  fi
}

check_and_create_dir() {
  if [ ! -d "$1" ]; then
    mkdir -p "$1"
    log "Created directory: $1"
  fi
}

sync_editor_settings() {
  local editor_dir=$1
  local editor_name=$2

  log "Starting $editor_name settings synchronization..."
  check_and_create_dir "$editor_dir"

  if [ -f "$VSCODE_SETTINGS_DIR/settings.json" ]; then
    if ! cmp -s "$VSCODE_SETTINGS_DIR/settings.json" "$editor_dir/settings.json"; then
      backup_file "$editor_dir/settings.json"
      cp "$VSCODE_SETTINGS_DIR/settings.json" "$editor_dir/settings.json"
      log "Updated $editor_name settings.json"
    else
      log "Skipped $editor_name settings.json (files are identical)"
    fi
  fi

  if [ -f "$VSCODE_SETTINGS_DIR/keybindings.json" ]; then
    if ! cmp -s "$VSCODE_SETTINGS_DIR/keybindings.json" "$editor_dir/keybindings.json"; then
      backup_file "$editor_dir/keybindings.json"
      cp "$VSCODE_SETTINGS_DIR/keybindings.json" "$editor_dir/keybindings.json"
      log "Updated $editor_name keybindings.json"
    else
      log "Skipped $editor_name keybindings.json (files are identical)"
    fi
  fi

  log "Completed $editor_name settings synchronization"
}

log "Starting VSCode settings synchronization..."
sync_editor_settings "$VSCODE_USER_DIR" "VSCode"
log "VSCode settings synchronization completed. Please restart VSCode to apply changes."

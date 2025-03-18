#!/bin/sh
CURRENT=$(cd $(dirname $0) && pwd)
VSCODE_SETTING_DIR=~/Library/Application\ Support/Code\ -\ Insiders/User
BACKUP_FILE="$CURRENT/backup_settings.json"

create_symlink() {
  rm -f "$VSCODE_SETTING_DIR/settings.json"
  ln -s "$CURRENT/settings.json" "$VSCODE_SETTING_DIR/settings.json"
  echo "settings: Symlink created"
}

create_symlink

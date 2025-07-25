#!/bin/sh
CURRENT=$(cd $(dirname $0) && pwd)
VSCODE_SETTING_DIR=~/Library/Application\ Support/Code/User
VSCODE_INSTRUCTIONS_CONFIG_DIR=~/.config/vscode/instructions
BACKUP_FILE="$CURRENT/backup_settings.json"
KEYBINDINGS_BACKUP_FILE="$CURRENT/backup_keybindings.json"

backup() {
  if [ -f "$VSCODE_SETTING_DIR/settings.json" ]; then
    cp "$VSCODE_SETTING_DIR/settings.json" "$BACKUP_FILE"
    echo "settings: Backup created"
  fi
  if [ -f "$VSCODE_SETTING_DIR/keybindings.json" ]; then
    cp "$VSCODE_SETTING_DIR/keybindings.json" "$KEYBINDINGS_BACKUP_FILE"
    echo "keybindings: Backup created"
  fi
}

create_symlink() {
  rm -f "$VSCODE_SETTING_DIR/settings.json"
  ln -s "$CURRENT/settings.json" "$VSCODE_SETTING_DIR/settings.json"
  echo "settings: Symlink created"

  rm -f "$VSCODE_SETTING_DIR/keybindings.json"
  ln -s "$CURRENT/keybindings.json" "$VSCODE_SETTING_DIR/keybindings.json"
  echo "keybindings: Symlink created"

  rm -f "$VSCODE_INSTRUCTIONS_CONFIG_DIR"/global.instructions.md
  mkdir -p "$VSCODE_INSTRUCTIONS_CONFIG_DIR"
  ln -s "$CURRENT/instructions/global.instructions.md" "$VSCODE_INSTRUCTIONS_CONFIG_DIR/global.instructions.md"
  echo "instructions: Symlink created"
}

backup && create_symlink

#!/bin/sh
# dotfiles内のextensionsを正として、localの拡張を上書きする

CURRENT=$(cd $(dirname $0) && pwd)

# OS検出とVSCode設定ディレクトリの決定（参照用）
OS=$(uname -s)
case "$OS" in
  Darwin)
    # macOS
    VSCODE_SETTING_DIR=~/Library/Application\ Support/Code/User
    ;;
  Linux)
    # Linux
    VSCODE_SETTING_DIR=~/.config/Code/User
    ;;
  *)
    echo "Unsupported OS: $OS"
    exit 1
    ;;
esac

# Backup current extensions list
code --list-extensions > "$CURRENT/backup_extensions"

# Install extensions from dotfiles that are not in local
comm -23 <(sort "$CURRENT/extensions") <(sort "$CURRENT/backup_extensions") | while read -r extension; do
  code --install-extension "$extension"
  echo "Installed $extension"
done

# Uninstall extensions that are in local but not in dotfiles
comm -13 <(sort "$CURRENT/extensions") <(sort "$CURRENT/backup_extensions") | while read -r extension; do
  code --uninstall-extension "$extension"
  echo "Uninstalled $extension"
done

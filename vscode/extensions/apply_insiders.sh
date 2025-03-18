#!/bin/sh
# dotfiles内のextensionsを正として、localの拡張を上書きする

CURRENT=$(cd $(dirname $0) && pwd)
VSCODE_SETTING_DIR=~/Library/Application\ Support/Code\ -\ Insiders/User

# Install extensions from dotfiles that are not in local
sort "$CURRENT/extensions" | while read -r extension; do
  code-insiders --install-extension "$extension"
  echo "Installed $extension"
done

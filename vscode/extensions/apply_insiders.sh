#!/bin/sh
# dotfiles内のextensionsを正として、localの拡張を上書きする

CURRENT=$(cd $(dirname $0) && pwd)

# OS検出とVSCode Insiders設定ディレクトリの決定（参照用）
OS=$(uname -s)
case "$OS" in
  Darwin)
    # macOS
    VSCODE_SETTING_DIR=~/Library/Application\ Support/Code\ -\ Insiders/User
    ;;
  Linux)
    # Linux
    VSCODE_SETTING_DIR=~/.config/Code\ -\ Insiders/User
    ;;
  *)
    echo "Unsupported OS: $OS"
    exit 1
    ;;
esac

# Install extensions from dotfiles that are not in local
sort "$CURRENT/extensions" | while read -r extension; do
  code-insiders --install-extension "$extension"
  echo "Installed $extension"
done

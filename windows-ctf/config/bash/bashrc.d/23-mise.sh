#!/usr/bin/env bash
# mise runtime manager (equivalent to mise.zsh)

if command -v mise >/dev/null 2>&1; then
  # シムベースでPATHに追加（プロンプトフックなし → 高速化）
  export PATH="$HOME/.local/share/mise/shims:$PATH"
fi

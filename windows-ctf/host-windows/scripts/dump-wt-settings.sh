#!/usr/bin/env bash
set -euo pipefail

DOTFILES_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
WT_DST="$DOTFILES_ROOT/windows-ctf/host-windows/config/windows-terminal/settings.json"

WIN_USERNAME="${WIN_USERNAME:-$(ls /mnt/c/Users/ | grep -v -E 'All Users|Default|Public|desktop.ini' | head -1)}"
WIN_HOME="/mnt/c/Users/$WIN_USERNAME"

# 両方の Windows Terminal 設定パスを試す
WT_PATHS=(
    "$WIN_HOME/AppData/Local/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json"
    "$WIN_HOME/AppData/Local/Microsoft/Windows Terminal/settings.json"
)

WT_SRC=""
for path in "${WT_PATHS[@]}"; do
    [[ -f "$path" ]] && WT_SRC="$path" && break
done

[[ -z "$WT_SRC" ]] && { echo "Error: settings.json not found" >&2; exit 1; }

cp "$WT_SRC" "$WT_DST"
echo "Dumped: $WT_SRC -> $WT_DST"

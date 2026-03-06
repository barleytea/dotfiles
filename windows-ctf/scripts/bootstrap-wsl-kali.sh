#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! grep -qi "microsoft" /proc/version 2>/dev/null; then
    echo "Warning: this does not look like WSL. Proceeding anyway."
fi

# Ensure base system is up to date before tool bootstrap.
sudo apt-get update
sudo apt-get dist-upgrade -y

"${SCRIPT_DIR}/install-manifest.sh" all

# Shell defaults used across both WSL and VM.
if command -v zsh >/dev/null 2>&1; then
    if [[ "${SHELL:-}" != "$(command -v zsh)" ]]; then
        echo "Tip: run 'chsh -s $(command -v zsh)' to switch your default shell to zsh."
    fi
fi

cat <<'EOM'
WSL bootstrap complete.
Next:
1. Run ./scripts/sync-dotfiles.sh
2. Run ./scripts/verify-environment.sh
3. For GUI apps, verify WSLg with: xclock or wireshark
EOM

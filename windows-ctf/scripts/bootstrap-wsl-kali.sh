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

"${SCRIPT_DIR}/install-mise.sh"

"${SCRIPT_DIR}/install-tailscale.sh"

"${SCRIPT_DIR}/install-docker.sh"

# Setup bash environment (tools + config symlinks)
"${SCRIPT_DIR}/setup-bash.sh"

# Setup Claude Code configuration (symlinks)
"${SCRIPT_DIR}/setup-claude.sh"

cat <<'EOM'
WSL bootstrap complete.
Next:
1. Run ./scripts/sync-dotfiles.sh
2. Run ./scripts/verify-environment.sh
3. Re-open the shell or run: newgrp docker
4. Verify Docker with: docker run hello-world
5. For GUI apps, verify WSLg with: xclock or wireshark
EOM

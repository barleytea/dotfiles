#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Kali VM baseline updates.
sudo apt-get update
sudo apt-get dist-upgrade -y

"${SCRIPT_DIR}/install-manifest.sh" all

cat <<'EOM'
VM bootstrap complete.
Recommended post-steps:
1. Install open-vm-tools-desktop if not already present.
2. Create a clean snapshot named: baseline-clean
3. Create a second snapshot named: ctf-ready
4. Run ./scripts/verify-environment.sh
EOM

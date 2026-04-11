#!/usr/bin/env bash
# Install Nix + nixvim for Kali/WSL (non-NixOS)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
NIXVIM_DIR="${DOTFILES_DIR}/nixvim"

# 1. Nix をインストール（未インストールの場合）
if ! command -v nix >/dev/null 2>&1; then
  echo "==> Installing Nix (Determinate Systems installer)"
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix \
    | sh -s -- install --no-confirm
  # 現在のセッションに nix を読み込む
  if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
    # shellcheck disable=SC1091
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  fi
else
  echo "==> Nix already installed: $(nix --version)"
fi

# 2. nixvim を nix profile でインストール
echo "==> Installing nixvim from ${NIXVIM_DIR}"
nix profile install "${NIXVIM_DIR}#default"

echo ""
echo "==> nixvim installed. Run 'nvim' to launch."
echo "    'vim' and 'vi' are also aliased via 90-aliases.sh."

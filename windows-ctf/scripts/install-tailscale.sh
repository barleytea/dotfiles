#!/usr/bin/env bash
# Install Tailscale on WSL Kali
set -euo pipefail

echo "==> Installing Tailscale"
curl -fsSL https://tailscale.com/install.sh | sh

echo ""
echo "==> Tailscale installed."
echo "    Next steps:"
echo "    1. Start daemon:  sudo tailscaled --tun=userspace-networking &"
echo "    2. Connect:       sudo tailscale up"
echo ""
echo "    WSL tip: systemd が無効な場合は userspace-networking モードを使う:"
echo "    sudo tailscaled --tun=userspace-networking --socks5-server=localhost:1055 &"

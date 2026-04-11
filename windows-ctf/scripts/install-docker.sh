#!/usr/bin/env bash
set -euo pipefail

if ! grep -qi "microsoft" /proc/version 2>/dev/null; then
    echo "Warning: this does not look like WSL. Proceeding with Docker install anyway."
fi

sudo apt-get update
sudo apt-get install -y docker.io docker-compose

if ! getent group docker >/dev/null 2>&1; then
    echo "Warning: docker group was not created automatically."
else
    if id -nG "${USER}" | tr ' ' '\n' | grep -qx docker; then
        echo "User ${USER} is already in the docker group."
    else
        sudo usermod -aG docker "${USER}"
        echo "Added ${USER} to docker group. Re-login or run: newgrp docker"
    fi
fi

if command -v systemctl >/dev/null 2>&1 && [[ -d /run/systemd/system ]]; then
    sudo systemctl enable --now docker
else
    sudo service docker start
fi

echo "Docker install complete."
echo "Run 'docker run hello-world' after reloading your shell to verify daemon access."

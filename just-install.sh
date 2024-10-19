#!/bin/bash
mkdir -p ~/.local/bin
curl --retry 5 --retry-delay 5 --proto '==https' --tlsv1.2 -H 'User-Agent: Chrome' -sSf https://just.systems/install.sh | bash -s -- --to ~/.local/bin

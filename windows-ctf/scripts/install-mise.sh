#!/usr/bin/env bash
set -euo pipefail

# Install mise
curl https://mise.run | sh

# Add mise to PATH for this session
export PATH="${HOME}/.local/bin:${PATH}"

# Install Node.js LTS and activate
mise use --global node@lts

# Install npm global tools
mise exec -- npm install -g @openai/codex commitizen cz-git

echo "==> mise + Node.js + codex + commitizen installed"
echo "    Add the following to your shell rc:"
echo '    eval "$(~/.local/bin/mise activate bash)"'

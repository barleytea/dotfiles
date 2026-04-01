#!/usr/bin/env bash
# Setup Claude Code config symlinks
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

CLAUDE_CONFIG_SRC="${DOTFILES_DIR}/config/claude"
CLAUDE_HOME="${HOME}/.claude"

echo "==> Setting up Claude Code configuration..."

# Create directories
echo "==> Creating Claude directories..."
mkdir -p "${CLAUDE_HOME}/commands"
mkdir -p "${CLAUDE_HOME}/skills"
mkdir -p "${CLAUDE_HOME}/hooks"

# Link top-level config files
echo "==> Linking Claude config files..."
ln -sf "${CLAUDE_CONFIG_SRC}/CLAUDE.md" "${CLAUDE_HOME}/CLAUDE.md"
echo "  Linked: ${CLAUDE_HOME}/CLAUDE.md"

ln -sf "${CLAUDE_CONFIG_SRC}/settings.json" "${CLAUDE_HOME}/settings.json"
echo "  Linked: ${CLAUDE_HOME}/settings.json"

ln -sf "${CLAUDE_CONFIG_SRC}/statusline.sh" "${CLAUDE_HOME}/statusline.sh"
echo "  Linked: ${CLAUDE_HOME}/statusline.sh"

# Link hook scripts
echo "==> Linking Claude hooks..."
if [ -d "${CLAUDE_CONFIG_SRC}/hooks" ]; then
    for file in "${CLAUDE_CONFIG_SRC}/hooks"/*; do
        if [ -f "$file" ]; then
            filename=$(basename "$file")
            ln -sf "$file" "${CLAUDE_HOME}/hooks/${filename}"
            echo "  Linked: ${CLAUDE_HOME}/hooks/${filename}"
        fi
    done
fi

# Link skill directories (as directory symlinks)
echo "==> Linking Claude skills..."
if [ -d "${CLAUDE_CONFIG_SRC}/skills" ]; then
    for skillDir in "${CLAUDE_CONFIG_SRC}/skills"/*; do
        if [ -d "$skillDir" ]; then
            skillName=$(basename "$skillDir")
            ln -sfn "$skillDir" "${CLAUDE_HOME}/skills/${skillName}"
            echo "  Linked: ${CLAUDE_HOME}/skills/${skillName}"
        fi
    done
fi

echo ""
echo "==> Claude Code setup complete!"
echo "    Config deployed to: ${CLAUDE_HOME}/"

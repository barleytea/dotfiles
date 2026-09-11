#!/usr/bin/env bash
# Setup Claude Code config symlinks
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

CLAUDE_CONFIG_SRC="${REPO_ROOT}/modules/home/claude/config"
CLAUDE_HOME="${HOME}/.claude"

echo "==> Setting up Claude Code configuration..."

if ! command -v jq >/dev/null 2>&1; then
    echo "Error: jq not found. Install jq before running this script." >&2
    exit 1
fi

# Create directories
echo "==> Creating Claude directories..."
mkdir -p "${CLAUDE_HOME}/commands"
mkdir -p "${CLAUDE_HOME}/skills"
mkdir -p "${CLAUDE_HOME}/hooks"
mkdir -p "${CLAUDE_HOME}/agents"

# Link top-level config files
echo "==> Linking Claude config files..."
ln -sfn "${CLAUDE_CONFIG_SRC}/AGENTS.md" "${CLAUDE_HOME}/CLAUDE.md"
echo "  Linked: ${CLAUDE_HOME}/CLAUDE.md"

ln -sfn "${CLAUDE_CONFIG_SRC}/statusline.sh" "${CLAUDE_HOME}/statusline.sh"
echo "  Linked: ${CLAUDE_HOME}/statusline.sh"

# settings.json は base + windows-ctf overlay をマージした実ファイルとして生成する（symlink ではない）
echo "==> Generating Claude settings.json (base + windows-ctf overlay)..."
if [ -L "${CLAUDE_HOME}/settings.json" ]; then
    # 旧セットアップが残した symlink を先に外しておかないと mv が symlink の先を上書きしてしまう
    rm -f "${CLAUDE_HOME}/settings.json"
fi
"${CLAUDE_CONFIG_SRC}/merge-settings.sh" \
    "${CLAUDE_CONFIG_SRC}/settings.json" \
    "${CLAUDE_CONFIG_SRC}/overlays/windows-ctf.json" \
    > "${CLAUDE_HOME}/settings.json.tmp"
jq empty "${CLAUDE_HOME}/settings.json.tmp"
mv "${CLAUDE_HOME}/settings.json.tmp" "${CLAUDE_HOME}/settings.json"
echo "  Generated: ${CLAUDE_HOME}/settings.json"

# Link hook scripts
echo "==> Linking Claude hooks..."
if [ -d "${CLAUDE_CONFIG_SRC}/hooks" ]; then
    for file in "${CLAUDE_CONFIG_SRC}/hooks"/*; do
        if [ -f "$file" ]; then
            filename=$(basename "$file")
            ln -sfn "$file" "${CLAUDE_HOME}/hooks/${filename}"
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

# Link command files
echo "==> Linking Claude commands..."
if [ -d "${CLAUDE_CONFIG_SRC}/commands" ]; then
    for file in "${CLAUDE_CONFIG_SRC}/commands"/*; do
        if [ -f "$file" ]; then
            filename=$(basename "$file")
            ln -sfn "$file" "${CLAUDE_HOME}/commands/${filename}"
            echo "  Linked: ${CLAUDE_HOME}/commands/${filename}"
        fi
    done
fi

# Link agent definitions
echo "==> Linking Claude agents..."
if [ -d "${CLAUDE_CONFIG_SRC}/agents" ]; then
    for file in "${CLAUDE_CONFIG_SRC}/agents"/*; do
        if [ -f "$file" ]; then
            filename=$(basename "$file")
            ln -sfn "$file" "${CLAUDE_HOME}/agents/${filename}"
            echo "  Linked: ${CLAUDE_HOME}/agents/${filename}"
        fi
    done
fi

# ai-guardrails のレビュースキル（任意: ローカルにチェックアウトされている場合のみ）
AI_GUARDRAILS_DIR="${AI_GUARDRAILS_DIR:-${REPO_ROOT}/../ai-guardrails}"
if [ -d "${AI_GUARDRAILS_DIR}/generated/claude-code/skills" ]; then
    echo "==> Linking ai-guardrails review skills..."
    for skillDir in "${AI_GUARDRAILS_DIR}/generated/claude-code/skills"/*; do
        if [ -d "$skillDir" ]; then
            skillName=$(basename "$skillDir")
            ln -sfn "$skillDir" "${CLAUDE_HOME}/skills/review-${skillName}"
            echo "  Linked: ${CLAUDE_HOME}/skills/review-${skillName}"
        fi
    done
fi
if [ -d "${AI_GUARDRAILS_DIR}/generated/external-skills" ]; then
    echo "==> Linking ai-guardrails external skills..."
    for skillDir in "${AI_GUARDRAILS_DIR}/generated/external-skills"/*; do
        if [ -d "$skillDir" ]; then
            skillName=$(basename "$skillDir")
            ln -sfn "$skillDir" "${CLAUDE_HOME}/skills/external-${skillName}"
            echo "  Linked: ${CLAUDE_HOME}/skills/external-${skillName}"
        fi
    done
fi
if [ ! -d "${AI_GUARDRAILS_DIR}" ]; then
    echo "  Note: ai-guardrails is not checked out at ${AI_GUARDRAILS_DIR}; review/external skills were skipped."
fi

echo ""
echo "==> Claude Code setup complete!"
echo "    Config deployed to: ${CLAUDE_HOME}/"

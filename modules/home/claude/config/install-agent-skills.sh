#!/usr/bin/env bash
# Claude Code 以外の agent に共有する Agent Skill を冪等に導入する。
set -euo pipefail

SKILL_NAME="typesafe-ai"
SKILL_SOURCE="typesafe-ai/skills"
SHARED_SKILL_PATH="${HOME}/.agents/skills/${SKILL_NAME}/SKILL.md"
SKILL_PATHS=(
    "${HOME}/.codex/skills/${SKILL_NAME}/SKILL.md"
    "${HOME}/.gemini/skills/${SKILL_NAME}/SKILL.md"
    "${HOME}/.copilot/skills/${SKILL_NAME}/SKILL.md"
)

if ! command -v npx >/dev/null 2>&1; then
    echo "  Note: npx not found; skipping ${SKILL_NAME} for other agents." >&2
    exit 0
fi

if [ -f "${SHARED_SKILL_PATH}" ]; then
    echo "  Agent Skill already installed: ${SKILL_NAME}"
    exit 0
fi

for skillPath in "${SKILL_PATHS[@]}"; do
    if [ ! -f "${skillPath}" ]; then
        echo "==> Installing Agent Skill: ${SKILL_NAME}"
        npx --yes skills add "${SKILL_SOURCE}" \
            --skill "${SKILL_NAME}" \
            --global \
            --agent codex gemini-cli github-copilot \
            --yes
        exit 0
    fi
done

echo "  Agent Skill already installed: ${SKILL_NAME}"

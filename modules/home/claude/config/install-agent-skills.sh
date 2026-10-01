#!/usr/bin/env bash
# Claude Code 以外の agent に共有する Agent Skill を冪等に導入する。
set -euo pipefail

if ! command -v npx >/dev/null 2>&1; then
    echo "  Note: npx not found; skipping external Agent Skills." >&2
    exit 0
fi

install_skill() {
    local skillName="$1"
    local skillSource="$2"
    local skillSelector="${3:-}"
    local sharedSkillPath="${HOME}/.agents/skills/${skillName}/SKILL.md"
    local skillPaths=(
        "${HOME}/.codex/skills/${skillName}/SKILL.md"
        "${HOME}/.gemini/skills/${skillName}/SKILL.md"
        "${HOME}/.copilot/skills/${skillName}/SKILL.md"
    )

    if [ -f "${sharedSkillPath}" ]; then
        echo "  Agent Skill already installed: ${skillName}"
        return 0
    fi

    for skillPath in "${skillPaths[@]}"; do
        if [ ! -f "${skillPath}" ]; then
            echo "==> Installing Agent Skill: ${skillName}"
            if [ -n "${skillSelector}" ]; then
                npx --yes skills add "${skillSource}" \
                    --skill "${skillSelector}" \
                    --global \
                    --agent codex gemini-cli github-copilot \
                    --yes
            else
                npx --yes skills add "${skillSource}" \
                    --global \
                    --agent codex gemini-cli github-copilot \
                    --yes
            fi
            return 0
        fi
    done

    echo "  Agent Skill already installed: ${skillName}"
}

install_skill "typesafe-ai" "typesafe-ai/skills" "typesafe-ai"
install_skill "yomiyasu" "nanaism/yomiyasu"

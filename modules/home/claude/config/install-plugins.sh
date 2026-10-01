#!/usr/bin/env bash
# Claude Code の外部プラグインを冪等に導入する。
set -euo pipefail

if ! command -v claude >/dev/null 2>&1; then
    echo "  Note: claude not found; skipping external plugins." >&2
    exit 0
fi

if ! command -v jq >/dev/null 2>&1; then
    echo "Error: jq not found; cannot inspect Claude Code plugins." >&2
    exit 1
fi

install_plugin() {
    local marketplaceName="$1"
    local marketplaceSource="$2"
    local pluginId="$3"

    if ! claude plugin marketplace list --json \
        | jq -e --arg name "${marketplaceName}" 'any(.[]; .name == $name)' >/dev/null; then
        echo "==> Adding Claude Code marketplace: ${marketplaceSource}"
        if ! claude plugin marketplace add "${marketplaceSource}"; then
            echo "  Warning: failed to add Claude Code marketplace: ${marketplaceName}; skipping plugin." >&2
            return 0
        fi
    fi

    if ! claude plugin list --json \
        | jq -e --arg id "${pluginId}" 'any(.[]; .id == $id)' >/dev/null; then
        echo "==> Installing Claude Code plugin: ${pluginId}"
        if ! claude plugin install "${pluginId}" --scope user --yes; then
            echo "  Warning: failed to install Claude Code plugin: ${pluginId}; continuing." >&2
        fi
    else
        echo "  Claude Code plugin already installed: ${pluginId}"
    fi
}

install_plugin "typesafe-ai" "https://github.com/typesafe-ai/skills.git" "typesafe@typesafe-ai"
install_plugin "yomiyasu" "https://github.com/nanaism/yomiyasu.git" "yomiyasu@yomiyasu"

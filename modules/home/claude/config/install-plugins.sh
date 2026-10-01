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
        claude plugin marketplace add "${marketplaceSource}"
    fi

    if ! claude plugin list --json \
        | jq -e --arg id "${pluginId}" 'any(.[]; .id == $id)' >/dev/null; then
        echo "==> Installing Claude Code plugin: ${pluginId}"
        claude plugin install "${pluginId}" --scope user --yes
    else
        echo "  Claude Code plugin already installed: ${pluginId}"
    fi
}

install_plugin "typesafe-ai" "typesafe-ai/skills" "typesafe@typesafe-ai"
install_plugin "yomiyasu" "nanaism/yomiyasu" "yomiyasu@yomiyasu"

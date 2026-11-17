#!/usr/bin/env bash
# Codex の外部プラグインを冪等に導入する。
set -euo pipefail

if ! command -v codex >/dev/null 2>&1; then
    echo "  Note: codex not found; skipping external plugins." >&2
    exit 0
fi

if ! command -v jq >/dev/null 2>&1; then
    echo "  Note: jq not found; skipping external plugins." >&2
    exit 0
fi

marketplaceName="pstack-claude"
marketplaceSource="https://github.com/michael-denyer/pstack-claude.git"
marketplaceRef="a12b04786023e762f12f5de7bb5fafb8c23f8c36"
pluginId="pstack@pstack-claude"

marketplaces="$(codex plugin marketplace list --json)" || {
    echo "  Warning: failed to list Codex marketplaces; skipping pstack." >&2
    exit 0
}

if ! printf '%s\n' "${marketplaces}" \
    | jq -e --arg name "${marketplaceName}" 'any(.marketplaces[]?; .name == $name)' >/dev/null; then
    echo "==> Adding Codex marketplace: ${marketplaceSource}#${marketplaceRef}"
    if ! codex plugin marketplace add "${marketplaceSource}" \
        --ref "${marketplaceRef}" \
        --sparse .agents/plugins \
        --sparse plugins/pstack; then
        echo "  Warning: failed to add Codex marketplace: ${marketplaceName}; skipping plugin." >&2
        exit 0
    fi
    marketplaces="$(codex plugin marketplace list --json)" || {
        echo "  Warning: failed to confirm Codex marketplace: ${marketplaceName}; skipping plugin." >&2
        exit 0
    }
fi

configuredSource="$(printf '%s\n' "${marketplaces}" \
    | jq -r --arg name "${marketplaceName}" '.marketplaces[]? | select(.name == $name) | .marketplaceSource.source // empty')"
if [[ "${configuredSource}" != "${marketplaceSource}" ]]; then
    echo "  Warning: Codex marketplace ${marketplaceName} points to an unexpected source; skipping pstack." >&2
    exit 0
fi

plugins="$(codex plugin list --marketplace "${marketplaceName}" --json)" || {
    echo "  Warning: failed to list Codex plugins from ${marketplaceName}; skipping pstack." >&2
    exit 0
}

if ! printf '%s\n' "${plugins}" \
    | jq -e --arg id "${pluginId}" 'any(.installed[]?; .pluginId == $id and .installed == true)' >/dev/null; then
    echo "==> Installing Codex plugin: ${pluginId}"
    if ! codex plugin add "${pluginId}"; then
        echo "  Warning: failed to install Codex plugin: ${pluginId}; continuing." >&2
    fi
else
    echo "  Codex plugin already installed: ${pluginId}"
fi

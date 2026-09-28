#!/usr/bin/env bash
# Claude Code の外部プラグインを冪等に導入する。
set -euo pipefail

MARKETPLACE_NAME="typesafe-ai"
MARKETPLACE_SOURCE="typesafe-ai/skills"
PLUGIN_ID="typesafe@typesafe-ai"

if ! command -v claude >/dev/null 2>&1; then
    echo "  Note: claude not found; skipping ${PLUGIN_ID}." >&2
    exit 0
fi

if ! command -v jq >/dev/null 2>&1; then
    echo "Error: jq not found; cannot inspect Claude Code plugins." >&2
    exit 1
fi

if ! claude plugin marketplace list --json \
    | jq -e --arg name "${MARKETPLACE_NAME}" 'any(.[]; .name == $name)' >/dev/null; then
    echo "==> Adding Claude Code marketplace: ${MARKETPLACE_SOURCE}"
    claude plugin marketplace add "${MARKETPLACE_SOURCE}"
fi

if ! claude plugin list --json \
    | jq -e --arg id "${PLUGIN_ID}" 'any(.[]; .id == $id)' >/dev/null; then
    echo "==> Installing Claude Code plugin: ${PLUGIN_ID}"
    claude plugin install "${PLUGIN_ID}" --scope user --yes
else
    echo "  Claude Code plugin already installed: ${PLUGIN_ID}"
fi

#!/usr/bin/env bash
# 初回セットアップ時だけ、mise タスクで共有 Agent Skills を導入する。
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/../../../.." && pwd)"

if ! command -v gh >/dev/null 2>&1; then
    echo "  Note: gh not found; skipping external Agent Skills." >&2
    exit 0
fi

if ! bash "${repo_root}/.mise/tasks/agent-skills" --ensure; then
    echo "  Warning: failed to install external Agent Skills; continuing." >&2
fi

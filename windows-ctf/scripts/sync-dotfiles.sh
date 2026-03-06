#!/usr/bin/env bash
set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/barleytea/dotfiles.git}"
TARGET_DIR="${TARGET_DIR:-${HOME}/git_repos/github.com/barleytea/dotfiles}"

if [[ ! -d "${TARGET_DIR}/.git" ]]; then
    echo "==> Cloning dotfiles into ${TARGET_DIR}"
    mkdir -p "$(dirname "${TARGET_DIR}")"
    git clone "${REPO_URL}" "${TARGET_DIR}"
else
    echo "==> Updating dotfiles in ${TARGET_DIR}"
    git -C "${TARGET_DIR}" pull --ff-only
fi

echo "==> Repository synchronized. No additional linker is applied by this script."
echo "    Apply host-side settings via windows-ctf/host-windows/scripts as needed."

echo "==> Dotfiles sync complete"

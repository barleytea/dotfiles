#!/usr/bin/env bash
set -euo pipefail

readonly HERDR_INSTALL_URL='https://herdr.dev/install.sh'
readonly HERDR_BIN="${HERDR_INSTALL_DIR:-${HOME}/.local/bin}/herdr"

tmp_dir="$(mktemp -d)"
cleanup() {
    rm -rf -- "${tmp_dir}"
}
trap cleanup EXIT

echo '==> Installing/updating Herdr for Kali'
curl --proto '=https' --tlsv1.2 -fsSL \
    "${HERDR_INSTALL_URL}" \
    -o "${tmp_dir}/install-herdr.sh"
sh "${tmp_dir}/install-herdr.sh"

if [[ ! -x "${HERDR_BIN}" ]]; then
    echo "Herdr installer did not create ${HERDR_BIN}." >&2
    exit 1
fi

"${HERDR_BIN}" --version
echo "==> Herdr installed: ${HERDR_BIN}"

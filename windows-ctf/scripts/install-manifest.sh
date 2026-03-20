#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST_DIR="${SCRIPT_DIR}/../manifests"

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <manifest-name|manifest-file> [manifest-name|manifest-file ...]"
    echo "Example: $0 all"
    exit 1
fi

if ! command -v apt-get >/dev/null 2>&1; then
    echo "Error: apt-get not found. This script is for Debian/Kali-based systems."
    exit 1
fi

APT_UPDATED=false

update_apt_once() {
    if [[ "${APT_UPDATED}" == false ]]; then
        echo "==> Updating apt package index"
        sudo apt-get update
        APT_UPDATED=true
    fi
}

resolve_manifest_path() {
    local value="$1"
    if [[ -f "${value}" ]]; then
        printf '%s\n' "${value}"
        return
    fi

    local candidate="${MANIFEST_DIR}/${value}.txt"
    if [[ -f "${candidate}" ]]; then
        printf '%s\n' "${candidate}"
        return
    fi

    echo "Error: manifest not found: ${value}" >&2
    exit 1
}

install_manifest() {
    local manifest_path="$1"
    echo "==> Applying manifest: $(basename "${manifest_path}")"

    local line
    while IFS= read -r line || [[ -n "${line}" ]]; do
        # Trim leading/trailing spaces.
        line="${line#${line%%[![:space:]]*}}"
        line="${line%${line##*[![:space:]]}}"

        if [[ -z "${line}" || "${line}" == \#* ]]; then
            continue
        fi

        if [[ "${line}" == @* ]]; then
            local nested="${line#@}"
            local nested_path
            nested_path="$(resolve_manifest_path "${nested}")"
            install_manifest "${nested_path}"
            continue
        fi

        update_apt_once
        echo "  - ${line}"
        # Pre-answer debconf prompts for known interactive packages.
        case "${line}" in
            wireshark|wireshark-common)
                echo "wireshark-common wireshark-common/install-setuid boolean true" \
                    | sudo debconf-set-selections
                ;;
        esac
        sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "${line}"
    done < "${manifest_path}"
}

for manifest in "$@"; do
    manifest_path="$(resolve_manifest_path "${manifest}")"
    install_manifest "${manifest_path}"
done

echo "==> Manifest installation complete"

#!/usr/bin/env bash
set -euo pipefail

readonly KEYRING_URL='https://cli.github.com/packages/githubcli-archive-keyring.gpg'
readonly KEYRING_SHA256='6084d5d7bd8e288441e0e94fc6275570895da18e6751f70f057485dc2d1a811b'
readonly KEYRING_PATH='/etc/apt/keyrings/githubcli-archive-keyring.gpg'
readonly SOURCE_PATH='/etc/apt/sources.list.d/github-cli.list'

for command_name in curl dpkg sha256sum sudo; do
    if ! command -v "${command_name}" >/dev/null 2>&1; then
        echo "Error: required command not found: ${command_name}" >&2
        exit 1
    fi
done

temporary_dir="$(mktemp -d)"
trap 'rm -rf -- "${temporary_dir}"' EXIT
download_path="${temporary_dir}/githubcli-archive-keyring.gpg"

echo '==> Downloading the official GitHub CLI signing key'
curl --fail --location --silent --show-error --retry 3 \
    --output "${download_path}" "${KEYRING_URL}"

actual_sha256="$(sha256sum "${download_path}" | cut -d ' ' -f 1)"
if [[ "${actual_sha256}" != "${KEYRING_SHA256}" ]]; then
    echo 'Error: GitHub CLI signing key checksum verification failed' >&2
    exit 1
fi

architecture="$(dpkg --print-architecture)"
repository="deb [arch=${architecture} signed-by=${KEYRING_PATH}] https://cli.github.com/packages stable main"

echo '==> Configuring the official GitHub CLI apt repository'
sudo install -d -m 0755 /etc/apt/keyrings /etc/apt/sources.list.d
sudo install -m 0644 "${download_path}" "${KEYRING_PATH}"
printf '%s\n' "${repository}" | sudo tee "${SOURCE_PATH}" >/dev/null

echo '==> Installing GitHub CLI'
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y gh

echo "GitHub CLI installed: $(gh --version | head -n 1)"

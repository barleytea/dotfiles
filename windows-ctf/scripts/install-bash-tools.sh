#!/usr/bin/env bash
# Install bash terminal tools for WSL Kali
# Installs: starship, atuin, zoxide (via curl installers), eza, bat, ghq
set -euo pipefail

LOCAL_BIN="${HOME}/.local/bin"
mkdir -p "${LOCAL_BIN}"

# Ensure ~/.local/bin is in PATH for this session
export PATH="${LOCAL_BIN}:${PATH}"

echo "==> Installing apt packages: bat, eza"
sudo apt-get install -y bat eza 2>/dev/null || {
  echo "Note: eza not found in apt, will skip. Install manually if needed."
  sudo apt-get install -y bat 2>/dev/null || true
}
# On Debian/Ubuntu, bat may be installed as 'batcat'
if command -v batcat >/dev/null 2>&1 && ! command -v bat >/dev/null 2>&1; then
  ln -sf "$(command -v batcat)" "${LOCAL_BIN}/bat"
fi

echo "==> Installing starship"
curl -sS https://starship.rs/install.sh | sh -s -- --bin-dir "${LOCAL_BIN}" --yes

echo "==> Installing atuin"
curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh
# atuin installer puts binary in ~/.atuin/bin, symlink to ~/.local/bin
if [[ -f "${HOME}/.atuin/bin/atuin" ]] && ! command -v atuin >/dev/null 2>&1; then
  ln -sf "${HOME}/.atuin/bin/atuin" "${LOCAL_BIN}/atuin"
fi

echo "==> Installing zoxide"
curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh

echo "==> Installing ghq"
GHQ_VERSION=$(curl -s https://api.github.com/repos/x-motemen/ghq/releases/latest | grep '"tag_name"' | sed 's/.*"v\([^"]*\)".*/\1/')
ARCH="$(uname -m)"
case "${ARCH}" in
  x86_64)  GHQ_ARCH="amd64" ;;
  aarch64) GHQ_ARCH="arm64" ;;
  *)        echo "Unsupported arch: ${ARCH}"; exit 1 ;;
esac
GHQ_URL="https://github.com/x-motemen/ghq/releases/download/v${GHQ_VERSION}/ghq_linux_${GHQ_ARCH}.zip"
TMP_DIR=$(mktemp -d)
curl -sSfL "${GHQ_URL}" -o "${TMP_DIR}/ghq.zip"
unzip -q "${TMP_DIR}/ghq.zip" -d "${TMP_DIR}"
install -m 755 "${TMP_DIR}/ghq_linux_${GHQ_ARCH}/ghq" "${LOCAL_BIN}/ghq"
rm -rf "${TMP_DIR}"

echo ""
echo "==> Done! Installed tools:"
for tool in starship atuin zoxide ghq bat eza; do
  if command -v "${tool}" >/dev/null 2>&1; then
    echo "  [OK] ${tool} $(${tool} --version 2>/dev/null | head -1)"
  else
    echo "  [MISSING] ${tool}"
  fi
done
echo ""
echo "Run 'make setup-bash' to link configs and add .bashrc source snippet."

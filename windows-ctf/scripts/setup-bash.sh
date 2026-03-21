#!/usr/bin/env bash
# Setup bash config symlinks and .bashrc integration
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

BASH_CONFIG_SRC="${DOTFILES_DIR}/config/bash"
BASH_CONFIG_DEST="${HOME}/.config/bash"

STARSHIP_CONFIG_SRC="${DOTFILES_DIR}/config/starship/starship.toml"
STARSHIP_CONFIG_DEST="${HOME}/.config/starship/starship.toml"

ATUIN_CONFIG_SRC="${DOTFILES_DIR}/config/atuin/config.toml"
ATUIN_CONFIG_DEST="${HOME}/.config/atuin/config.toml"

TMUX_CONF_SRC="${DOTFILES_DIR}/config/tmux/tmux.conf"
TMUX_CONF_DEST="${HOME}/.tmux.conf"

GIT_CONFIG_SRC="${DOTFILES_DIR}/config/git/config"
GIT_CONFIG_DEST="${HOME}/.config/git/config"

GIT_IGNORE_SRC="${DOTFILES_DIR}/config/git/ignore"
GIT_IGNORE_DEST="${HOME}/.config/git/ignore"

CZRC_SRC="${DOTFILES_DIR}/config/cz-git/czrc"
CZRC_DEST="${HOME}/.czrc"

echo "==> Installing bash tools first..."
bash "${SCRIPT_DIR}/install-bash-tools.sh"

echo ""
echo "==> Creating config directories..."
mkdir -p "${HOME}/.config/bash" "${HOME}/.config/starship" "${HOME}/.config/atuin" "${HOME}/.config/git"
mkdir -p "${HOME}/.local/state/bash" "${HOME}/.local/state/less"

echo "==> Linking bash config directory..."
# Link bashrc.d directory (link individual files to allow additions)
mkdir -p "${BASH_CONFIG_DEST}/bashrc.d"
for f in "${BASH_CONFIG_SRC}/bashrc.d/"*.sh; do
  dest="${BASH_CONFIG_DEST}/bashrc.d/$(basename "$f")"
  ln -sf "$f" "$dest"
  echo "  Linked: $dest"
done

# Link main bashrc.sh
ln -sf "${BASH_CONFIG_SRC}/bashrc.sh" "${BASH_CONFIG_DEST}/bashrc.sh"
echo "  Linked: ${BASH_CONFIG_DEST}/bashrc.sh"

echo "==> Linking starship config..."
ln -sf "${STARSHIP_CONFIG_SRC}" "${STARSHIP_CONFIG_DEST}"
echo "  Linked: ${STARSHIP_CONFIG_DEST}"

echo "==> Linking atuin config..."
ln -sf "${ATUIN_CONFIG_SRC}" "${ATUIN_CONFIG_DEST}"
echo "  Linked: ${ATUIN_CONFIG_DEST}"

echo "==> Linking tmux config..."
ln -sf "${TMUX_CONF_SRC}" "${TMUX_CONF_DEST}"
echo "  Linked: ${TMUX_CONF_DEST}"

echo "==> Linking git config..."
ln -sf "${GIT_CONFIG_SRC}" "${GIT_CONFIG_DEST}"
echo "  Linked: ${GIT_CONFIG_DEST}"
ln -sf "${GIT_IGNORE_SRC}" "${GIT_IGNORE_DEST}"
echo "  Linked: ${GIT_IGNORE_DEST}"

echo "==> Linking cz-git config..."
ln -sf "${CZRC_SRC}" "${CZRC_DEST}"
echo "  Linked: ${CZRC_DEST}"

echo "==> Adding .bashrc source snippet..."
BASHRC="${HOME}/.bashrc"
SNIPPET='# Source extra configs from ~/.config/bash/bashrc.sh
if [ -f "${HOME}/.config/bash/bashrc.sh" ]; then source "${HOME}/.config/bash/bashrc.sh"; fi'

if ! grep -q '\.config/bash/bashrc\.sh' "${BASHRC}" 2>/dev/null; then
  printf '\n%s\n' "${SNIPPET}" >> "${BASHRC}"
  echo "  Added source snippet to ${BASHRC}"
else
  echo "  Source snippet already present in ${BASHRC}"
fi

echo ""
echo "==> Setup complete! Open a new bash session to activate all settings."
echo "    Or run: source ~/.bashrc"

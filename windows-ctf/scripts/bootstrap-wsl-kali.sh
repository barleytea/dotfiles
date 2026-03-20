#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! grep -qi "microsoft" /proc/version 2>/dev/null; then
    echo "Warning: this does not look like WSL. Proceeding anyway."
fi

# Ensure base system is up to date before tool bootstrap.
sudo apt-get update
sudo apt-get dist-upgrade -y

"${SCRIPT_DIR}/install-manifest.sh" all

"${SCRIPT_DIR}/install-mise.sh"

# Shell defaults used across both WSL and VM.
if command -v zsh >/dev/null 2>&1; then
    if [[ "${SHELL:-}" != "$(command -v zsh)" ]]; then
        echo "Tip: run 'chsh -s $(command -v zsh)' to switch your default shell to zsh."
    fi
fi

# zsh options (bell disable, etc.)
DOTFILES_DIR="${HOME}/git_repos/github.com/barleytea/dotfiles"
DOTFILES_ZSH_OPTIONS="${DOTFILES_DIR}/windows-ctf/config/zsh/options.zsh"
ZSHRC_D="${HOME}/.zshrc.d"
mkdir -p "${ZSHRC_D}"
ln -sf "${DOTFILES_ZSH_OPTIONS}" "${ZSHRC_D}/options.zsh"

# Ensure ~/.zshrc sources ~/.zshrc.d/*.zsh
if ! grep -q 'zshrc.d' "${HOME}/.zshrc" 2>/dev/null; then
    cat >> "${HOME}/.zshrc" <<'EOF'
# Source extra configs from ~/.zshrc.d/
for _f in "${HOME}/.zshrc.d"/*.zsh; do [ -f "$_f" ] && source "$_f"; done
unset _f
EOF
fi

cat <<'EOM'
WSL bootstrap complete.
Next:
1. Run ./scripts/sync-dotfiles.sh
2. Run ./scripts/verify-environment.sh
3. For GUI apps, verify WSLg with: xclock or wireshark
EOM

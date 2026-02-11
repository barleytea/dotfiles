#!/usr/bin/env bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  ParrotOS Dotfiles Installer          ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}\n"

# Check if running on Debian-based system
if [[ ! -f /etc/os-release ]]; then
    echo -e "${RED}✗ Cannot detect OS. /etc/os-release not found.${NC}"
    exit 1
fi

# shellcheck source=/dev/null
source /etc/os-release
if [[ ! "$ID" =~ (debian|ubuntu|parrot) ]]; then
    echo -e "${YELLOW}⚠ Warning: This script is designed for Debian-based systems.${NC}"
    echo -e "Detected OS: ${ID}"
    echo -e "Continue anyway? (y/N)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo -e "${GREEN}✓${NC} Detected OS: ${PRETTY_NAME}\n"

# Update package list
echo -e "${BLUE}[1/6] Updating package list...${NC}"
sudo apt update

# Install base packages
echo -e "\n${BLUE}[2/6] Installing base packages...${NC}"
if [[ -f "${SCRIPT_DIR}/packages/base.txt" ]]; then
    echo "Reading package list from base.txt..."
    xargs -a "${SCRIPT_DIR}/packages/base.txt" sudo apt install -y
    echo -e "${GREEN}✓${NC} Base packages installed"
else
    echo -e "${RED}✗ base.txt not found${NC}"
    exit 1
fi

# Install CTF tools (optional)
echo -e "\n${BLUE}[3/6] CTF Tools${NC}"
if [[ -f "${SCRIPT_DIR}/packages/ctf.txt" ]]; then
    echo -e "${YELLOW}Install CTF tools? (y/N)${NC}"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        echo "Installing CTF tools..."
        xargs -a "${SCRIPT_DIR}/packages/ctf.txt" sudo apt install -y || {
            echo -e "${YELLOW}⚠ Some CTF tools may not be available in your repositories${NC}"
        }
        echo -e "${GREEN}✓${NC} CTF tools installation attempted"
    else
        echo "Skipping CTF tools"
    fi
else
    echo -e "${YELLOW}⚠ ctf.txt not found, skipping${NC}"
fi

# Install Nerd Fonts (optional)
echo -e "\n${BLUE}[4/6] Nerd Fonts${NC}"
echo -e "${YELLOW}Install Nerd Fonts? (y/N)${NC}"
read -r response
if [[ "$response" =~ ^[Yy]$ ]]; then
    bash "${SCRIPT_DIR}/scripts/install-fonts.sh"
else
    echo "Skipping Nerd Fonts installation"
fi

# Install non-apt tools
echo -e "\n${BLUE}[5/6] Installing non-apt tools...${NC}"
bash "${SCRIPT_DIR}/scripts/install-tools.sh"

# Create symlinks
echo -e "\n${BLUE}[6/6] Creating symlinks...${NC}"
bash "${SCRIPT_DIR}/scripts/link.sh"

# Change default shell to zsh
echo -e "\n${BLUE}Changing default shell to zsh...${NC}"
if [[ "$SHELL" != "$(which zsh)" ]]; then
    echo "Current shell: $SHELL"
    echo -e "${YELLOW}Change default shell to zsh? (Y/n)${NC}"
    read -r response
    if [[ ! "$response" =~ ^[Nn]$ ]]; then
        chsh -s "$(which zsh)"
        echo -e "${GREEN}✓${NC} Default shell changed to zsh"
        echo -e "${YELLOW}Note: You need to log out and log back in for the change to take effect${NC}"
    fi
else
    echo -e "${GREEN}✓${NC} Default shell is already zsh"
fi

echo -e "\n${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  Installation Complete!                ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}\n"

echo -e "Next steps:"
echo -e "  1. ${YELLOW}Log out and log back in${NC} (to apply zsh as default shell)"
echo -e "  2. ${YELLOW}Open a new terminal${NC}"
echo -e "  3. Zellij will auto-start, and Sheldon will install zsh plugins on first run"
echo -e ""
echo -e "Optional:"
echo -e "  - Run ${BLUE}mise install${NC} to install mise-managed tools (node, go, python)"
echo -e "  - Run ${BLUE}mise run npm-commitizen${NC} to install commitizen globally"
echo -e "  - Run ${BLUE}mise run pre-commit-init${NC} to set up pre-commit hooks (if in a git repo)"
echo -e ""
echo -e "Enjoy your new development environment! 🚀"

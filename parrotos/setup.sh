#!/usr/bin/env bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  ParrotOS Dotfiles Bootstrap          ║${NC}"
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

# Install basic dependencies
echo -e "${BLUE}Installing basic dependencies (git, curl)...${NC}"
sudo apt update
sudo apt install -y git curl

# Clone or update dotfiles repository
DOTFILES_DIR="$HOME/git_repos/github.com/barleytea/dotfiles"

if [[ -d "$DOTFILES_DIR" ]]; then
    echo -e "\n${YELLOW}Dotfiles directory already exists: ${DOTFILES_DIR}${NC}"
    echo -e "${YELLOW}Update it? (Y/n)${NC}"
    read -r response
    if [[ ! "$response" =~ ^[Nn]$ ]]; then
        echo "Updating dotfiles repository..."
        cd "$DOTFILES_DIR"
        git pull
        echo -e "${GREEN}✓${NC} Repository updated"
    fi
else
    echo -e "\n${BLUE}Cloning dotfiles repository...${NC}"
    mkdir -p "$(dirname "$DOTFILES_DIR")"
    git clone https://github.com/barleytea/dotfiles.git "$DOTFILES_DIR"
    echo -e "${GREEN}✓${NC} Repository cloned"
fi

# Run the main installer
echo -e "\n${BLUE}Running main installer...${NC}"
bash "${DOTFILES_DIR}/parrotos/install.sh"

echo -e "\n${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  Bootstrap Complete!                   ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"

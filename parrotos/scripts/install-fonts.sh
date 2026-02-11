#!/usr/bin/env bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Installing Nerd Fonts ===${NC}\n"

FONTS_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONTS_DIR"

# Function to install a Nerd Font
install_nerd_font() {
    local font_name="$1"
    local font_display_name="${2:-$font_name}"

    echo -e "${BLUE}[${font_display_name}]${NC}"

    # Check if font is already installed
    if fc-list | grep -qi "${font_display_name}"; then
        echo -e "${GREEN}✓${NC} ${font_display_name} is already installed"
        return 0
    fi

    echo "Downloading ${font_display_name}..."

    local tmp_dir
    tmp_dir=$(mktemp -d)
    local font_url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${font_name}.zip"

    if curl -fL "$font_url" -o "${tmp_dir}/${font_name}.zip"; then
        echo "Installing ${font_display_name}..."
        unzip -q "${tmp_dir}/${font_name}.zip" -d "${tmp_dir}/${font_name}"

        # Copy only .ttf and .otf files
        find "${tmp_dir}/${font_name}" -type f \( -name "*.ttf" -o -name "*.otf" \) -exec cp {} "$FONTS_DIR/" \;

        echo -e "${GREEN}✓${NC} ${font_display_name} installed successfully"
    else
        echo -e "${RED}✗${NC} Failed to download ${font_display_name}"
    fi

    rm -rf "$tmp_dir"
}

# Install Hack Nerd Font (used in ghostty and terminal configs)
install_nerd_font "Hack" "Hack Nerd Font"

# Optional: Install more fonts
echo -e "\n${YELLOW}Would you like to install additional Nerd Fonts? (y/N)${NC}"
read -r response
if [[ "$response" =~ ^[Yy]$ ]]; then
    install_nerd_font "JetBrainsMono" "JetBrains Mono Nerd Font"
    install_nerd_font "FiraCode" "Fira Code Nerd Font"
    install_nerd_font "Meslo" "Meslo Nerd Font"
fi

# Refresh font cache
echo -e "\n${BLUE}Refreshing font cache...${NC}"
fc-cache -fv >/dev/null 2>&1

echo -e "\n${GREEN}=== Font installation complete! ===${NC}"
echo -e "Installed fonts are available at: ${FONTS_DIR}"
echo -e "\nYou can verify installed fonts with: fc-list | grep -i 'Nerd'"

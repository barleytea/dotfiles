#!/usr/bin/env bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to remove symlink
remove_link() {
    local target="$1"

    # Expand tilde in target path
    target="${target/#\~/$HOME}"

    if [[ -L "$target" ]]; then
        echo -e "${YELLOW}Removing symlink:${NC} ${target}"
        rm "$target"
    elif [[ -e "$target" ]]; then
        echo -e "${RED}Warning:${NC} ${target} exists but is not a symlink. Skipping."
    else
        echo -e "${BLUE}Info:${NC} ${target} does not exist. Skipping."
    fi
}

echo -e "${BLUE}=== ParrotOS Dotfiles Symlink Removal ===${NC}\n"

# Zsh
echo -e "${BLUE}[Zsh]${NC}"
remove_link ~/.zshenv
remove_link ~/.config/zsh/.zshrc
for config in ~/.config/zsh/config/*.zsh; do
    if [[ -L "$config" ]]; then
        remove_link "$config"
    fi
done

# Sheldon
echo -e "\n${BLUE}[Sheldon]${NC}"
remove_link ~/.config/sheldon/plugins.toml

# Git
echo -e "\n${BLUE}[Git]${NC}"
remove_link ~/.config/git/config
remove_link ~/.config/git/ignore

# Starship
echo -e "\n${BLUE}[Starship]${NC}"
remove_link ~/.config/starship.toml

# Atuin
echo -e "\n${BLUE}[Atuin]${NC}"
remove_link ~/.config/atuin/config.toml

# Mise
echo -e "\n${BLUE}[Mise]${NC}"
remove_link ~/.config/mise/config.toml

# Tmux
echo -e "\n${BLUE}[Tmux]${NC}"
remove_link ~/.tmux.conf

# Lazygit
echo -e "\n${BLUE}[Lazygit]${NC}"
remove_link ~/.config/lazygit/config.yml

# Ghostty
echo -e "\n${BLUE}[Ghostty]${NC}"
remove_link ~/.config/ghostty/config

# Zellij
echo -e "\n${BLUE}[Zellij]${NC}"
remove_link ~/.config/zellij/config.kdl

# Yazi
echo -e "\n${BLUE}[Yazi]${NC}"
remove_link ~/.config/yazi/yazi.toml
remove_link ~/.config/yazi/keymap.toml

# EditorConfig
echo -e "\n${BLUE}[EditorConfig]${NC}"
remove_link ~/.editorconfig

# Scripts
echo -e "\n${BLUE}[Scripts]${NC}"
remove_link ~/.local/bin/zellij-worktree-switcher
remove_link ~/.local/bin/zellij-session-switcher
remove_link ~/.local/bin/zellij-worktree-remove

echo -e "\n${GREEN}=== Symlink removal complete! ===${NC}"

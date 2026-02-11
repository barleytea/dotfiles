#!/usr/bin/env bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the dotfiles directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"

# Dry-run mode
DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
    echo -e "${YELLOW}=== DRY RUN MODE ===${NC}"
fi

# Backup timestamp
BACKUP_TIMESTAMP=$(date +%Y%m%d%H%M%S)

# Function to create symlink
create_link() {
    local source="$1"
    local target="$2"

    # Expand tilde in target path
    target="${target/#\~/$HOME}"

    if [[ "$DRY_RUN" == true ]]; then
        echo -e "${BLUE}[DRY-RUN]${NC} Would link: ${source} -> ${target}"
        return
    fi

    # Create parent directory if it doesn't exist
    local parent_dir
    parent_dir="$(dirname "$target")"
    if [[ ! -d "$parent_dir" ]]; then
        echo -e "${YELLOW}Creating directory:${NC} ${parent_dir}"
        mkdir -p "$parent_dir"
    fi

    # Backup existing file/link
    if [[ -e "$target" ]] || [[ -L "$target" ]]; then
        local backup="${target}.bak.${BACKUP_TIMESTAMP}"
        echo -e "${YELLOW}Backing up existing file:${NC} ${target} -> ${backup}"
        mv "$target" "$backup"
    fi

    # Create symlink
    echo -e "${GREEN}Linking:${NC} ${source} -> ${target}"
    ln -sf "$source" "$target"
}

# Function to link all files in a directory
link_directory() {
    local source_dir="$1"
    local target_dir="$2"

    for file in "$source_dir"/*; do
        if [[ -f "$file" ]]; then
            local filename
            filename="$(basename "$file")"
            create_link "$file" "${target_dir}/${filename}"
        fi
    done
}

echo -e "${BLUE}=== ParrotOS Dotfiles Symlink Setup ===${NC}\n"

# Zsh
echo -e "${BLUE}[Zsh]${NC}"
create_link "${DOTFILES_DIR}/shell/zsh/.zshenv" ~/.zshenv
create_link "${DOTFILES_DIR}/shell/zsh/.zshrc" ~/.config/zsh/.zshrc
link_directory "${DOTFILES_DIR}/shell/zsh/config" ~/.config/zsh/config

# Sheldon
echo -e "\n${BLUE}[Sheldon]${NC}"
create_link "${DOTFILES_DIR}/shell/sheldon/plugins.toml" ~/.config/sheldon/plugins.toml

# Git
echo -e "\n${BLUE}[Git]${NC}"
create_link "${DOTFILES_DIR}/git/config" ~/.config/git/config
create_link "${DOTFILES_DIR}/git/ignore" ~/.config/git/ignore

# Starship
echo -e "\n${BLUE}[Starship]${NC}"
create_link "${DOTFILES_DIR}/starship/starship.toml" ~/.config/starship.toml

# Atuin
echo -e "\n${BLUE}[Atuin]${NC}"
create_link "${DOTFILES_DIR}/atuin/config.toml" ~/.config/atuin/config.toml

# Mise
echo -e "\n${BLUE}[Mise]${NC}"
create_link "${DOTFILES_DIR}/mise/config.toml" ~/.config/mise/config.toml

# Tmux
echo -e "\n${BLUE}[Tmux]${NC}"
create_link "${DOTFILES_DIR}/tmux/tmux.conf" ~/.tmux.conf

# Lazygit
echo -e "\n${BLUE}[Lazygit]${NC}"
create_link "${DOTFILES_DIR}/lazygit/config.yml" ~/.config/lazygit/config.yml

# Ghostty
echo -e "\n${BLUE}[Ghostty]${NC}"
create_link "${DOTFILES_DIR}/ghostty/config" ~/.config/ghostty/config

# Zellij
echo -e "\n${BLUE}[Zellij]${NC}"
create_link "${DOTFILES_DIR}/zellij/config.kdl" ~/.config/zellij/config.kdl

# Yazi
echo -e "\n${BLUE}[Yazi]${NC}"
create_link "${DOTFILES_DIR}/yazi/yazi.toml" ~/.config/yazi/yazi.toml
create_link "${DOTFILES_DIR}/yazi/keymap.toml" ~/.config/yazi/keymap.toml

# EditorConfig
echo -e "\n${BLUE}[EditorConfig]${NC}"
create_link "${DOTFILES_DIR}/editorconfig/.editorconfig" ~/.editorconfig

# Scripts
echo -e "\n${BLUE}[Scripts]${NC}"
mkdir -p ~/.local/bin
for script in "${DOTFILES_DIR}/scripts"/zellij-*.sh; do
    if [[ -f "$script" ]]; then
        script_name="$(basename "$script" .sh)"
        create_link "$script" ~/.local/bin/"${script_name}"
        if [[ "$DRY_RUN" == false ]]; then
            chmod +x ~/.local/bin/"${script_name}"
        fi
    fi
done

echo -e "\n${GREEN}=== Symlink setup complete! ===${NC}"

if [[ "$DRY_RUN" == true ]]; then
    echo -e "${YELLOW}Note: This was a dry run. No changes were made.${NC}"
    echo -e "Run without --dry-run to apply changes."
fi

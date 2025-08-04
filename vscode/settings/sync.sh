#!/usr/bin/env bash
# A simple script to synchronize settings between VSCode and Neovim
# This is a simplified version of sync-editor-settings installed via Home Manager

set -euo pipefail

# OS検出
OS=$(uname -s)

# Environment variables
HOME_DIR="$HOME"
DOTFILES_DIR="$HOME/git_repos/github.com/barleytea/dotfiles"
NVIM_CONFIG_DIR="$HOME/.config/nvim"
VSCODE_SETTINGS_DIR="$DOTFILES_DIR/vscode/settings"
NVIM_LUA_DIR="$NVIM_CONFIG_DIR/lua"

# Editor-specific settings directories - OS別に設定
case "$OS" in
  Darwin)
    # macOS
    VSCODE_USER_DIR="$HOME/Library/Application Support/Code/User"
    ;;
  Linux)
    # Linux
    VSCODE_USER_DIR="$HOME/.config/Code/User"
    ;;
  *)
    echo "Unsupported OS: $OS"
    exit 1
    ;;
esac

# Logging function
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Create backup
backup_file() {
  if [ -f "$1" ]; then
    cp "$1" "$1.bak"
    log "Created backup: $1.bak"
  fi
}

# Check and create directory
check_and_create_dir() {
  if [ ! -d "$1" ]; then
    mkdir -p "$1"
    log "Created directory: $1"
  fi
}

# Function to update a JSON/JSONC file property using Node.js
# This handles comments correctly unlike jq
update_jsonc_property() {
  local file="$1"
  local prop_path="$2"
  local new_value="$3"

  # Create a temporary Node.js script
  local tmp_script=$(mktemp)

  # Write a Node.js script that preserves comments
  cat > "$tmp_script" << 'EOF'
const fs = require('fs');
const path = require('path');

// Read the JSONC file as text
const filePath = process.argv[2];
const propPath = process.argv[3];
const newValue = process.argv[4];

try {
  // Read file content
  const content = fs.readFileSync(filePath, 'utf8');

  // Simple approach: find the property and replace its value with regex
  // This is not a proper JSON parser but works for simple cases with comments
  const propRegex = new RegExp(`(["']${propPath}["']\\s*:\\s*)[^,\\n\\r}]*(,|\\n|\\r|})`, 'g');
  const newContent = content.replace(propRegex, `$1"${newValue}"$2`);

  // Write back to file
  fs.writeFileSync(filePath, newContent, 'utf8');
  console.log("Updated property successfully");
} catch (error) {
  console.error("Error updating property:", error);
  process.exit(1);
}
EOF

  # Execute the Node.js script
  node "$tmp_script" "$file" "$prop_path" "$new_value"

  # Clean up
  rm "$tmp_script"
}

# VSCode settings sync
sync_editor_settings() {
  local editor_dir=$1
  local editor_name=$2

  log "Starting $editor_name settings synchronization..."

  # Check settings directory
  check_and_create_dir "$editor_dir"

  # Sync settings.json
  if [ -f "$VSCODE_SETTINGS_DIR/settings.json" ]; then
    if ! cmp -s "$VSCODE_SETTINGS_DIR/settings.json" "$editor_dir/settings.json"; then
      backup_file "$editor_dir/settings.json"
      cp "$VSCODE_SETTINGS_DIR/settings.json" "$editor_dir/settings.json"
      log "Updated $editor_name settings.json"
    else
      log "Skipped $editor_name settings.json (files are identical)"
    fi
  fi

  # Sync keybindings.json
  if [ -f "$VSCODE_SETTINGS_DIR/keybindings.json" ]; then
    if ! cmp -s "$VSCODE_SETTINGS_DIR/keybindings.json" "$editor_dir/keybindings.json"; then
      backup_file "$editor_dir/keybindings.json"
      cp "$VSCODE_SETTINGS_DIR/keybindings.json" "$editor_dir/keybindings.json"
      log "Updated $editor_name keybindings.json"
    else
      log "Skipped $editor_name keybindings.json (files are identical)"
    fi
  fi

  log "Completed $editor_name settings synchronization"
}

# VSCode to Neovim sync
sync_vscode_to_neovim() {
  log "Starting VSCode to Neovim settings synchronization..."

  # Check Neovim settings directory
  check_and_create_dir "$NVIM_LUA_DIR/shared"

  # Load VSCode keymap settings and convert to Neovim settings
  if [ -f "$VSCODE_SETTINGS_DIR/neovim-keymaps.json" ]; then
    # Create backup
    backup_file "$NVIM_LUA_DIR/shared/keymaps.lua"

    log "Generating Neovim keymap file..."
    cat > "$NVIM_LUA_DIR/shared/keymaps.lua" << 'EOL'
-- Keymap file generated from VSCode sync
-- Warning: This file is auto-generated. Take backup before manual editing.

local M = {}

function M.setup()
  -- Leader key setting
  vim.g.mapleader = " "

  -- Basic keymappings
  -- Editor operations
  vim.keymap.set('n', '<leader>w', ':w<CR>', { silent = true, desc = "Save" })
  vim.keymap.set('n', '<leader>q', ':q<CR>', { silent = true, desc = "Quit" })
  vim.keymap.set('i', 'jj', '<Esc>', { silent = true, desc = "ESC key" })

  -- Movement keys
  vim.keymap.set('n', '<C-h>', '<C-w>h', { silent = true, desc = "Move to left window" })
  vim.keymap.set('n', '<C-j>', '<C-w>j', { silent = true, desc = "Move to window below" })
  vim.keymap.set('n', '<C-k>', '<C-w>k', { silent = true, desc = "Move to window above" })
  vim.keymap.set('n', '<C-l>', '<C-w>l', { silent = true, desc = "Move to right window" })

  -- Tab/Buffer operations
  vim.keymap.set('n', '<S-h>', ':bprevious<CR>', { silent = true, desc = "Previous buffer" })
  vim.keymap.set('n', '<S-l>', ':bnext<CR>', { silent = true, desc = "Next buffer" })

  -- VSCode-specific settings (applied only when called from VSCode)
  if vim.g.vscode then
    -- Override VSCode-specific keymappings
    vim.keymap.set('n', '<C-h>', '<Cmd>call VSCodeNotify("workbench.action.navigateLeft")<CR>', { silent = true })
    vim.keymap.set('n', '<C-j>', '<Cmd>call VSCodeNotify("workbench.action.navigateDown")<CR>', { silent = true })
    vim.keymap.set('n', '<C-k>', '<Cmd>call VSCodeNotify("workbench.action.navigateUp")<CR>', { silent = true })
    vim.keymap.set('n', '<C-l>', '<Cmd>call VSCodeNotify("workbench.action.navigateRight")<CR>', { silent = true })

    -- Edit operations
    vim.keymap.set('n', '<leader>w', '<Cmd>call VSCodeNotify("workbench.action.files.save")<CR>', { silent = true })
    vim.keymap.set('n', '<leader>q', '<Cmd>call VSCodeNotify("workbench.action.closeActiveEditor")<CR>', { silent = true })
    vim.keymap.set('n', '<leader>e', '<Cmd>call VSCodeNotify("workbench.view.explorer")<CR>', { silent = true })
    vim.keymap.set('n', '<leader>f', '<Cmd>call VSCodeNotify("workbench.action.quickOpen")<CR>', { silent = true })

    -- Code operations
    vim.keymap.set('n', 'gd', '<Cmd>call VSCodeNotify("editor.action.revealDefinition")<CR>', { silent = true })
    vim.keymap.set('n', 'gr', '<Cmd>call VSCodeNotify("editor.action.goToReferences")<CR>', { silent = true })
  end
end

return M
EOL
    log "Updated Neovim keymap file"
  else
    log "Warning: neovim-keymaps.json not found in VSCode settings"
  fi

  # Generate Neovim settings file from VSCode settings
  if [ -f "$VSCODE_SETTINGS_DIR/settings.json" ]; then
    # Create backup
    backup_file "$NVIM_LUA_DIR/shared/options.lua"

    log "Generating Neovim settings file..."
    cat > "$NVIM_LUA_DIR/shared/options.lua" << 'EOL'
-- Settings file generated from VSCode sync
-- Warning: This file is auto-generated. Take backup before manual editing.

local M = {}

function M.setup()
  -- Basic settings
  vim.opt.number = true          -- Show line numbers
  vim.opt.relativenumber = true  -- Show relative line numbers
  vim.opt.cursorline = true      -- Highlight cursor line
  vim.opt.cursorcolumn = true    -- Highlight cursor column
  vim.opt.wrap = false           -- No line wrapping
  vim.opt.tabstop = 2            -- Tab width
  vim.opt.shiftwidth = 2         -- Indent width
  vim.opt.expandtab = true       -- Expand tabs to spaces
  vim.opt.smartindent = true     -- Smart indentation
  vim.opt.autoindent = true      -- Auto indentation

  -- Search settings
  vim.opt.hlsearch = true        -- Highlight search results
  vim.opt.ignorecase = true      -- Case-insensitive search
  vim.opt.smartcase = true       -- Smart case search

  -- System settings
  vim.opt.backup = false         -- No backup files
  vim.opt.writebackup = false    -- No backup files during write
  vim.opt.swapfile = false       -- No swap files
  vim.opt.updatetime = 50        -- Update time
  vim.opt.clipboard = "unnamedplus" -- Use system clipboard

  -- VSCode mode specific settings
  if vim.g.vscode then
    -- Override some settings in VSCode
    vim.opt.hlsearch = false     -- Let VSCode handle highlighting
    vim.opt.cursorline = false   -- Let VSCode handle cursor line
    vim.opt.cursorcolumn = false -- Let VSCode handle cursor column
  end
end

return M
EOL
    log "Updated Neovim settings file"
  else
    log "Warning: settings.json not found in VSCode settings"
  fi

  # Generate vscode.lua file
  backup_file "$NVIM_CONFIG_DIR/vscode.lua"
  log "Updating VSCode Neovim mode initialization file..."

  cat > "$NVIM_CONFIG_DIR/vscode.lua" << 'EOL'
-- VSCode-Neovim integration mode settings
-- This file is used when Neovim is launched from VS Code

-- Set VSCode mode flag
vim.g.vscode = 1

-- Load shared settings
local ok, options = pcall(require, 'shared.options')
if ok then
  options.setup()
else
  print("Warning: Failed to load options settings")
end

local ok, keymaps = pcall(require, 'shared.keymaps')
if ok then
  keymaps.setup()
else
  print("Warning: Failed to load keymap settings")
end

-- VSCode mode specific settings
-- Speed up escape sequences
vim.opt.ttimeoutlen = 0

print("VSCode-Neovim mode initialized")
EOL
  log "Updated VSCode Neovim mode initialization file"

  log "Completed VSCode to Neovim settings synchronization"
}

# Neovim to VSCode sync (basic settings only)
sync_neovim_to_vscode() {
  log "Starting Neovim to VSCode settings synchronization..."

  # Check VSCode settings directory
  check_and_create_dir "$VSCODE_SETTINGS_DIR"

  # Backup VSCode settings file
  if [ -f "$VSCODE_SETTINGS_DIR/settings.json" ]; then
    backup_file "$VSCODE_SETTINGS_DIR/settings.json"
  fi

  # Generate minimal settings file if it doesn't exist
  if [ ! -f "$VSCODE_SETTINGS_DIR/settings.json" ]; then
    # OS別のVSCode-Neovim設定
    case "$OS" in
      Darwin)
        # macOS
        cat > "$VSCODE_SETTINGS_DIR/settings.json" << EOL
{
    "workbench.colorTheme": "Dracula Theme",
    "editor.fontFamily": "'Hack Nerd Font Mono', Menlo, Monaco, 'Courier New', monospace",
    "editor.fontSize": 14,
    "editor.tabSize": 2,
    "editor.insertSpaces": true,
    "editor.wordWrap": "off",
    "terminal.integrated.fontFamily": "'Hack Nerd Font Mono'",
    "vscode-neovim.neovimExecutablePaths.darwin": "$HOME/.local/state/nix/profiles/profile/bin/nvim",
    "vscode-neovim.neovimInitVimPaths.darwin": "$NVIM_CONFIG_DIR/vscode.lua"
}
EOL
        ;;
      Linux)
        # Linux
        cat > "$VSCODE_SETTINGS_DIR/settings.json" << EOL
{
    "workbench.colorTheme": "Dracula Theme",
    "editor.fontFamily": "'Hack Nerd Font Mono', monospace",
    "editor.fontSize": 14,
    "editor.tabSize": 2,
    "editor.insertSpaces": true,
    "editor.wordWrap": "off",
    "terminal.integrated.fontFamily": "'Hack Nerd Font Mono'",
    "vscode-neovim.neovimExecutablePaths.linux": "$HOME/.local/state/nix/profiles/profile/bin/nvim",
    "vscode-neovim.neovimInitVimPaths.linux": "$NVIM_CONFIG_DIR/vscode.lua"
}
EOL
        ;;
    esac
    log "Generated basic VSCode settings file for $OS"
  else
    # Use Node.js to update the JSON while preserving comments
    if command -v node &> /dev/null; then
      # Set appropriate Neovim path in VSCode settings - OS別に分岐
      case "$OS" in
        Darwin)
          # macOS
          update_jsonc_property "$VSCODE_SETTINGS_DIR/settings.json" "vscode-neovim.neovimInitVimPaths.darwin" "$NVIM_CONFIG_DIR/vscode.lua"
          ;;
        Linux)
          # Linux
          update_jsonc_property "$VSCODE_SETTINGS_DIR/settings.json" "vscode-neovim.neovimInitVimPaths.linux" "$NVIM_CONFIG_DIR/vscode.lua"
          ;;
      esac
      log "Updated VSCode settings file with Node.js for $OS"
    else
      log "Warning: Node.js not found. Cannot update settings automatically."
      log "Please edit $VSCODE_SETTINGS_DIR/settings.json manually."
    fi
  fi

  log "Completed Neovim to VSCode settings synchronization"
}

# Main process
log "Starting editor settings synchronization..."

# VSCode -> Neovim sync
sync_vscode_to_neovim

# Neovim -> VSCode sync
sync_neovim_to_vscode

# VSCode settings sync
sync_editor_settings "$VSCODE_USER_DIR" "VSCode"

log "All settings synchronization completed. Please restart your editors to apply changes."

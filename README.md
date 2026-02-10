# dotfiles

Personal dotfiles managed with Nix, structured as independent flakes per OS.

## Repository Structure

This repository is organized into OS-specific directories, each with its own `flake.nix`:

- **`darwin/`** - macOS configuration (nix-darwin + home-manager)
- **`nixos/`** - NixOS configuration (system + home-manager)
- **`nixvim/`** - Standalone Neovim configuration (can be used independently)

Each directory is a complete, standalone flake that can be applied independently.

## Supported Architectures

| Architecture | nixpkgs | Status |
|--------------|---------|--------|
| Apple Silicon (aarch64-darwin) | unstable | ✅ Full support |
| Intel Mac (x86_64-darwin) | unstable | ✅ Full support |
| NixOS (x86_64-linux) | unstable | ✅ Full support |

## Quick Start

### macOS (darwin)

```bash
# Apply home-manager configuration
make home-manager-apply

# Apply nix-darwin system configuration
make nix-darwin-apply

# Update flake inputs
make flake-update-darwin
```

### NixOS

```bash
# Apply system configuration
make nixos-switch

# Update flake inputs
make flake-update-nixos
```

### Nixvim (Standalone)

```bash
# Run Neovim with nixvim config
nix run ./nixvim

# Update nixvim flake
make flake-update-nixvim
```

## Documentation

Documentation is available as Claude Code skills in `.claude/skills/`. These skills can be accessed by both humans and Claude AI:

**Setup & Installation:**
- `/installation` - Nix and dotfiles installation guide

**System & Package Management:**
- `/nix-operations` - Nix operations (home-manager, nix-darwin, package management)
- `/mise-guide` - Mise tool version management

**Languages & Runtimes:**
- `/languages-setup` - Language and runtime setup

**Editors & IDEs:**
- `/vscode-setup` - VSCode configuration
- `/cursor-setup` - Cursor AI editor setup (NixOS)
- `/nixos-keybindings` - NixOS keyboard shortcuts

**Tools & Utilities:**
- `/npm-tools` - NPM package management
- `/pre-commit-guide` - Pre-commit hooks
- `/atuin-guide` - Atuin shell history with SQLite
- `/zoxide-guide` - Zoxide smart directory navigation
- `/zellij-worktree` - Zellij git worktree workflow

**Services:**
- `/services-guide` - Yabai and skhd window management
- `/fileserver-guide` - NixOS file server with Tailscale
- `/gitserver-guide` - Git SSH server (NixOS)
- `/tailscale-acl` - Tailscale ACL configuration

**Cheatsheets:**
- `/hyprland-cheatsheet` - Hyprland shortcuts and configuration

### Usage

**In Claude Code:**
```bash
# Invoke skills directly
/installation
/nix-operations
/zellij-worktree

# Or ask naturally - Claude will reference them automatically
"How do I install Nix?"
"Show me zellij keybindings"
```

**Skills are also readable as markdown files** in `.claude/skills/*/SKILL.md`

## Screenshot Shortcuts

- GNOME: `Super+Shift+S` opens the built-in screenshot UI; use `Enter` for full screen or drag to capture a region.
- Hyprland: `Alt+Shift+S` captures a region and `Alt+Shift+D` captures the full screen via `hyprshot`, saving under `~/Pictures/Screenshots` and copying to the clipboard. PrintScreen bindings remain available if the key exists.

## Main Tools

### Package Management

- [nix](https://nixos.org/) - package manager
- [home-manager](https://github.com/nix-community/home-manager) - home manager
- [nix-darwin](https://github.com/LnL7/nix-darwin) - darwin system manager
- [mise](https://mise.jdx.dev/) - runtime and tool manager

### Development Tools

- [pre-commit](https://pre-commit.com/) - git hooks framework
- [gitleaks](https://github.com/gitleaks/gitleaks) - secret scanner
- [commitizen](https://github.com/commitizen/cz-cli) - commit convention tool
- [cz-git](https://github.com/Zhengqbbb/cz-git) - commitizen adapter

### Editors

- [neovim](https://neovim.io/) - editor
- [vscode](https://code.visualstudio.com/) - editor
- [cursor](https://www.cursor.com/) - editor

### Terminals

- [alacritty](https://github.com/alacritty/alacritty) - terminal
- [wezterm](https://github.com/wez/wezterm) - alternative terminal
- [ghostty](https://github.com/ghostty/ghostty) - terminal

### Terminal Multiplexers

- [zellij](https://github.com/zellij-org/zellij) - terminal multiplexer
- [tmux](https://github.com/tmux/tmux) - alternative terminal multiplexer

### Shell Tools

- [zsh](https://www.zsh.org/) - shell
- [starship](https://starship.rs/) - shell prompt
- [sheldon](https://github.com/rossmacarthur/sheldon) - plugin manager
- [atuin](https://github.com/atuinsh/atuin) - shell history

### Window Management

- [yabai](https://github.com/koekeishiya/yabai) - window manager
- [skhd](https://github.com/koekeishiya/skhd) - hotkey daemon

### Task Runner

- [make](https://www.gnu.org/software/make/) - task runner

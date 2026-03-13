---
name: services-guide
description: System services configuration guide including AeroSpace, JankyBorders, and AltTab on macOS
---

# Services Configuration

This document provides information about the macOS window-management stack configured in this repository: AeroSpace, JankyBorders, and AltTab.

**Note:** This guide is specific to macOS (darwin). For NixOS window management, see `/hyprland-cheatsheet` and `/nixos-keybindings`.

## Stack Overview

- [AeroSpace](https://nikitabobko.github.io/AeroSpace/guide) manages tiling, workspaces, and keybindings
- [JankyBorders](https://github.com/FelixKratz/JankyBorders) highlights the focused window
- [AltTab](https://alt-tab-macos.netlify.app/) provides a macOS app/window switcher with previews

## Installation and Setup

Packages are managed via Homebrew in `darwin/homebrew/default.nix`:

- `nikitabobko/tap/aerospace`
- `FelixKratz/formulae/borders`
- `alt-tab`

User configuration is managed via Home Manager:

- `darwin/home-manager/aerospace/aerospace.toml`
- `darwin/home-manager/borders/bordersrc`

Apply changes with:

```bash
make home-manager-apply
make nix-darwin-apply
```

## AeroSpace

- Runtime config: `~/.aerospace.toml`
- Source of truth in this repo: `darwin/home-manager/aerospace/aerospace.toml`

### Current Behavior

- Starts automatically at login
- Uses US keyboard key names such as `/`, `,`, `;`, `-`, `=`
- Default layout is `tiles`
- `alt + f` is not native fullscreen; it switches the current workspace into an accordion-style focused view

### Daily Usage

Use AeroSpace with these mental models:

- `alt + /` returns the current container to normal tiling
- `alt + ,` switches to accordion layout
- `alt + f` is a stable pseudo-fullscreen inside AeroSpace, not macOS native fullscreen
- `alt + shift + f` toggles the focused window between floating and tiling
- `alt + ;` enters service mode for less common operations

Common flows:

- Make one window effectively dominant: `alt + f`
- Return from pseudo-fullscreen to tiling: `alt + /`
- Clean up a messy workspace tree: `alt + ;`, then `r`
- Move a window to another workspace and follow it: `alt + shift + 1..9`
- Jump back to the previous workspace: `alt + tab`
- Use real macOS fullscreen: `alt + ;`, then `shift + f`

### Keyboard Shortcuts

Below are the primary shortcuts configured for AeroSpace in this repo.

#### Window Navigation

| Shortcut | Action |
|----------|--------|
| `alt + h` | Focus left |
| `alt + j` | Focus down |
| `alt + k` | Focus up |
| `alt + l` | Focus right |

#### Window Movement

| Shortcut | Action |
|----------|--------|
| `alt + shift + h` | Move window left |
| `alt + shift + j` | Move window down |
| `alt + shift + k` | Move window up |
| `alt + shift + l` | Move window right |

#### Workspaces

| Shortcut | Action |
|----------|--------|
| `alt + 1..9` | Switch to workspace 1..9 |
| `alt + shift + 1..9` | Move window to workspace 1..9 and follow it |
| `alt + tab` | Toggle between recent workspaces |

#### Layout and Resize

| Shortcut | Action |
|----------|--------|
| `alt + /` | Switch current container to tiles layout |
| `alt + ,` | Switch current container to accordion layout |
| `alt + f` | Flatten workspace tree and emphasize the focused window in accordion layout |
| `alt + shift + f` | Toggle floating / tiling |
| `alt + enter` | Open Ghostty |
| `alt + r` | Enter resize mode |
| `alt + ;` | Enter service mode |

#### Resize Mode

| Shortcut | Action |
|----------|--------|
| `h` / `l` | Resize width |
| `j` / `k` | Resize height |
| `shift + h/j/k/l` | Fine-grained resize |
| `esc` | Return to main mode |

#### Service Mode

| Shortcut | Action |
|----------|--------|
| `esc` | Reload config and return to main mode |
| `r` | Flatten workspace tree |
| `f` | Toggle floating / tiling |
| `shift + f` | Toggle macOS native fullscreen |
| `backspace` | Close all windows except current |
| `arrow keys` | Join with adjacent container |

### Fullscreen and Layout Notes

- `alt + f` is the recommended "focus one window" shortcut in this setup
- `alt + f` is intentionally implemented without AeroSpace `fullscreen`, because AeroSpace fullscreen can collapse when focus changes across workspaces
- To go back to ordinary tiling after `alt + f`, press `alt + /`
- To use true macOS fullscreen, enter service mode with `alt + ;` and press `shift + f`
- If a workspace feels structurally odd, run `alt + ;` then `r`, and then choose `alt + /` or `alt + ,` again

### Startup and Reload

This configuration enables automatic startup at login:

```toml
start-at-login = true
```

Typical maintenance flow:

```bash
# Apply dotfiles changes
make home-manager-apply
make nix-darwin-apply

# Reload AeroSpace config manually if needed
aerospace reload-config
```

## JankyBorders

- Runtime config: `~/.config/borders/bordersrc`
- Source of truth: `darwin/home-manager/borders/bordersrc`

Current settings:

- rounded borders
- width `4.0`
- HiDPI enabled
- pink-ish active color and blue inactive color inspired by the article setup

Manual restart if needed:

```bash
pkill borders || true
/opt/homebrew/bin/borders
```

## AltTab

AltTab is installed as a cask and used for app/window switching. Detailed preferences are not repo-managed yet.

Typical first-run steps:

1. Open `AltTab`
2. Grant Accessibility permission
3. Enable launch at login from AltTab preferences if desired

## Troubleshooting

- **AeroSpace keybindings do not work:** Check Accessibility permissions for AeroSpace
- **`aerospace reload-config` cannot connect to server:** Make sure `AeroSpace.app` is running, then reopen it if necessary
- **A window was pseudo-fullscreen and you want tiling back:** Press `alt + /`
- **A workspace looks split strangely after moving windows around:** Press `alt + ;`, then `r`, then reapply `alt + /` or `alt + ,`
- **Native fullscreen and AeroSpace layout feel inconsistent:** Prefer `alt + f` for normal use and reserve `alt + ;` + `shift + f` for apps that truly need macOS fullscreen
- **Borders are missing:** Restart `borders` and verify `~/.config/borders/bordersrc`
- **AltTab does not appear:** Open the app once manually and grant Accessibility permissions
- **Config changes do not apply:** Run `aerospace reload-config`; for border changes restart `borders`

### Verification

```bash
# Confirm packages are installed
brew list --cask | grep aerospace
brew list --cask | grep alt-tab
brew list --formula | grep borders

# Confirm managed config exists
ls -l ~/.aerospace.toml
ls -l ~/.config/borders/bordersrc
```

## Customization

To customize the setup:

1. Edit `darwin/home-manager/aerospace/aerospace.toml`
2. Edit `darwin/home-manager/borders/bordersrc` for border style/colors
3. Run `make home-manager-apply`
4. Reload AeroSpace or restart the affected process

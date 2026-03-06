# Windows Host UX (Mac-like)

This module standardizes the Windows host experience so daily operations feel close to the existing macOS setup.

## UX Goals

- Vim-like window movement/resizing on host desktop
- Fast app launcher workflow similar to Raycast
- Terminal look-and-feel aligned with Ghostty + Dracula + Hack Nerd Font
- Consistent key ergonomics: `Caps Lock -> Ctrl` always on
- Optional profile to map `Win -> Ctrl` for stronger Mac-like muscle memory

## Components

- Window manager: `komorebi`
- Hotkeys/remaps: `AutoHotkey v2`
- Launcher: `Flow Launcher`
- Search: `Everything`
- Quick preview: `QuickLook`
- Terminal: `Ghostty`

## Key Policy

- `Caps Lock -> Ctrl`: always enabled (`caps_as_ctrl=true`)
- `Win -> Ctrl`: toggle profile
  - `default`: off
  - `mac-like`: on
  - `safe-fallback`: off

Emergency shortcut (in AHK):

- `Ctrl + Alt + Pause`: suspend/resume AHK remaps

## Setup (PowerShell)

```powershell
cd path\to\dotfiles\windows-ctf\host-windows\scripts
.\bootstrap-host.ps1
```

## Daily Operations

Apply/re-apply settings:

```powershell
.\apply-host-settings.ps1
```

Enable Win->Ctrl (`mac-like` profile):

```powershell
.\toggle-win-ctrl-remap.ps1 -Mode on
```

Disable Win->Ctrl (`default`/`safe-fallback` profile):

```powershell
.\toggle-win-ctrl-remap.ps1 -Mode off
```

Verify host UX state:

```powershell
.\verify-host.ps1
```

## Notes

- This module intentionally keeps `Caps Lock -> Ctrl` always on.
- If `Win -> Ctrl` is on, Windows-native shortcuts like `Win+R` are unavailable until toggled off.
- If komorebi is not installed or not running, AHK keybindings still load; only window commands fail.

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
- Terminal: `Ghostty` (optional) / `Windows Terminal` (required fallback)
- Agent IDE: `Orca` (Windows UI + WSL Kali agents)
- Agent runtime: `Herdr` (separate native Windows and Kali WSL installs)

## Key Policy

- `Caps Lock -> Ctrl`: always enabled (`caps_as_ctrl=true`)
- `Win -> Ctrl`: toggle profile
  - `default`: off
  - `mac-like`: on
  - `safe-fallback`: off

Emergency shortcut (in AHK):

- `Ctrl + Alt + Pause`: suspend/resume AHK remaps

## Setup (PowerShell)

**初回のみ**: デフォルト設定ではスクリプト実行が無効なため、事前に以下を実行してください。

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

その後：

```powershell
cd path\to\dotfiles\windows-ctf\host-windows\scripts
.\bootstrap-host.ps1
```

`bootstrap-host.ps1` installs the native Windows Herdr build on its stable
channel. Install or update only Herdr with:

```powershell
.\install-herdr.ps1
herdr
```

Kali WSL has a separate installation, managed from the Linux side with
`make install-herdr`. Windows and WSL keep independent Herdr sessions and
configuration.

## Orca + WSL Kali

The recommended daily setup is the native Windows Orca app using agent CLIs
installed inside the `kali-linux` WSL distro. `bootstrap-host.ps1` installs Orca
through `winget`; `bootstrap-wsl-kali.sh` installs Codex and the other npm-based
agent tools through mise.

To install only Orca on Windows, run:

```powershell
winget install --id StablyAI.Orca --exact
```

1. Confirm the distro name and agent command from PowerShell:

   ```powershell
   wsl --list --quiet
   wsl -d kali-linux -- bash -lc 'command -v codex'
   ```

2. Start Orca and open **Settings -> Terminal**. Select WSL and `kali-linux`
   for the default shell.
3. Open the account switcher, add a Codex account hosted in WSL, and select
   `kali-linux`. Complete `codex login` when prompted.
4. Add a repository from the Kali filesystem using its UNC path, for example:

   ```text
   \\wsl.localhost\kali-linux\home\<user>\git_repos\github.com\<owner>\<repo>
   ```

Orca then keeps its UI on Windows while `git`, terminals, and the selected
agent run in Kali. If Orca cannot find Codex, run `make install-mise` inside
`windows-ctf/`, restart Orca, and check **Settings -> Agents** for the detected
path.

For a standalone Kali desktop or VMware guest, install the Linux AppImage
instead:

```bash
cd ~/git_repos/github.com/barleytea/dotfiles/windows-ctf
make install-orca
orca-ide
```

The same command works under WSLg, but the Windows-hosted UI is preferred for
the normal WSL workflow. The installed `orca-ide` launcher automatically uses
AppImage extraction mode when WSL does not provide `/dev/fuse`.

Do not run `sudo apt install orca`: that package is the GNOME screen reader,
not this agent IDE. Orca intentionally names its Linux command `orca-ide` to
avoid that conflict. Also prefer the Windows app for account credentials under
WSL; without an unlocked GNOME Keyring or KWallet, the Linux app warns that its
locally stored secrets are not encrypted.

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
- In `manifests/apps-winget.txt`, lines prefixed with `?` are optional packages.

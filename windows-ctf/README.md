# Windows CTF Environment (WSL2 + VMware Kali)

This directory provides a dual-layer CTF environment for ThinkPad + Windows and a Mac-like host UX profile.

- Daily workflow: Kali on WSL2
- Isolation/repro workflow: Kali on VMware (single VM + snapshots)
- Host UX workflow: Windows tuned with Ghostty + komorebi + AutoHotkey + Flow Launcher

## Topology

1. Windows 11 Home host (Mac-like UX profile)
2. WSL2 Kali for fast daily operations
3. VMware Kali for risky binaries and rollback-based testing

Orca runs natively on Windows for the daily workflow and launches Codex from
the Kali WSL distro. A standalone AppImage installer is also provided for the
VMware Kali desktop or WSLg.

## Prerequisites

Before running scripts, prepare the Windows host:

1. Install `VMware Workstation Pro` on Windows (required, not bundled by this repo).
2. Enable CPU virtualization in BIOS/UEFI (Intel VT-x / AMD-V).
3. Keep enough resources for dual usage (recommended: RAM 32GB, SSD 200GB+ for CTF assets).
4. Prepare Kali image for VMware (official ISO or prebuilt virtual image).

Notes for Windows 11 + WSL2 coexistence:

- VMware can run with Hyper-V/VBS enabled, but performance may degrade depending on host settings.
- If VM performance is poor, review virtualization security settings and measure tradeoffs before changing them.

## Directory Layout

```text
windows-ctf/
├── Makefile
├── README.md
├── host-windows/
│   ├── README.md
│   ├── manifests/
│   │   └── apps-winget.txt
│   ├── config/
│   │   ├── ahk/
│   │   ├── komorebi/
│   │   ├── ghostty/
│   │   └── flow-launcher/
│   └── scripts/
│       ├── bootstrap-host.ps1
│       ├── apply-host-settings.ps1
│       ├── verify-host.ps1
│       ├── toggle-win-ctrl-remap.ps1
│       └── set-caps-ctrl.ps1
├── manifests/
│   ├── all.txt
│   ├── core.txt
│   ├── web.txt
│   ├── pwn.txt
│   ├── rev.txt
│   ├── forensics.txt
│   └── gui.txt
└── scripts/
    ├── setup-host.ps1
    ├── install-manifest.sh
    ├── install-docker.sh
    ├── install-gh.sh
    ├── install-herdr.sh
    ├── install-orca.sh
    ├── bootstrap-wsl-kali.sh
    ├── bootstrap-vm-kali.sh
    ├── sync-dotfiles.sh
    └── verify-environment.sh
```

## Bootstrap Flow

### 0) Host UX setup (Windows, PowerShell)

**初回のみ**: デフォルト設定ではスクリプト実行が無効なため、事前に以下を実行してください。

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

その後：

```powershell
cd path\to\dotfiles\windows-ctf\host-windows\scripts
.\bootstrap-host.ps1
```

This installs host-side UX tools via `winget`, enforces `Caps Lock -> Ctrl`,
applies host configs, and verifies status.
It also installs Orca. See the
[Windows host guide](host-windows/README.md#orca--wsl-kali) for connecting it
to Codex inside `kali-linux`.

### 1) WSL feature setup (Windows, Administrator PowerShell)

```powershell
cd path\to\dotfiles\windows-ctf\scripts
.\setup-host.ps1
```

This enables WSL2 prerequisites and attempts `wsl --install -d kali-linux`.
It does **not** install VMware itself.

### 2) WSL Kali setup

```bash
cd ~/git_repos/github.com/barleytea/dotfiles/windows-ctf
make bootstrap-wsl
make sync-dotfiles
make verify-environment
```

`make bootstrap-wsl` now installs Docker Engine and Docker Compose for Kali on WSL2.
If you only need Docker later, run:

```bash
cd ~/git_repos/github.com/barleytea/dotfiles/windows-ctf
make install-docker
newgrp docker
docker run hello-world
```

Install or update GitHub CLI independently with:

```bash
make install-gh
gh auth login
```

This uses GitHub CLI's official apt repository because Kali's configured apt
snapshot does not provide the `gh` package.

### Herdr on Windows and Kali WSL

The two bootstrap flows install separate Herdr binaries so native Windows
agents and Kali WSL agents can each use local persistent sessions:

```powershell
# Windows host
cd path\to\dotfiles\windows-ctf\host-windows\scripts
.\install-herdr.ps1
herdr
```

```bash
# Kali WSL
cd ~/git_repos/github.com/barleytea/dotfiles/windows-ctf
make install-herdr
herdr
```

The Windows installer uses Herdr's stable channel. The Kali installer places
the executable in `~/.local/bin`, which this repository adds to `PATH`.
Each installation has its own sessions and configuration; they are not shared
automatically across the Windows/WSL boundary.

If your WSL distro has systemd enabled, the bootstrap uses `systemctl enable --now docker`.
Otherwise it falls back to `service docker start`.

### Bash plugins and inline suggestions

The Bash environment uses Sheldon as its plugin manager. Its declarative
configuration is stored in `config/sheldon/plugins.toml`.

`ble.sh` provides inline command suggestions while typing. Atuin automatically
registers its history as a suggestion source when `ble.sh` is active. Accept a
suggestion with the right arrow, `Ctrl+F`, or `End`.

Install or refresh the shell tools and activate the configuration with:

```bash
cd ~/git_repos/github.com/barleytea/dotfiles/windows-ctf
make setup-bash
exec bash
```

The fzf integration is loaded through the `ble.sh` integration modules to
avoid replacing its line editor bindings.

### 3) VMware Kali setup

```bash
cd ~/git_repos/github.com/barleytea/dotfiles/windows-ctf
make bootstrap-vm
make sync-dotfiles
make verify-environment
```

VMware application setup checklist (Windows side):

1. Install VMware Workstation Pro.
2. Create a Kali VM from ISO/image.
3. Assign CPU/RAM/Disk (suggested start: 4 vCPU, 8-12GB RAM, 100GB disk).
4. Install/enable VMware Tools (`open-vm-tools-desktop` in guest).

Install the native Linux Orca app in the guest when you want the full UI there:

```bash
make install-orca
orca-ide
```

The launcher automatically falls back to AppImage extraction mode when FUSE
is unavailable, including WSL installations without `/dev/fuse`.
Use `orca-ide`, not `orca ide`; Kali's `orca` apt package is the unrelated
GNOME screen reader.

After `bootstrap-vm`, create snapshots in VMware:

1. `baseline-clean`
2. `ctf-ready`

## Host Key Policy

- `Caps Lock -> Ctrl`: always enabled.
- `Win -> Ctrl`: toggle profile for stronger Mac-like muscle memory.
  - `on`: `mac-like`
  - `off`: `default` / `safe-fallback`

Use:

```powershell
cd path\to\dotfiles\windows-ctf\host-windows\scripts
.\toggle-win-ctrl-remap.ps1 -Mode on
.\toggle-win-ctrl-remap.ps1 -Mode off
```

## Manifests (Kali)

- `core.txt`: common base tools for both environments
- `web.txt`: web security tooling
- `pwn.txt`: binary exploitation tooling
- `rev.txt`: reverse engineering tooling
- `forensics.txt`: forensics tooling
- `gui.txt`: GUI-focused tools used in WSLg/VM desktop
- `all.txt`: composition entrypoint using `@manifest` includes

Install selected categories:

```bash
bash ./scripts/install-manifest.sh core web pwn
```

Install full stack:

```bash
bash ./scripts/install-manifest.sh all
```

## Operating Policy

- Run unknown binaries in VMware first.
- Use WSL for daily solve scripts and lightweight tasks.
- Switch VMware networking to Host-only for high-risk investigations.
- Keep secrets on host password manager, not long-lived inside VM images.
- Take snapshot before each CTF event or dangerous test.

## Acceptance Checklist

- Host UX scripts pass (`verify-host.ps1`) and key policy behaves as expected.
- WSL and VMware Kali both boot and can reach network.
- `make verify-environment` passes in both Linux environments.
- WSL GUI tools launch via WSLg.
- Orca launches on Windows and detects the Codex installation in `kali-linux`.
- VMware snapshots can restore to `ctf-ready` quickly.

## CI Coverage

`windows-ctf/**` changes trigger `.github/workflows/windows-host.yml` on PR/push.
This workflow checks:

- PowerShell parse errors (`*.ps1`)
- PowerShell lint (`PSScriptAnalyzer`, Error severity gate)
- JSON config validity
- AHK key policy (`CapsLock::Ctrl` and emergency suspend hotkey)
- winget package IDs in `host-windows/manifests/apps-winget.txt`

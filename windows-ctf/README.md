# Windows CTF Environment (WSL2 + VMware Kali)

This directory provides a dual-layer CTF environment for ThinkPad + Windows and a Mac-like host UX profile.

- Daily workflow: Kali on WSL2
- Isolation/repro workflow: Kali on VMware (single VM + snapshots)
- Host UX workflow: Windows tuned with Ghostty + komorebi + AutoHotkey + Flow Launcher

## Topology

1. Windows 11 Home host (Mac-like UX profile)
2. WSL2 Kali for fast daily operations
3. VMware Kali for risky binaries and rollback-based testing

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

This installs host-side UX tools via `winget`, enforces `Caps Lock -> Ctrl`, applies host configs, and verifies status.

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
- VMware snapshots can restore to `ctf-ready` quickly.

## CI Coverage

`windows-ctf/**` changes trigger `.github/workflows/windows-host.yml` on PR/push.
This workflow checks:

- PowerShell parse errors (`*.ps1`)
- PowerShell lint (`PSScriptAnalyzer`, Error severity gate)
- JSON config validity
- AHK key policy (`CapsLock::Ctrl` and emergency suspend hotkey)
- winget package IDs in `host-windows/manifests/apps-winget.txt`

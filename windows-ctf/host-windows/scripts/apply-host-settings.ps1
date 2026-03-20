Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootDir = Split-Path -Parent $scriptDir
$configDir = Join-Path $rootDir 'config'
$statePath = Join-Path $configDir 'ahk/state.json'
$generatedAhkPath = Join-Path $configDir 'ahk/keymap.generated.ahk'

$ghosttyDir = Join-Path $env:APPDATA 'ghostty'
$flowDir = Join-Path $env:APPDATA 'FlowLauncher/Settings'
$komorebiDir = Join-Path $env:USERPROFILE '.config/komorebi'
$startupDir = Join-Path $env:APPDATA 'Microsoft/Windows/Start Menu/Programs/Startup'

if (-not (Test-Path $statePath)) {
  throw "AHK state file not found: $statePath"
}

$state = Get-Content $statePath | ConvertFrom-Json
if (-not $state.caps_as_ctrl) {
  throw 'caps_as_ctrl must remain true by policy. Use set-caps-ctrl.ps1 to repair.'
}

New-Item -ItemType Directory -Force -Path $ghosttyDir | Out-Null
New-Item -ItemType Directory -Force -Path $flowDir | Out-Null
New-Item -ItemType Directory -Force -Path $komorebiDir | Out-Null
New-Item -ItemType Directory -Force -Path $startupDir | Out-Null

Copy-Item (Join-Path $configDir 'ghostty/config') (Join-Path $ghosttyDir 'config') -Force
Copy-Item (Join-Path $configDir 'flow-launcher/settings.json') (Join-Path $flowDir 'Settings.json') -Force
Copy-Item (Join-Path $configDir 'komorebi/komorebi.json') (Join-Path $komorebiDir 'komorebi.json') -Force

$wtSettingsSrc = Join-Path $configDir 'windows-terminal/settings.json'
$wtPaths = @(
    (Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState'),
    (Join-Path $env:LOCALAPPDATA 'Microsoft\Windows Terminal')
)
foreach ($p in $wtPaths) {
    if (Test-Path $p) {
        Copy-Item $wtSettingsSrc (Join-Path $p 'settings.json') -Force
        Write-Host "  Windows Terminal settings applied to: $p"
    }
}

$base = Get-Content (Join-Path $configDir 'ahk/keymap.base.ahk') -Raw
$winMap = if ($state.win_as_ctrl) {
  Get-Content (Join-Path $configDir 'ahk/winctrl.on.ahk') -Raw
} else {
  Get-Content (Join-Path $configDir 'ahk/winctrl.off.ahk') -Raw
}

$generated = @(
  '; AUTO-GENERATED. DO NOT EDIT DIRECTLY.'
  "; profile: $($state.profile)"
  $base
  $winMap
) -join "`r`n"

Set-Content -Path $generatedAhkPath -Value $generated -Encoding UTF8

$startupAhk = Join-Path $startupDir 'windows-ctf-keymap.ahk'
Copy-Item $generatedAhkPath $startupAhk -Force

# Restart AHK with the generated script.
# Step 1: WM_CLOSE (0x10) で AHK に OnExit フックを実行させてから終了させる
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public class WinMsg {
    [DllImport("user32.dll")]
    public static extern bool PostMessage(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam);
}
'@ -ErrorAction SilentlyContinue

$ahkProcs = @(
    Get-Process AutoHotkey64 -ErrorAction SilentlyContinue
    Get-Process AutoHotkey   -ErrorAction SilentlyContinue
) | Where-Object { $_ -ne $null }

foreach ($proc in $ahkProcs) {
    if ($proc.MainWindowHandle -ne [IntPtr]::Zero) {
        [WinMsg]::PostMessage($proc.MainWindowHandle, 0x0010, [IntPtr]::Zero, [IntPtr]::Zero) | Out-Null
    }
}

# Step 2: グレースフルな終了を最大 2 秒待つ
$deadline = (Get-Date).AddSeconds(2)
while ((Get-Date) -lt $deadline) {
    $still = @(
        Get-Process AutoHotkey64 -ErrorAction SilentlyContinue
        Get-Process AutoHotkey   -ErrorAction SilentlyContinue
    ) | Where-Object { $_ -ne $null }
    if (-not $still) { break }
    Start-Sleep -Milliseconds 200
}

# Step 3: 残存プロセスを強制終了（フォールバック）
Get-Process AutoHotkey64 -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Get-Process AutoHotkey   -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

$ahkCmd = Get-Command AutoHotkey64.exe -ErrorAction SilentlyContinue
$ahkExe = if ($ahkCmd) { $ahkCmd.Source } else { $null }
if (-not $ahkExe) {
  $ahkCmd = Get-Command AutoHotkey.exe -ErrorAction SilentlyContinue
  $ahkExe = if ($ahkCmd) { $ahkCmd.Source } else { $null }
}
if (-not $ahkExe) {
  $candidates = @(
    'C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe'
    'C:\Program Files\AutoHotkey\v2\AutoHotkey.exe'
    'C:\Program Files\AutoHotkey\AutoHotkey64.exe'
    'C:\Program Files\AutoHotkey\AutoHotkey.exe'
  )
  foreach ($c in $candidates) {
    if (Test-Path $c) { $ahkExe = $c; break }
  }
}
if ($ahkExe) {
  Start-Process -FilePath $ahkExe -ArgumentList @($generatedAhkPath)
} else {
  Write-Warning 'AutoHotkey executable not found. Install AutoHotkey then re-run apply-host-settings.ps1.'
}

# komorebi is intentionally disabled. Uncomment to re-enable.
# $komorebiCmd = Get-Command komorebic -ErrorAction SilentlyContinue
# if ($komorebiCmd) {
#   try { & $komorebiCmd.Source stop | Out-Null } catch {}
#   try { & $komorebiCmd.Source start --config (Join-Path $komorebiDir 'komorebi.json') | Out-Null } catch {
#     Write-Warning "komorebi start failed: $($_.Exception.Message)"
#   }
# } else {
#   Write-Warning 'komorebic command not found. Install komorebi then re-run apply-host-settings.ps1.'
# }

# Font check
$fontInstalled = (Test-Path (Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts\HackNerdFont-Regular.ttf')) -or
                 (Test-Path (Join-Path $env:WINDIR 'Fonts\HackNerdFont-Regular.ttf'))
if (-not $fontInstalled) {
  Write-Warning 'Hack Nerd Font is not installed. Run: .\scripts\install-fonts.ps1'
}

Write-Host "Applied host settings (profile=$($state.profile), caps_as_ctrl=$($state.caps_as_ctrl), win_as_ctrl=$($state.win_as_ctrl))."

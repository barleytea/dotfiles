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
Get-Process AutoHotkey64 -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Get-Process AutoHotkey  -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

$ahkExe = (Get-Command AutoHotkey64.exe -ErrorAction SilentlyContinue)?.Source
if (-not $ahkExe) {
  $ahkExe = (Get-Command AutoHotkey.exe -ErrorAction SilentlyContinue)?.Source
}
if ($ahkExe) {
  Start-Process -FilePath $ahkExe -ArgumentList @($generatedAhkPath)
} else {
  Write-Warning 'AutoHotkey executable not found. Install AutoHotkey then re-run apply-host-settings.ps1.'
}

# Start/restart komorebi if available.
$komorebiCmd = Get-Command komorebic -ErrorAction SilentlyContinue
if ($komorebiCmd) {
  try { & $komorebiCmd.Source stop | Out-Null } catch {}
  try { & $komorebiCmd.Source start --config (Join-Path $komorebiDir 'komorebi.json') | Out-Null } catch {
    Write-Warning "komorebi start failed: $($_.Exception.Message)"
  }
} else {
  Write-Warning 'komorebic command not found. Install komorebi then re-run apply-host-settings.ps1.'
}

Write-Host "Applied host settings (profile=$($state.profile), caps_as_ctrl=$($state.caps_as_ctrl), win_as_ctrl=$($state.win_as_ctrl))."

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootDir = Split-Path -Parent $scriptDir
$configDir = Join-Path $rootDir 'config'
$statePath = Join-Path $configDir 'ahk/state.json'
$generatedAhkPath = Join-Path $configDir 'ahk/keymap.generated.ahk'

$errors = 0

function Test-RequiredCommand {
  param([string]$Name)
  if (Get-Command $Name -ErrorAction SilentlyContinue) {
    Write-Host "[OK] command: $Name"
  } else {
    Write-Host "[NG] command missing: $Name"
    $script:errors++
  }
}

function Test-RequiredPath {
  param([string]$PathValue)
  if (Test-Path $PathValue) {
    Write-Host "[OK] path: $PathValue"
  } else {
    Write-Host "[NG] path missing: $PathValue"
    $script:errors++
  }
}

Test-RequiredCommand winget
Test-RequiredCommand AutoHotkey64.exe
Test-RequiredCommand komorebic

Test-RequiredPath $statePath
Test-RequiredPath $generatedAhkPath
Test-RequiredPath (Join-Path $env:APPDATA 'ghostty/config')
Test-RequiredPath (Join-Path $env:APPDATA 'FlowLauncher/Settings/Settings.json')
Test-RequiredPath (Join-Path $env:USERPROFILE '.config/komorebi/komorebi.json')
Test-RequiredPath (Join-Path $env:APPDATA 'Microsoft/Windows/Start Menu/Programs/Startup/windows-ctf-keymap.ahk')

if (Test-Path $statePath) {
  $state = Get-Content $statePath | ConvertFrom-Json
  if ($state.caps_as_ctrl -eq $true) {
    Write-Host '[OK] caps_as_ctrl is enabled'
  } else {
    Write-Host '[NG] caps_as_ctrl is disabled (policy violation)'
    $errors++
  }
}

if ($errors -gt 0) {
  throw "verify-host failed with $errors issue(s)."
}

Write-Host 'verify-host passed.'

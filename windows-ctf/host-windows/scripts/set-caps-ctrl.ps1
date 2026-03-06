Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootDir = Split-Path -Parent $scriptDir
$statePath = Join-Path $rootDir 'config/ahk/state.json'

if (-not (Test-Path $statePath)) {
  throw "State file not found: $statePath"
}

$state = Get-Content $statePath | ConvertFrom-Json
$state.caps_as_ctrl = $true
if (-not $state.profile) {
  $state.profile = 'default'
}

$state | ConvertTo-Json | Set-Content -Path $statePath -Encoding UTF8
Write-Host 'Caps Lock -> Ctrl is enforced in state.'

param(
  [Parameter(Mandatory = $true)]
  [ValidateSet('on', 'off')]
  [string]$Mode
)

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
$state.win_as_ctrl = ($Mode -eq 'on')
$state.profile = if ($Mode -eq 'on') { 'mac-like' } else { 'default' }

$state | ConvertTo-Json | Set-Content -Path $statePath -Encoding UTF8

& (Join-Path $scriptDir 'apply-host-settings.ps1') | Out-Host
Write-Host "Win->Ctrl remap is now: $Mode"

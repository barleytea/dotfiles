Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootDir = Split-Path -Parent $scriptDir
$manifestPath = Join-Path $rootDir 'manifests/apps-winget.txt'

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
  throw 'winget is not available. Install App Installer from Microsoft Store first.'
}

Write-Host '==> Installing Windows host UX apps via winget'
$ids = Get-Content $manifestPath | Where-Object {
  $line = $_.Trim()
  $line -and -not $line.StartsWith('#')
}

foreach ($id in $ids) {
  Write-Host "--> $id"
  try {
    winget install --id $id --accept-package-agreements --accept-source-agreements --silent --disable-interactivity | Out-Host
  }
  catch {
    Write-Warning "winget install failed for $id (continuing): $($_.Exception.Message)"
  }
}

Write-Host '==> Applying host settings'
& (Join-Path $scriptDir 'set-caps-ctrl.ps1') | Out-Host
& (Join-Path $scriptDir 'apply-host-settings.ps1') | Out-Host

Write-Host '==> Verifying host settings'
& (Join-Path $scriptDir 'verify-host.ps1') | Out-Host

Write-Host 'Bootstrap complete.'

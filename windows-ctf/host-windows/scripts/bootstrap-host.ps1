Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootDir = Split-Path -Parent $scriptDir
$manifestPath = Join-Path $rootDir 'manifests/apps-winget.txt'

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
  throw 'winget is not available. Install App Installer from Microsoft Store first.'
}

Write-Host '==> Installing Windows host UX apps via winget'
$entries = Get-Content $manifestPath | ForEach-Object {
  $line = $_.Trim()
  if (-not $line -or $line.StartsWith('#')) { return }
  [pscustomobject]@{
    Optional = $line.StartsWith('?')
    Id = if ($line.StartsWith('?')) { $line.Substring(1) } else { $line }
  }
}

foreach ($entry in $entries) {
  $id = $entry.Id
  Write-Host "--> $id"
  try {
    winget install --id $id --accept-package-agreements --accept-source-agreements --silent --disable-interactivity | Out-Host
  }
  catch {
    if ($entry.Optional) {
      Write-Warning "Optional package install failed for $id (continuing): $($_.Exception.Message)"
    } else {
      Write-Warning "Required package install failed for $id (continuing): $($_.Exception.Message)"
    }
  }
}

Write-Host '==> Applying host settings'
& (Join-Path $scriptDir 'set-caps-ctrl.ps1') | Out-Host
& (Join-Path $scriptDir 'apply-host-settings.ps1') | Out-Host

Write-Host '==> Verifying host settings'
& (Join-Path $scriptDir 'verify-host.ps1') | Out-Host

Write-Host 'Bootstrap complete.'

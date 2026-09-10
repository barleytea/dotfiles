Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$installUrl = 'https://herdr.dev/install.ps1'

Write-Host '==> Installing/updating Herdr for Windows (stable channel)'
$installScript = Invoke-RestMethod -Uri $installUrl -UseBasicParsing
$installBlock = [ScriptBlock]::Create([string]$installScript)
& $installBlock -Channel stable

$herdr = Get-Command herdr -ErrorAction SilentlyContinue
if ($null -eq $herdr) {
  throw 'Herdr was installed, but herdr is not available in this PowerShell session.'
}

& $herdr.Source --version
Write-Host "==> Herdr installed: $($herdr.Source)"

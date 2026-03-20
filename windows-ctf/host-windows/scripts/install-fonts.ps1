Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$fontName = 'HackNerdFont-Regular.ttf'
$fontDisplayName = 'Hack Nerd Font'
$downloadUrl = 'https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/Hack.zip'
$zipPath = Join-Path $env:TEMP 'HackNerdFont.zip'
$extractPath = Join-Path $env:TEMP 'HackNerdFont'

function Test-FontInstalled {
  $registryPath = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'
  $fonts = Get-ItemProperty -Path $registryPath -ErrorAction SilentlyContinue
  if ($fonts.PSObject.Properties.Name -like "*Hack Nerd Font*") { return $true }
  return Test-Path (Join-Path $env:WINDIR "Fonts\$fontName")
}

if (Test-FontInstalled) {
  Write-Host "[OK] $fontDisplayName is already installed."
  exit 0
}

Write-Host "==> Downloading $fontDisplayName ..."
Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath -UseBasicParsing

Write-Host '==> Extracting ...'
if (Test-Path $extractPath) { Remove-Item $extractPath -Recurse -Force }
Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force

Write-Host '==> Installing fonts (current user) ...'
$shell = New-Object -ComObject Shell.Application
$fontsFolder = $shell.Namespace(0x14)
Get-ChildItem -Path $extractPath -Include '*.ttf', '*.otf' -Recurse | ForEach-Object {
  $dest = Join-Path $env:WINDIR "Fonts\$($_.Name)"
  if (-not (Test-Path $dest)) {
    $fontsFolder.CopyHere($_.FullName, 0x10)
  }
}

Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
Remove-Item $extractPath -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "[OK] $fontDisplayName installed."

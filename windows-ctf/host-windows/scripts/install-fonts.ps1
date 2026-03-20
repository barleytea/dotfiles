Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$fontDisplayName = 'Hack Nerd Font'
$downloadUrl = 'https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/Hack.zip'
$zipPath = Join-Path $env:TEMP 'HackNerdFont.zip'
$extractPath = Join-Path $env:TEMP 'HackNerdFont'
$userFontsDir = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts'
$systemFontsDir = Join-Path $env:WINDIR 'Fonts'
$regPath = 'HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'

function Test-FilesExist {
  return (Test-Path (Join-Path $userFontsDir 'HackNerdFont-Regular.ttf')) -or
         (Test-Path (Join-Path $systemFontsDir 'HackNerdFont-Regular.ttf'))
}

function Test-RegistryExists {
  $reg = Get-ItemProperty $regPath -ErrorAction SilentlyContinue
  return $reg -and ($reg.PSObject.Properties.Name -like '*HackNerdFont*')
}

function Register-Fonts {
  New-Item -ItemType Directory -Force -Path $userFontsDir | Out-Null
  Get-ChildItem -Path $userFontsDir -Filter 'HackNerdFont*.ttf' | ForEach-Object {
    $displayName = [System.IO.Path]::GetFileNameWithoutExtension($_.Name) + ' (TrueType)'
    Set-ItemProperty -Path $regPath -Name $displayName -Value $_.FullName -ErrorAction SilentlyContinue
  }
  Write-Host '✓ Font registry entries added.'
}

$filesExist = Test-FilesExist
$regExists = Test-RegistryExists

if ($filesExist -and $regExists) {
  Write-Host "[OK] $fontDisplayName is already installed and registered."
  exit 0
}

if (-not $filesExist) {
  Write-Host "==> Downloading $fontDisplayName ..."
  Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath -UseBasicParsing

  Write-Host '==> Extracting ...'
  if (Test-Path $extractPath) { Remove-Item $extractPath -Recurse -Force }
  Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force

  Write-Host '==> Copying font files ...'
  New-Item -ItemType Directory -Force -Path $userFontsDir | Out-Null
  Get-ChildItem -Path $extractPath -Include '*.ttf', '*.otf' -Recurse | ForEach-Object {
    Copy-Item $_.FullName (Join-Path $userFontsDir $_.Name) -Force
  }

  Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
  Remove-Item $extractPath -Recurse -Force -ErrorAction SilentlyContinue
  Write-Host '✓ Font files installed.'
}

if (-not $regExists) {
  Write-Host '==> Registering fonts in HKCU ...'
  Register-Fonts
}

Write-Host "[OK] $fontDisplayName installed. Restart Windows Terminal to apply."

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$fontDisplayName = 'Hack Nerd Font'
$downloadUrl = 'https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/Hack.zip'
$zipPath = Join-Path $env:TEMP 'HackNerdFont.zip'
$extractPath = Join-Path $env:TEMP 'HackNerdFont'
$userFontsDir = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts'
$systemFontsDir = Join-Path $env:WINDIR 'Fonts'

function Test-FontInstalled {
  return (Test-Path (Join-Path $userFontsDir 'HackNerdFont-Regular.ttf')) -or
         (Test-Path (Join-Path $systemFontsDir 'HackNerdFont-Regular.ttf'))
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
New-Item -ItemType Directory -Force -Path $userFontsDir | Out-Null
$regPath = 'HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'

Get-ChildItem -Path $extractPath -Include '*.ttf', '*.otf' -Recurse | ForEach-Object {
  $dest = Join-Path $userFontsDir $_.Name
  if (-not (Test-Path $dest)) {
    Copy-Item $_.FullName $dest -Force
    # レジストリに登録（アプリがフォント名で検索できるよう）
    $displayName = [System.IO.Path]::GetFileNameWithoutExtension($_.Name) + ' (TrueType)'
    Set-ItemProperty -Path $regPath -Name $displayName -Value $dest -ErrorAction SilentlyContinue
  }
}

Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
Remove-Item $extractPath -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "[OK] $fontDisplayName installed. Restart terminal apps to apply."

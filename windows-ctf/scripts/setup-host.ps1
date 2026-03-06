#requires -RunAsAdministrator

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Host '==> Enabling required Windows features for WSL2'
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart | Out-Host
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart | Out-Host

Write-Host '==> Setting WSL2 as default version'
wsl --set-default-version 2

Write-Host '==> Installing Kali (if not installed)'
try {
    wsl --install -d kali-linux
} catch {
    Write-Host 'Kali might already be installed. Continuing...'
}

Write-Host '==> Done. Reboot Windows if this is the first WSL setup.'
Write-Host 'VMware Workstation Pro should be installed separately via official installer.'

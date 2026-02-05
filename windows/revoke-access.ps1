# OpenClaw Windows Organizer - Revoke Access Script
# Run as Administrator: .\revoke-access.ps1

param(
    [string]$AgentUser = "agent"
)

Write-Host "============================================" -ForegroundColor Red
Write-Host "  OpenClaw Access Revocation" -ForegroundColor Red
Write-Host "============================================" -ForegroundColor Red
Write-Host ""

$confirm = Read-Host "This will permanently revoke AI agent access. Continue? (yes/no)"
if ($confirm -ne "yes") {
    Write-Host "Aborted." -ForegroundColor Yellow
    exit
}

Write-Host ""
Write-Host "[1/5] Stopping SSH service..." -ForegroundColor Cyan
wsl -u root service ssh stop 2>$null

Write-Host "[2/5] Removing agent user from WSL..." -ForegroundColor Cyan
wsl -u root userdel -r $AgentUser 2>$null

Write-Host "[3/5] Removing port forwarding rules..." -ForegroundColor Cyan
netsh interface portproxy delete v4tov4 listenport=2222 listenaddress=0.0.0.0 2>$null

Write-Host "[4/5] Removing firewall rules..." -ForegroundColor Cyan
Remove-NetFirewallRule -DisplayName "*WSL SSH*" -ErrorAction SilentlyContinue
Remove-NetFirewallRule -DisplayName "*Tailscale Only*" -ErrorAction SilentlyContinue
Remove-NetFirewallRule -DisplayName "*OpenClaw*" -ErrorAction SilentlyContinue

Write-Host "[5/5] Removing startup script..." -ForegroundColor Cyan
$startupPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\start-ssh.vbs"
if (Test-Path $startupPath) {
    Remove-Item $startupPath -Force
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "  Access Revoked Successfully" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "The AI agent can no longer access this PC."
Write-Host "To restore access, run the setup script again."

# Runs the keep-alive check now, then every minute, forever.
# Started hidden at login by the shortcut in the Windows Startup folder.
$ErrorActionPreference = 'SilentlyContinue'
$created = $false
$mutex = New-Object System.Threading.Mutex($true, 'Local\EscapeDigitalRoomWatchdog', [ref]$created)
if (-not $created) { exit }
$dir = 'C:\Users\ASUS\Documents\Default Project'
while ($true) {
  & (Join-Path $dir 'keep_public_link.ps1')
  Start-Sleep -Seconds 60
}

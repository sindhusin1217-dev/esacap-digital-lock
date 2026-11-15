# Keeps the Escape the Digital Room game server and public link running.
# Started hidden at login by "Escape Digital Room (permanent link).vbs".
#
# Priority:
#   1. srv.us fixed link  (no account, same address every time) - srvus_enabled.txt
#   2. ngrok fixed link   (needs a valid free authtoken)       - ngrok_enabled.txt
#   3. Cloudflare quick tunnel (temporary address fallback)
$ErrorActionPreference = 'SilentlyContinue'
$dir = 'C:\Users\ASUS\Documents\Default Project'
Set-Location $dir
$log = Join-Path $dir 'keep_public_link.log'

function Write-Log([string]$msg) {
  Add-Content -Path $log -Value ('[' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') + '] ' + $msg)
}

# 1) Game server on port 8000
$listening = Get-NetTCPConnection -LocalPort 8000 -State Listen -ErrorAction SilentlyContinue
if (-not $listening) {
  $py = (Get-Command python).Source
  if ($py) {
    Start-Process -FilePath $py -ArgumentList '-u', 'server.py' -WorkingDirectory $dir -WindowStyle Hidden `
      -RedirectStandardOutput (Join-Path $dir 'server.log') `
      -RedirectStandardError (Join-Path $dir 'server.err')
    Write-Log 'server.py was not running - started it (hidden)'
    Start-Sleep -Seconds 3
    if (Get-NetTCPConnection -LocalPort 8000 -State Listen -ErrorAction SilentlyContinue) {
      Write-Log 'server is listening on port 8000'
    } else {
      Write-Log 'server did not start - see server.err'
    }
  } else {
    Write-Log 'python was not found - could not start the server'
  }
}

$oldLink = ''
if (Test-Path (Join-Path $dir 'public_link.txt')) {
  $oldLink = (Get-Content (Join-Path $dir 'public_link.txt') -Raw).Trim()
}
$permanent = $false

# 2) srv.us fixed link (free, no account, stable URL from the SSH key)
$srvusEnabled = Join-Path $dir 'srvus_enabled.txt'
if (Test-Path $srvusEnabled) {
  $sshProc = Get-CimInstance Win32_Process -Filter "Name = 'ssh.exe'" | Where-Object { $_.CommandLine -like '*srv.us*' }
  if (-not $sshProc) {
    Remove-Item (Join-Path $dir 'srvus.log') -ErrorAction SilentlyContinue
    Start-Process -FilePath 'ssh.exe' `
      -ArgumentList '-i', 'serveo_key', '-o', 'StrictHostKeyChecking=no', '-o', 'UserKnownHostsFile=NUL', '-o', 'ExitOnForwardFailure=yes', '-o', 'ServerAliveInterval=30', '-o', 'ServerAliveCountMax=3', '-R', '1:127.0.0.1:8000', 'srv.us' `
      -WorkingDirectory $dir -WindowStyle Hidden `
      -RedirectStandardOutput (Join-Path $dir 'srvus.log') `
      -RedirectStandardError (Join-Path $dir 'srvus.err')
    Write-Log 'srv.us tunnel was not running - started it'
  }
  $u = $null
  for ($i = 0; $i -lt 40; $i++) {
    Start-Sleep -Milliseconds 500
    if (Test-Path (Join-Path $dir 'srvus.log')) {
      $m = Select-String -Path (Join-Path $dir 'srvus.log') -Pattern 'https://[a-z0-9]+\.srv\.us/?' | Select-Object -First 1
      if ($m) { $u = $m.Matches[0].Value; break }
    }
  }
  if (-not $u -and (Test-Path (Join-Path $dir 'srvus_url.txt'))) {
    $u = (Get-Content (Join-Path $dir 'srvus_url.txt') -Raw).Trim()
  }
  if ($u) {
    Set-Content -Path (Join-Path $dir 'public_link.txt') -Value $u
    Set-Content -Path (Join-Path $dir 'srvus_url.txt') -Value $u
    if ($u -ne $oldLink) {
      try { Set-Clipboard -Value $u } catch {}
      Write-Log ('permanent link: ' + $u)
    }
    Get-Process cloudflared, ngrok -ErrorAction SilentlyContinue | Stop-Process -Force
    $permanent = $true
  } else {
    Write-Log 'srv.us did not start - using a quick tunnel meanwhile'
  }
}

# 3) ngrok fixed link (only when srv.us is not enabled)
if (-not $permanent -and (Test-Path (Join-Path $dir 'ngrok_enabled.txt')) -and (Test-Path (Join-Path $dir 'ngrok.exe'))) {
  $ngrokProc = Get-CimInstance Win32_Process -Filter "Name = 'ngrok.exe'" | Where-Object { $_.CommandLine -like '*8000*' }
  if (-not $ngrokProc) {
    Start-Process -FilePath (Join-Path $dir 'ngrok.exe') `
      -ArgumentList 'http', '8000', '--log=stdout' `
      -WorkingDirectory $dir -WindowStyle Hidden `
      -RedirectStandardOutput (Join-Path $dir 'ngrok.log') `
      -RedirectStandardError (Join-Path $dir 'ngrok.err')
    Write-Log 'ngrok was not running - started it'
  }
  for ($i = 0; $i -lt 40; $i++) {
    Start-Sleep -Milliseconds 500
    try {
      $api = Invoke-RestMethod -Uri 'http://127.0.0.1:4040/api/tunnels' -TimeoutSec 2
      $t = @($api.tunnels) | Where-Object { $_.public_url -like 'https://*' } | Select-Object -First 1
      if ($t) {
        Set-Content -Path (Join-Path $dir 'public_link.txt') -Value $t.public_url
        if ($t.public_url -ne $oldLink) {
          try { Set-Clipboard -Value $t.public_url } catch {}
          Write-Log ('ngrok link: ' + $t.public_url)
        }
        Get-Process cloudflared -ErrorAction SilentlyContinue | Stop-Process -Force
        $permanent = $true
        break
      }
    } catch {}
  }
  if (-not $permanent) {
    Get-CimInstance Win32_Process -Filter "Name = 'ngrok.exe'" | Where-Object { $_.CommandLine -like '*8000*' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force }
    Write-Log 'ngrok did not start (check the authtoken) - using a quick tunnel meanwhile'
  }
}

# 4) Cloudflare quick tunnel (temporary fallback)
if (-not $permanent) {
  $cf = Get-Process cloudflared -ErrorAction SilentlyContinue
  if (-not $cf) {
    Remove-Item (Join-Path $dir 'tunnel.log'), (Join-Path $dir 'tunnel.out') -ErrorAction SilentlyContinue
    Start-Process -FilePath 'cmd.exe' `
      -ArgumentList '/c', 'cloudflared.exe tunnel --url http://127.0.0.1:8000 --no-autoupdate >tunnel.out 2>tunnel.log' `
      -WorkingDirectory $dir -WindowStyle Hidden
    Write-Log 'cloudflared was not running - started a new quick tunnel'

    $u = $null
    for ($i = 0; $i -lt 120; $i++) {
      Start-Sleep -Milliseconds 500
      if (Test-Path (Join-Path $dir 'tunnel.log')) {
        $m = Select-String -Path (Join-Path $dir 'tunnel.log') -Pattern 'https://[a-z0-9-]+\.trycloudflare\.com' -AllMatches | Select-Object -First 1
        if ($m) { $u = $m.Matches[0].Value; break }
      }
    }
    if ($u) {
      Set-Content -Path (Join-Path $dir 'public_link.txt') -Value $u
      if ($u -ne $oldLink) {
        try { Set-Clipboard -Value $u } catch {}
        Write-Log ('new quick link: ' + $u)
      }
    } else {
      Write-Log 'could not read the tunnel URL (will retry shortly)'
    }
  } else {
    # Already running: make sure the link file shows its current address.
    if (Test-Path (Join-Path $dir 'tunnel.log')) {
      $m = Select-String -Path (Join-Path $dir 'tunnel.log') -Pattern 'https://[a-z0-9-]+\.trycloudflare\.com' -AllMatches | Select-Object -First 1
      if ($m) { Set-Content -Path (Join-Path $dir 'public_link.txt') -Value $m.Matches[0].Value }
    }
  }
}

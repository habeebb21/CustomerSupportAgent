# n8n + ngrok Startup Script
# Run once after booting - handles everything automatically.

Set-StrictMode -Off
Set-Location $PSScriptRoot

function Write-Step { param([string]$msg) Write-Host "[n8n] $msg" -ForegroundColor Cyan }
function Write-OK   { param([string]$msg) Write-Host "[ OK ] $msg" -ForegroundColor Green }
function Write-Fail { param([string]$msg) Write-Host "[FAIL] $msg" -ForegroundColor Red }

Write-Step "Stopping any existing containers..."
docker compose down --remove-orphans 2>$null

Write-Step "Removing any leftover standalone containers..."
docker rm -f n8n 2>$null
docker rm -f n8n_ngrok 2>$null

Write-Step "Starting ngrok tunnel..."
docker compose up -d ngrok

Write-Step "Waiting for ngrok public URL (up to 60s)..."
$url = $null
$tries = 0
while (-not $url -and $tries -lt 30) {
    $tries++
    Start-Sleep -Seconds 2
    try {
        $resp = Invoke-RestMethod -Uri "http://localhost:4040/api/tunnels" -ErrorAction Stop
        $t = $resp.tunnels | Where-Object { $_.proto -eq "https" } | Select-Object -First 1
        if ($t) { $url = $t.public_url }
    } catch {}
}

if (-not $url) {
    Write-Fail "Could not get ngrok URL. Check http://localhost:4040"
    exit 1
}
Write-OK "Public URL: $url"

Write-Step "Writing .env with public URL..."
"WEBHOOK_URL=$url" | Out-File -FilePath ".env" -Encoding ascii -NoNewline

Write-Step "Starting n8n with public webhook URL..."
docker compose up -d n8n

Write-Step "Waiting for n8n to be ready (up to 60s)..."
for ($i = 0; $i -lt 20; $i++) {
    Start-Sleep -Seconds 3
    try {
        $h = Invoke-WebRequest -Uri "http://localhost:5678/healthz" -UseBasicParsing -TimeoutSec 3 -ErrorAction Stop
        if ($h.StatusCode -eq 200) { break }
    } catch {}
}

Write-Host ""
Write-Host "=========================================================" -ForegroundColor Yellow
Write-Host "  n8n is READY" -ForegroundColor Green
Write-Host "=========================================================" -ForegroundColor Yellow
Write-Host "  Local  : http://localhost:5678"
Write-Host "  Public : $url" -ForegroundColor Green
Write-Host "  ngrok  : http://localhost:4040"
Write-Host "=========================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "Paste the Public URL as WEBHOOK_URL in any external service."
Write-Host "To stop everything run stop.bat"

# PowerShell script to start NLP Service
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Starting NLP Service for Movie Search" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if Python is installed
try {
    $pythonVersion = python --version 2>&1
    Write-Host "[OK] Python found: $pythonVersion" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Python is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install Python 3.8 or higher" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""
Write-Host "[1/3] Checking dependencies..." -ForegroundColor Yellow

# Check if fastapi is installed
try {
    pip show fastapi | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] Dependencies already installed" -ForegroundColor Green
    }
} catch {
    Write-Host "[INFO] Installing dependencies..." -ForegroundColor Yellow
    pip install -r requirements.txt
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERROR] Failed to install dependencies" -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }
}

Write-Host ""
Write-Host "[2/3] Testing NLP algorithms..." -ForegroundColor Yellow
python test_nlp_algorithms.py
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] NLP algorithms test failed" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""
Write-Host "[3/3] Getting network information..." -ForegroundColor Yellow

# Get IP address
$ipAddresses = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.IPAddress -notlike "127.*" -and $_.IPAddress -notlike "169.254.*"} | Select-Object -ExpandProperty IPAddress)
$mainIP = $ipAddresses[0]  # Lấy IP đầu tiên (thường là IP chính)

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Network Information:" -ForegroundColor Cyan
Write-Host "  Your IP Address: $mainIP" -ForegroundColor Yellow
Write-Host "  Port: 8002" -ForegroundColor Yellow
Write-Host ""
Write-Host "IMPORTANT: Update IP in Flutter app!" -ForegroundColor Red
Write-Host "  File: lib/services/nlp_api_service.dart" -ForegroundColor Yellow
Write-Host "  Change: baseUrl = 'http://$mainIP:8002'" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

# Set port environment variable
$env:NLP_PORT = "8002"

Write-Host "[4/4] Starting NLP Service on port 8002..." -ForegroundColor Yellow
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "NLP Service is running!" -ForegroundColor Green
Write-Host "Local: http://localhost:8002" -ForegroundColor Cyan
Write-Host "Network: http://$mainIP:8002" -ForegroundColor Cyan
Write-Host "API Docs: http://$mainIP:8002/docs" -ForegroundColor Cyan
Write-Host "Health: http://$mainIP:8002/health" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Press Ctrl+C to stop the service" -ForegroundColor Yellow
Write-Host ""

python nlp_service.py

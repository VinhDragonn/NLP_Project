# Script để lấy IP WiFi hiện tại và cập nhật vào .env
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Getting WiFi IP Address" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Lấy IP của adapter WiFi đang kết nối
$wifiAdapter = Get-NetAdapter | Where-Object {$_.Name -like "*Wi-Fi*" -or $_.Name -like "*WiFi*" -or $_.InterfaceDescription -like "*Wi-Fi*"} | Where-Object {$_.Status -eq "Up"} | Select-Object -First 1

if ($wifiAdapter) {
    $wifiIP = Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias $wifiAdapter.Name | Where-Object {$_.IPAddress -notlike "127.*" -and $_.IPAddress -notlike "169.254.*"} | Select-Object -First 1 -ExpandProperty IPAddress
    
    if ($wifiIP) {
        Write-Host "✅ WiFi IP found: $wifiIP" -ForegroundColor Green
        Write-Host ""
        Write-Host "Updating .env file..." -ForegroundColor Yellow
        
        # Đọc file .env hiện tại
        $envContent = @()
        $nlpUrlUpdated = $false
        
        if (Test-Path .env) {
            $envLines = Get-Content .env
            foreach ($line in $envLines) {
                if ($line -match '^NLP_URL=') {
                    $envContent += "NLP_URL=`"http://$wifiIP:8002`""
                    $nlpUrlUpdated = $true
                } elseif ($line -match '^ML_URL=') {
                    # Giữ nguyên ML_URL hoặc cập nhật nếu cần
                    $envContent += $line
                } else {
                    $envContent += $line
                }
            }
        }
        
        # Nếu chưa có NLP_URL, thêm vào
        if (-not $nlpUrlUpdated) {
            $envContent += "NLP_URL=`"http://$wifiIP:8002`""
        }
        
        # Ghi lại file .env
        $envContent | Set-Content .env -Encoding UTF8
        
        Write-Host "✅ .env file updated!" -ForegroundColor Green
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "Current Configuration:" -ForegroundColor Cyan
        Write-Host "  WiFi IP: $wifiIP" -ForegroundColor Yellow
        Write-Host "  NLP URL: http://$wifiIP:8002" -ForegroundColor Yellow
        Write-Host "========================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "⚠️  IMPORTANT: Restart Flutter app to load new IP!" -ForegroundColor Red
        Write-Host ""
    } else {
        Write-Host "❌ Could not find IP address for WiFi adapter" -ForegroundColor Red
    }
} else {
    Write-Host "❌ WiFi adapter not found or not connected" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please ensure:" -ForegroundColor Yellow
    Write-Host "  1. WiFi is turned on" -ForegroundColor Yellow
    Write-Host "  2. Connected to mobile hotspot" -ForegroundColor Yellow
    Write-Host "  3. Internet connection is active" -ForegroundColor Yellow
}

Read-Host "Press Enter to exit"


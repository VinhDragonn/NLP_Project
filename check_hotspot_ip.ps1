# Script kiểm tra IP khi kết nối vào hotspot
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Kiểm tra IP khi kết nối Hotspot" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "⚠️  QUAN TRỌNG:" -ForegroundColor Yellow
Write-Host "   1. Đảm bảo điện thoại đã BẬT WiFi Hotspot" -ForegroundColor White
Write-Host "   2. Đảm bảo laptop đã KẾT NỐI vào WiFi hotspot đó" -ForegroundColor White
Write-Host "   3. Ngắt kết nối WiFi khác (nếu có)" -ForegroundColor White
Write-Host ""

Read-Host "Nhấn Enter sau khi đã kết nối vào hotspot..."

Write-Host ""
Write-Host "Đang kiểm tra IP WiFi..." -ForegroundColor Yellow
Write-Host ""

# Lấy tất cả IP của adapter WiFi
$wifiIPs = Get-NetIPAddress -AddressFamily IPv4 | Where-Object {
    ($_.InterfaceAlias -like "*Wi-Fi*" -or $_.InterfaceAlias -like "*WiFi*") -and
    $_.IPAddress -notlike "127.*" -and 
    $_.IPAddress -notlike "169.254.*"
} | Select-Object IPAddress, InterfaceAlias, PrefixOrigin

if ($wifiIPs) {
    Write-Host "✅ Tìm thấy IP WiFi:" -ForegroundColor Green
    Write-Host ""
    foreach ($ip in $wifiIPs) {
        Write-Host "   IP: $($ip.IPAddress)" -ForegroundColor Cyan
        Write-Host "   Adapter: $($ip.InterfaceAlias)" -ForegroundColor Gray
        Write-Host "   Source: $($ip.PrefixOrigin)" -ForegroundColor Gray
        Write-Host ""
    }
    
    $mainIP = $wifiIPs[0].IPAddress
    
    # Kiểm tra xem có phải IP hotspot không (thường là 192.168.43.x hoặc 192.168.44.x)
    if ($mainIP -like "192.168.43.*" -or $mainIP -like "192.168.44.*" -or $mainIP -like "192.168.137.*") {
        Write-Host "✅ Phát hiện IP Hotspot: $mainIP" -ForegroundColor Green
    } else {
        Write-Host "⚠️  IP này có thể không phải từ Hotspot" -ForegroundColor Yellow
        Write-Host "   Hotspot thường có IP dạng: 192.168.43.x hoặc 192.168.44.x" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "IP để dùng trong .env:" -ForegroundColor Cyan
    Write-Host "  NLP_URL=`"http://$mainIP:8002`"" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    
    # Hỏi có muốn cập nhật vào .env không
    $update = Read-Host "Có muốn cập nhật vào file .env? (Y/N)"
    if ($update -eq "Y" -or $update -eq "y") {
        # Đọc file .env
        $envContent = @()
        $nlpUrlUpdated = $false
        
        if (Test-Path .env) {
            $envLines = Get-Content .env
            foreach ($line in $envLines) {
                if ($line -match '^NLP_URL=') {
                    $envContent += "NLP_URL=`"http://$mainIP:8002`""
                    $nlpUrlUpdated = $true
                } else {
                    $envContent += $line
                }
            }
        }
        
        if (-not $nlpUrlUpdated) {
            $envContent += "NLP_URL=`"http://$mainIP:8002`""
        }
        
        $envContent | Set-Content .env -Encoding UTF8
        Write-Host ""
        Write-Host "✅ Đã cập nhật vào file .env!" -ForegroundColor Green
        Write-Host ""
        Write-Host "⚠️  Nhớ restart Flutter app để load IP mới!" -ForegroundColor Red
    }
} else {
    Write-Host "❌ Không tìm thấy IP WiFi!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Vui lòng kiểm tra:" -ForegroundColor Yellow
    Write-Host "  1. WiFi đã bật chưa?" -ForegroundColor White
    Write-Host "  2. Đã kết nối vào hotspot chưa?" -ForegroundColor White
    Write-Host "  3. Thử chạy: ipconfig" -ForegroundColor White
}

Write-Host ""
Read-Host "Nhấn Enter để thoát"


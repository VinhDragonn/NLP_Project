# Script kiểm tra IP khi kết nối USB Tethering từ điện thoại
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Kiểm tra IP USB Tethering" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "⚠️  QUAN TRỌNG:" -ForegroundColor Yellow
Write-Host "   1. Đảm bảo điện thoại đã BẬT USB Tethering" -ForegroundColor White
Write-Host "   2. Đảm bảo cáp USB đã kết nối laptop" -ForegroundColor White
Write-Host "   3. Đảm bảo laptop đã nhận kết nối (có icon mạng)" -ForegroundColor White
Write-Host ""

Read-Host "Nhấn Enter sau khi đã kết nối USB tethering..."

Write-Host ""
Write-Host "Đang tìm adapter USB/Ethernet..." -ForegroundColor Yellow
Write-Host ""

# Tìm tất cả adapter Ethernet đang kết nối (loại trừ VMware, TAP, Virtual)
$ethernetAdapters = Get-NetAdapter | Where-Object {
    ($_.PhysicalMediaType -like "*802.3*" -or 
     $_.InterfaceDescription -like "*Ethernet*" -or
     $_.InterfaceDescription -like "*USB*" -or
     $_.Name -like "*Ethernet*" -or
     $_.Name -like "*Local Area Connection*") -and
    $_.Status -eq "Up" -and
    $_.InterfaceDescription -notlike "*VMware*" -and
    $_.InterfaceDescription -notlike "*Virtual*" -and
    $_.InterfaceDescription -notlike "*TAP*"
}

if (-not $ethernetAdapters) {
    Write-Host "❌ Không tìm thấy adapter Ethernet/USB đang kết nối!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Đang liệt kê tất cả adapter để kiểm tra:" -ForegroundColor Yellow
    Get-NetAdapter | Where-Object {$_.Status -eq "Up"} | Select-Object Name, InterfaceDescription, Status | Format-Table -AutoSize
    Write-Host ""
    Write-Host "Vui lòng kiểm tra:" -ForegroundColor Yellow
    Write-Host "  1. USB tethering đã bật trên điện thoại chưa?" -ForegroundColor White
    Write-Host "  2. Cáp USB đã cắm chưa?" -ForegroundColor White
    Write-Host "  3. Windows đã nhận kết nối chưa?" -ForegroundColor White
    Read-Host "Nhấn Enter để thoát"
    exit
}

Write-Host "✅ Tìm thấy adapter:" -ForegroundColor Green
$ethernetAdapters | Select-Object Name, InterfaceDescription, Status | Format-Table -AutoSize
Write-Host ""

# Lấy IP của adapter đầu tiên (thường là adapter chính)
$mainAdapter = $ethernetAdapters | Select-Object -First 1
$ethernetIPs = Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias $mainAdapter.Name | Where-Object {
    $_.IPAddress -notlike "127.*" -and 
    $_.IPAddress -notlike "169.254.*"
} | Select-Object IPAddress, InterfaceAlias

if ($ethernetIPs) {
    Write-Host "✅ Tìm thấy IP của adapter $($mainAdapter.Name):" -ForegroundColor Green
    Write-Host ""
    foreach ($ip in $ethernetIPs) {
        Write-Host "   IP: $($ip.IPAddress)" -ForegroundColor Cyan
        Write-Host "   Adapter: $($ip.InterfaceAlias)" -ForegroundColor Gray
        Write-Host ""
    }
    
    $mainIP = $ethernetIPs[0].IPAddress
    
    # IP USB tethering thường là 192.168.42.x hoặc 192.168.43.x
    if ($mainIP -like "192.168.*") {
        Write-Host "✅ Phát hiện IP USB Tethering: $mainIP" -ForegroundColor Green
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
        } else {
            # Nếu không có file .env, tạo mới với các key cần thiết
            $envContent = @(
                'apikey=""',
                'ML_URL=""',
                "NLP_URL=`"http://$mainIP:8002`""
            )
            $nlpUrlUpdated = $true
        }
        
        if (-not $nlpUrlUpdated) {
            $envContent += "NLP_URL=`"http://$mainIP:8002`""
        }
        
        $envContent | Set-Content .env -Encoding UTF8
        Write-Host ""
        Write-Host "✅ Đã cập nhật vào file .env!" -ForegroundColor Green
        Write-Host ""
        Write-Host "📋 Nội dung file .env:" -ForegroundColor Cyan
        Get-Content .env | ForEach-Object { Write-Host "   $_" -ForegroundColor Gray }
        Write-Host ""
        Write-Host "⚠️  QUAN TRỌNG: Restart Flutter app để load IP mới!" -ForegroundColor Red
    }
} else {
    Write-Host "❌ Không tìm thấy IP cho adapter này!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Vui lòng kiểm tra:" -ForegroundColor Yellow
    Write-Host "  1. Adapter đã được cấu hình IP chưa?" -ForegroundColor White
    Write-Host "  2. Chạy: ipconfig để xem chi tiết" -ForegroundColor White
}

Write-Host ""
Read-Host "Nhan Enter de thoat"


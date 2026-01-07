# Script don gian de lay IP USB Tethering
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Tim IP USB Tethering" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Tim tat ca adapter dang ket noi (loai tru VMware, Virtual)
$allAdapters = Get-NetAdapter | Where-Object {
    $_.Status -eq "Up" -and
    $_.InterfaceDescription -notlike "*VMware*" -and
    $_.InterfaceDescription -notlike "*Virtual*" -and
    $_.InterfaceDescription -notlike "*TAP*" -and
    $_.Name -notlike "*VMware*"
}

Write-Host "Cac adapter dang ket noi:" -ForegroundColor Yellow
$allAdapters | Select-Object Name, InterfaceDescription | Format-Table -AutoSize
Write-Host ""

# Lay IP cua tat ca adapter
$foundIP = $null
foreach ($adapter in $allAdapters) {
    $ips = Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias $adapter.Name | Where-Object {
        $_.IPAddress -notlike "127.*" -and 
        $_.IPAddress -notlike "169.254.*" -and
        $_.IPAddress -notlike "192.168.40.*" -and  # VMware VMnet1
        $_.IPAddress -notlike "192.168.231.*"      # VMware VMnet8
    }
    
    if ($ips) {
        foreach ($ip in $ips) {
            Write-Host "IP tim thay:" -ForegroundColor Green
            Write-Host "  Adapter: $($adapter.Name)" -ForegroundColor Cyan
            Write-Host "  IP: $($ip.IPAddress)" -ForegroundColor Yellow
            Write-Host ""
            
            # IP USB tethering thuong la 192.168.42.x hoac 192.168.43.x
            if ($ip.IPAddress -like "192.168.*") {
                $foundIP = $ip.IPAddress
                Write-Host "  -> Day co the la IP USB Tethering!" -ForegroundColor Green
            }
        }
    }
}

if ($foundIP) {
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "IP de dung: $foundIP" -ForegroundColor Yellow
    Write-Host "NLP_URL=`"http://$foundIP:8002`"" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    
    $update = Read-Host "Cap nhat vao file .env? (Y/N)"
    if ($update -eq "Y" -or $update -eq "y") {
        # Doc file .env
        $envContent = @()
        $nlpUrlUpdated = $false
        
        if (Test-Path .env) {
            $envLines = Get-Content .env
            foreach ($line in $envLines) {
                if ($line -match '^NLP_URL=') {
                    $envContent += "NLP_URL=`"http://$foundIP:8002`""
                    $nlpUrlUpdated = $true
                } else {
                    $envContent += $line
                }
            }
        } else {
            $envContent = @(
                'apikey=""',
                'ML_URL=""',
                "NLP_URL=`"http://$foundIP:8002`""
            )
            $nlpUrlUpdated = $true
        }
        
        if (-not $nlpUrlUpdated) {
            $envContent += "NLP_URL=`"http://$foundIP:8002`""
        }
        
        $envContent | Set-Content .env -Encoding UTF8
        Write-Host ""
        Write-Host "Da cap nhat vao file .env!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Noi dung file .env:" -ForegroundColor Cyan
        Get-Content .env
    }
} else {
    Write-Host ""
    Write-Host "Khong tim thay IP hop le!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Vui long kiem tra:" -ForegroundColor Yellow
    Write-Host "  1. USB tethering da bat chua?" -ForegroundColor White
    Write-Host "  2. Cap USB da cam chua?" -ForegroundColor White
    Write-Host "  3. Chay: ipconfig de xem chi tiet" -ForegroundColor White
}

Write-Host ""
Read-Host "Nhan Enter de thoat"


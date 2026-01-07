# 📱 Hướng dẫn kết nối khi điện thoại phát WiFi Hotspot

## 🔍 Bước 1: Kiểm tra IP của laptop khi kết nối vào hotspot

Khi laptop kết nối vào WiFi hotspot của điện thoại, bạn cần lấy IP của laptop (không phải IP của điện thoại).

### Cách 1: Dùng PowerShell (Khuyên dùng)
```powershell
# Chạy trong PowerShell
Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.InterfaceAlias -like "*Wi-Fi*"} | Select-Object IPAddress, InterfaceAlias
```

### Cách 2: Dùng ipconfig
```cmd
ipconfig
```
Tìm dòng "IPv4 Address" của adapter "Wi-Fi" hoặc "Wireless LAN adapter"

### Cách 3: Tự động cập nhật
```powershell
# Chạy script tự động
.\get_wifi_ip.ps1
```

## 📝 Bước 2: Cập nhật IP vào file .env

Sau khi có IP (ví dụ: `192.168.43.150`), mở file `.env` và sửa:

```
NLP_URL="http://192.168.43.150:8002"
```

**Lưu ý:** 
- Thay `192.168.43.150` bằng IP thực tế của laptop
- Port phải là `8002` (port của NLP service)

## 🚀 Bước 3: Chạy NLP Service

```powershell
cd ml_backend
python nlp_service.py
```

Hoặc dùng script:
```powershell
.\ml_backend\start_nlp_service.ps1
```

## ✅ Bước 4: Kiểm tra kết nối

1. **Từ laptop:** Mở browser và truy cập: `http://localhost:8002/health`
2. **Từ điện thoại:** Mở browser và truy cập: `http://[IP_LAPTOP]:8002/health`
   - Ví dụ: `http://192.168.43.150:8002/health`

## 🔧 Troubleshooting

### IP thay đổi mỗi lần kết nối?
- Hotspot Android thường cấp IP động
- Mỗi lần kết nối lại, chạy lại script `get_wifi_ip.ps1` để cập nhật IP mới

### Không kết nối được?
1. **Kiểm tra firewall:**
   ```powershell
   # Cho phép Python qua firewall
   New-NetFirewallRule -DisplayName "Python NLP Service" -Direction Inbound -LocalPort 8002 -Protocol TCP -Action Allow
   ```

2. **Kiểm tra server có chạy không:**
   ```powershell
   netstat -ano | findstr :8002
   ```

3. **Kiểm tra cùng mạng:**
   - Đảm bảo điện thoại và laptop cùng mạng WiFi (hotspot)
   - Đảm bảo hotspot đang bật

4. **Test từ điện thoại:**
   - Mở browser trên điện thoại
   - Truy cập: `http://[IP_LAPTOP]:8002/health`
   - Nếu thấy `{"status":"ok"}` là thành công!

## 📌 Lưu ý quan trọng

1. **IP của điện thoại phát hotspot:**
   - Thường là `192.168.43.1` hoặc `192.168.44.1` (Android)
   - **KHÔNG dùng IP này** trong Flutter app

2. **IP của laptop trong mạng hotspot:**
   - Thường là `192.168.43.x` hoặc `192.168.44.x` (x là số từ 2-254)
   - **Dùng IP này** trong file .env

3. **Flutter app tự động đọc từ .env:**
   - File `lib/services/nlp_api_service.dart` đã được cấu hình đọc từ `.env`
   - Chỉ cần cập nhật `.env` và restart app

## 🎯 Tóm tắt

```
Điện thoại (phát hotspot) 
    ↓
Laptop kết nối vào hotspot → Nhận IP (ví dụ: 192.168.43.150)
    ↓
Cập nhật IP vào .env: NLP_URL="http://192.168.43.150:8002"
    ↓
Chạy Python server: python nlp_service.py
    ↓
Flutter app đọc IP từ .env → Kết nối thành công! ✅
```


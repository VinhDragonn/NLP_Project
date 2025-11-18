# Android Studio - NLP Backend Setup

## Cách 1: Sử dụng Script (Đơn giản nhất)

### Bước 1: Chạy Backend
Double-click file: `start_nlp_backend.bat`

### Bước 2: Chạy Flutter
Nhấn nút Run (▶️) trong Android Studio như bình thường

---

## Cách 2: Tích hợp External Tool (Tự động)

### Bước 1: Thêm External Tool
1. Mở Android Studio
2. **File** → **Settings** (hoặc `Ctrl + Alt + S`)
3. **Tools** → **External Tools**
4. Click **+** (Add)
5. Điền thông tin:
   - **Name**: `Start NLP Backend`
   - **Description**: `Start NLP Backend Server on port 8002`
   - **Program**: `python`
   - **Arguments**: `nlp_service.py`
   - **Working directory**: `C:\Users\vinh0\Documents\movie_DO_AN\ml_backend`
   - **Environment variables**: `NLP_PORT=8002`
6. Click **OK**

### Bước 2: Sử dụng
1. **Tools** → **External Tools** → **Start NLP Backend**
2. Backend sẽ chạy trong terminal riêng
3. Sau đó nhấn Run Flutter như bình thường

---

## Cách 3: Tạo Run Configuration (Chuyên nghiệp)

### Bước 1: Tạo Compound Configuration
1. Click dropdown Run/Debug configurations (bên cạnh nút ▶️)
2. Click **Edit Configurations...**
3. Click **+** → **Compound**
4. **Name**: `Flutter + NLP Backend`
5. Click **+** → Chọn configuration Flutter hiện tại
6. Click **OK**

### Bước 2: Chạy Backend thủ công
- Vẫn phải chạy backend thủ công bằng `start_nlp_backend.bat`
- Sau đó chọn configuration `Flutter + NLP Backend` và Run

---

## Cách 4: Tạo Batch File All-in-One (Khuyến nghị!)

### File đã tạo: `run_with_backend.bat`

### Sử dụng:
1. Double-click `run_with_backend.bat`
2. Backend sẽ tự động chạy trong cửa sổ riêng
3. Sau 3 giây, chạy Flutter app trong Android Studio
4. Khi xong, nhấn phím bất kỳ trong cửa sổ batch để tắt backend

---

## 🎯 Khuyến nghị cho Android Studio:

### Option A: Nhanh nhất
```
1. Double-click: start_nlp_backend.bat
2. Nhấn Run trong Android Studio
```

### Option B: Tự động nhất
```
1. Double-click: run_with_backend.bat
2. Đợi 3 giây
3. Nhấn Run trong Android Studio
```

---

## 🔧 Troubleshooting

### Lỗi: Backend không chạy
- Kiểm tra Python đã cài đặt: `python --version`
- Kiểm tra dependencies: `pip install -r requirements.txt`

### Lỗi: Port 8002 đã được sử dụng
```powershell
# Tìm process đang dùng port 8002
netstat -ano | findstr :8002

# Kill process (thay PID bằng số từ lệnh trên)
taskkill /PID <PID> /F
```

### Lỗi: Flutter không kết nối được backend
- Kiểm tra IP trong `nlp_api_service.dart`:
  ```dart
  final String baseUrl = 'http://192.168.100.219:8002';
  ```
- Chạy `ipconfig` để lấy IP mới nếu đổi mạng

---

## 📱 Chạy trên thiết bị thật

1. Kết nối điện thoại qua USB
2. Bật USB Debugging
3. Chạy backend: `start_nlp_backend.bat`
4. Kiểm tra IP máy tính: `ipconfig`
5. Cập nhật IP trong `nlp_api_service.dart`
6. Run Flutter app

---

## ⚡ Shortcut

Tạo shortcut trên Desktop:
1. Right-click `start_nlp_backend.bat`
2. **Send to** → **Desktop (create shortcut)**
3. Đổi tên: "Start NLP Backend"
4. Đổi icon (optional)

Bây giờ chỉ cần double-click shortcut trên Desktop! 🚀

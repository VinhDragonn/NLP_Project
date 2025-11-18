# 🚀 Hướng Dẫn Deploy NLP Backend Lên Cloud

## Vấn đề hiện tại:
- ❌ Phải chạy Python trên máy tính
- ❌ Tắt máy tính = mất chức năng tìm kiếm
- ❌ Phải cùng mạng WiFi

## Giải pháp:
✅ Deploy backend lên cloud server
✅ Chạy 24/7 miễn phí
✅ Không cần máy tính
✅ Hoạt động mọi lúc, mọi nơi

---

# Cách 1: Render.com (Khuyến nghị - Dễ nhất)

## Bước 1: Tạo tài khoản Render
1. Truy cập: https://render.com
2. Click **Get Started** → Sign up với GitHub
3. Xác nhận email

## Bước 2: Push code lên GitHub
```bash
# Trong thư mục movie_DO_AN
git init
git add .
git commit -m "Add NLP backend"

# Tạo repo mới trên GitHub: https://github.com/new
# Tên repo: movie-nlp-backend

git remote add origin https://github.com/YOUR_USERNAME/movie-nlp-backend.git
git push -u origin main
```

## Bước 3: Deploy trên Render
1. Đăng nhập Render.com
2. Click **New** → **Web Service**
3. Connect GitHub repository: `movie-nlp-backend`
4. Cấu hình:
   - **Name**: `nlp-backend`
   - **Region**: `Singapore` (gần VN nhất)
   - **Branch**: `main`
   - **Root Directory**: `ml_backend`
   - **Runtime**: `Python 3`
   - **Build Command**: `pip install -r requirements.txt`
   - **Start Command**: `uvicorn nlp_service:app --host 0.0.0.0 --port $PORT`
5. Click **Create Web Service**

## Bước 4: Đợi deploy (5-10 phút)
- Render sẽ tự động build và deploy
- Khi xong, bạn sẽ có URL: `https://nlp-backend-xxxx.onrender.com`

## Bước 5: Cập nhật Flutter app
Sửa file `lib/services/nlp_api_service.dart`:
```dart
class NLPApiService {
  // Thay đổi từ localhost sang URL Render
  final String baseUrl = 'https://nlp-backend-xxxx.onrender.com';
  // Thay xxxx bằng URL thực tế từ Render
```

## Bước 6: Test
1. Rebuild Flutter app
2. Test voice search
3. Giờ không cần chạy Python nữa! 🎉

---

# Cách 2: Railway.app (Nhanh hơn)

## Bước 1: Tạo tài khoản
1. Truy cập: https://railway.app
2. Sign up với GitHub

## Bước 2: Deploy
1. Click **New Project**
2. **Deploy from GitHub repo**
3. Chọn repo `movie-nlp-backend`
4. Railway tự động detect Python và deploy
5. Lấy URL: `https://xxx.railway.app`

## Bước 3: Cập nhật Flutter
```dart
final String baseUrl = 'https://xxx.railway.app';
```

---

# Cách 3: PythonAnywhere (Miễn phí mãi mãi)

## Bước 1: Tạo tài khoản
1. Truy cập: https://www.pythonanywhere.com
2. Sign up (Free tier)

## Bước 2: Upload code
1. **Files** → Upload `ml_backend` folder
2. **Consoles** → **Bash**
3. Cài dependencies:
```bash
pip install --user -r requirements.txt
```

## Bước 3: Tạo Web App
1. **Web** → **Add a new web app**
2. **Manual configuration** → **Python 3.10**
3. **WSGI configuration file** → Edit:
```python
import sys
path = '/home/YOUR_USERNAME/ml_backend'
if path not in sys.path:
    sys.path.append(path)

from nlp_service import app as application
```
4. **Reload** web app

## Bước 4: Lấy URL
- URL: `https://YOUR_USERNAME.pythonanywhere.com`

## Bước 5: Cập nhật Flutter
```dart
final String baseUrl = 'https://YOUR_USERNAME.pythonanywhere.com';
```

---

# So Sánh

| Platform | Tốc độ | Miễn phí | Dễ dùng | Uptime |
|----------|--------|----------|---------|--------|
| **Render** | ⭐⭐⭐⭐ | ✅ 750h/tháng | ⭐⭐⭐⭐⭐ | 99.9% |
| **Railway** | ⭐⭐⭐⭐⭐ | ✅ $5 credit | ⭐⭐⭐⭐⭐ | 99.9% |
| **PythonAnywhere** | ⭐⭐⭐ | ✅ Mãi mãi | ⭐⭐⭐ | 99% |

---

# 🎯 Khuyến nghị

## Cho học sinh/sinh viên:
→ **Render.com** (Dễ nhất, miễn phí đủ dùng)

## Cho production:
→ **Railway.app** (Nhanh nhất, $5 credit)

## Cho demo dài hạn:
→ **PythonAnywhere** (Miễn phí mãi mãi)

---

# ⚠️ Lưu ý quan trọng

## Render.com Free Tier:
- ✅ 750 giờ/tháng (đủ chạy 24/7)
- ⚠️ Sleep sau 15 phút không dùng
- ⚠️ Khởi động lại mất ~30 giây

### Giải pháp cho sleep:
Thêm health check trong Flutter:
```dart
// Gọi API này mỗi 10 phút để giữ server thức
Future<void> keepAlive() async {
  try {
    await http.get(Uri.parse('$baseUrl/health'));
  } catch (e) {
    print('Keep alive failed: $e');
  }
}
```

Hoặc dùng service miễn phí: https://uptimerobot.com

---

# 🔧 Troubleshooting

## Lỗi: Build failed
```bash
# Kiểm tra requirements.txt có đầy đủ
# Thêm version cụ thể:
fastapi==0.104.1
uvicorn==0.24.0
```

## Lỗi: Port already in use
```python
# Sửa nlp_service.py
if __name__ == "__main__":
    import os
    port = int(os.environ.get("PORT", 8002))
    uvicorn.run(app, host="0.0.0.0", port=port)
```

## Lỗi: CORS
```python
# Thêm vào nlp_service.py
from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

---

# 📱 Sau khi deploy

## Cập nhật Flutter app:
1. Sửa `nlp_api_service.dart`
2. Thay `http://192.168.100.219:8002` → URL cloud
3. Rebuild app
4. Test voice search

## Giờ app hoạt động:
✅ Không cần máy tính
✅ Không cần cùng WiFi
✅ Hoạt động 24/7
✅ Mọi lúc, mọi nơi

---

# 🎉 Kết quả

Trước:
```
Máy tính (Python) → WiFi → Điện thoại
❌ Phải chạy Python
❌ Cùng mạng
❌ Tắt máy = mất chức năng
```

Sau:
```
Cloud Server → Internet → Điện thoại
✅ Không cần máy tính
✅ Mọi mạng đều được
✅ Hoạt động 24/7
```

---

# 📞 Hỗ trợ

Nếu gặp vấn đề, check:
1. Backend logs trên Render/Railway
2. Flutter logs: `flutter logs`
3. Network: Kiểm tra URL có đúng không
4. CORS: Thêm middleware nếu cần

Good luck! 🚀

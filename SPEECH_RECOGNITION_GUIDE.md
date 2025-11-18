# 🎤 Hướng Dẫn Nhận Dạng Giọng Nói

## ⚠️ Vấn đề với Speech Recognition

### Vấn đề:
Google Speech Recognition **nhận dạng kém** tên người nước ngoài khi nói tiếng Việt:

```
Bạn nói: "Christopher Nolan"
Nhận dạng: "cheat topper nowland" ❌
Nhận dạng: "tiktoper nỗ lực" ❌
```

### Nguyên nhân:
- Speech-to-text được train cho tiếng Việt
- Tên nước ngoài không có trong từ điển tiếng Việt
- Âm thanh tương tự → nhận dạng sai

---

## ✅ Giải pháp: 3 Nút Voice Search

### 1. **Nút Thư viện (Vàng)** 🟡
- Ngôn ngữ: Tiếng Việt
- Tốc độ: Nhanh (~2s)
- Độ chính xác: Thấp
- Sử dụng: Tìm kiếm đơn giản

**Ví dụ:**
```
✅ "Tìm phim Avengers" → OK
❌ "Phim kinh dị" → Không hiểu
```

---

### 2. **Nút NLP (VI) (Xanh)** 🟢
- Ngôn ngữ: Tiếng Việt
- NLP: 11 thuật toán
- Độ chính xác: Cao (80-90%)
- Giới hạn: Tên người nước ngoài

**Ví dụ:**
```
✅ "Phim kinh dị" → 20 phim horror
✅ "Phim 2024" → Phim năm 2024
✅ "Phim Avatar" → Avatar 1, 2
❌ "Phim Christopher Nolan" → Nhận dạng sai
```

---

### 3. **Nút NLP (EN) (Xanh Dương)** 🔵 ⭐ KHUYẾN NGHỊ
- Ngôn ngữ: Tiếng Anh
- NLP: 11 thuật toán
- Độ chính xác: Rất cao (90-95%)
- Tốt nhất: Tên người, tên phim

**Ví dụ:**
```
✅ "Christopher Nolan movies" → Phim của Nolan
✅ "Tom Cruise films" → Phim Tom Cruise
✅ "Horror movies" → Phim kinh dị
✅ "Avatar movie" → Avatar
✅ "Action movies 2024" → Phim hành động 2024
```

---

## 🎯 Khi nào dùng nút nào?

### Dùng NLP (VI) - Xanh 🟢:
```
✅ "Phim kinh dị"
✅ "Phim hành động"
✅ "Phim 2024"
✅ "Phim hay nhất"
✅ "Phim phổ biến"
✅ "Phim Avatar" (tên phim nổi tiếng)
```

### Dùng NLP (EN) - Xanh Dương 🔵:
```
✅ "Christopher Nolan movies"
✅ "Tom Cruise films"
✅ "Leonardo DiCaprio"
✅ "Steven Spielberg"
✅ "Marvel movies"
✅ "DC movies"
✅ "Horror movies"
✅ "Action films 2024"
```

---

## 📝 Mẹo sử dụng:

### Cho tên người (Diễn viên/Đạo diễn):
**Dùng NLP (EN) - Nói tiếng Anh:**
```
✅ "Christopher Nolan movies"
✅ "Tom Cruise films"
✅ "Robert Downey Junior"
```

**KHÔNG dùng NLP (VI):**
```
❌ "Phim của Christopher Nolan" → Nhận dạng sai
❌ "Phim Tom Cruise" → Có thể sai
```

### Cho thể loại:
**Cả 2 nút đều OK:**
```
NLP (VI): "Phim kinh dị"
NLP (EN): "Horror movies"
```

### Cho tên phim:
**Cả 2 nút đều OK:**
```
NLP (VI): "Phim Avatar"
NLP (EN): "Avatar movie"
```

---

## 🎬 Ví dụ thực tế:

### Tìm phim của đạo diễn:

**❌ SAI - Dùng NLP (VI):**
```
Bạn: "Phim của đạo diễn Christopher Nolan"
Speech: "phim của đạo diễn tiktoper nỗ lực"
Kết quả: 0 phim ❌
```

**✅ ĐÚNG - Dùng NLP (EN):**
```
Bạn: "Christopher Nolan movies"
Speech: "Christopher Nolan movies"
NLP: people: [christopher nolan]
Kết quả: Inception, Interstellar, The Dark Knight ✅
```

---

### Tìm phim theo thể loại:

**✅ Cả 2 đều OK:**

**NLP (VI):**
```
Bạn: "Phim kinh dị"
NLP: genres: [horror]
Kết quả: 20 phim horror ✅
```

**NLP (EN):**
```
Bạn: "Horror movies"
NLP: genres: [horror]
Kết quả: 20 phim horror ✅
```

---

## 📊 So sánh 3 nút:

| Tính năng | Thư viện (Vàng) | NLP (VI) | NLP (EN) ⭐ |
|-----------|-----------------|----------|------------|
| **Tốc độ** | ⚡⚡⚡ | ⚡⚡ | ⚡⚡ |
| **NLP** | ❌ | ✅ 11 thuật toán | ✅ 11 thuật toán |
| **Tiếng Việt** | ✅ | ✅ | ❌ |
| **Tên người** | ❌ | ❌ Kém | ✅ Tốt |
| **Thể loại** | ❌ | ✅ Tốt | ✅ Tốt |
| **Tên phim** | ✅ | ✅ Tốt | ✅ Tốt |
| **Độ chính xác** | 50% | 80-90% | 90-95% |

---

## 🎯 Khuyến nghị:

### Tìm theo tên người → Dùng NLP (EN) 🔵
```
"Christopher Nolan movies"
"Tom Cruise films"
"Leonardo DiCaprio"
```

### Tìm theo thể loại → Dùng NLP (VI) hoặc (EN) 🟢🔵
```
VI: "Phim kinh dị"
EN: "Horror movies"
```

### Tìm theo tên phim → Dùng NLP (VI) hoặc (EN) 🟢🔵
```
VI: "Phim Avatar"
EN: "Avatar movie"
```

---

## 🚀 Workflow đề xuất:

### Bước 1: Xác định loại tìm kiếm
- Tên người? → NLP (EN) 🔵
- Thể loại/Năm? → NLP (VI) 🟢
- Tên phim? → Cả 2 OK 🟢🔵

### Bước 2: Chọn nút phù hợp
- NLP (VI) - Xanh: Tiếng Việt
- NLP (EN) - Xanh Dương: Tiếng Anh

### Bước 3: Nói rõ ràng
- Chậm rãi, có khoảng dừng
- Phát âm chuẩn

### Bước 4: Kiểm tra text
- Xem text hiển thị
- Nếu đúng → Nhấn lần 2
- Nếu sai → Thử lại

---

## 💡 Tips:

### 1. Học một số cụm tiếng Anh cơ bản:
```
"[Name] movies" - Phim của [Tên]
"Horror movies" - Phim kinh dị
"Action films" - Phim hành động
"Movies 2024" - Phim 2024
"Popular movies" - Phim phổ biến
"Best movies" - Phim hay nhất
```

### 2. Tên đạo diễn/diễn viên nổi tiếng:
```
Christopher Nolan
Steven Spielberg
Quentin Tarantino
Tom Cruise
Leonardo DiCaprio
Robert Downey Junior
```

### 3. Thể loại phim:
```
Horror - Kinh dị
Action - Hành động
Comedy - Hài
Romance - Tình cảm
Thriller - Tâm lý
Sci-fi - Khoa học viễn tưởng
```

---

## 🎉 Kết luận:

- **NLP (VI) 🟢:** Tốt cho tiếng Việt, thể loại, năm
- **NLP (EN) 🔵:** Tốt nhất cho tên người, tên phim nước ngoài
- **Thư viện 🟡:** Backup, tìm kiếm đơn giản

**Khuyến nghị:** Dùng NLP (EN) cho tên người nước ngoài! 🌟

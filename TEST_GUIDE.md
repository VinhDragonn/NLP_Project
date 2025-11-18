# Hướng dẫn Test NLP Voice Search

## ✅ Đã tích hợp vào HomePage

File `lib/HomePage/HomePage.dart` đã được cập nhật để sử dụng **NLP Voice Search Button** với 11 thuật toán NLP tự code.

## 🚀 Cách test

### Bước 1: Khởi động NLP Backend

Mở terminal trong `ml_backend`:

```powershell
# Windows PowerShell
$env:NLP_PORT=8002; python nlp_service.py
```

Đợi đến khi thấy:
```
✅ NLP Service ready!
INFO:     Uvicorn running on http://0.0.0.0:8002
```

### Bước 2: Chạy Flutter App

Mở terminal mới:

```bash
flutter run
```

### Bước 3: Test Voice Search

1. **Mở app** → Vào HomePage
2. **Nhấn nút mic** (floating button màu vàng/xanh)
3. **Nói tiếng Việt** hoặc tiếng Anh:
   - "Tìm phim hành động mới nhất năm 2024"
   - "Find action movies"
   - "Phim kinh dị hay nhất"
   - "Tom Cruise movies"
   - "Popular movies"

4. **Xem kết quả NLP**:
   - Dialog hiển thị phân tích NLP
   - Intent classification
   - Entities extracted
   - Processed query
   - Confidence score

5. **Tìm kiếm** với processed query

## 🎯 Các trường hợp test

### Test 1: Tìm theo thể loại
```
Input:  "Tìm phim hành động mới nhất"
Output: 
  Intent: search_by_genre
  Entities: {genres: [action]}
  Processed: "action movie new latest"
```

### Test 2: Tìm theo năm
```
Input:  "Phim năm 2024"
Output:
  Intent: search_by_year
  Entities: {years: [2024]}
  Processed: "movie 2024"
```

### Test 3: Tìm phim phổ biến
```
Input:  "Phim nổi tiếng"
Output:
  Intent: search_popular
  Entities: {popularity_expressions: [nổi tiếng]}
  Processed: "popular movie"
```

### Test 4: Tìm theo diễn viên
```
Input:  "Phim của Tom Cruise"
Output:
  Intent: search_by_actor
  Entities: {people: [tom cruise]}
  Processed: "tom cruise movie"
```

### Test 5: Tìm phim hay nhất
```
Input:  "Phim hay nhất"
Output:
  Intent: search_high_rating
  Entities: {rating_expressions: [hay nhất]}
  Processed: "best movie"
```

## 📊 Kiểm tra NLP algorithms

Trong console/terminal sẽ thấy log:

```
🎤 Voice: Tìm phim hành động mới nhất năm 2024
🎯 Intent: search_by_genre
🔄 Processed: action movie 2024 new latest
📊 Confidence: 0.89
```

## 🔍 Debug

### Kiểm tra NLP Service

```powershell
# Test health check
curl http://localhost:8002/health

# Kết quả mong đợi:
# {"status":"ok","service":"nlp_service","models_loaded":true}
```

### Kiểm tra API

Mở trình duyệt: http://localhost:8002/docs

Test endpoint `/api/nlp/voice-search`:
```json
{
  "voice_text": "Tìm phim hành động mới nhất",
  "language": "vi"
}
```

### Lỗi thường gặp

#### 1. NLP Service không khả dụng
```
⚠️ NLP Service không khả dụng. Vui lòng khởi động backend.
```

**Giải pháp:**
- Kiểm tra backend có đang chạy không
- Kiểm tra port 8002
- Kiểm tra URL trong `nlp_api_service.dart`

#### 2. Import error
```
Error: Cannot find 'nlp_voice_search_button.dart'
```

**Giải pháp:**
```bash
flutter clean
flutter pub get
flutter run
```

#### 3. Permission denied
```
Cần quyền truy cập microphone
```

**Giải pháp:**
- Cấp quyền microphone trong settings
- Kiểm tra AndroidManifest.xml

## 🎨 UI States

Button có 4 trạng thái:

1. **Idle** (Vàng) - Sẵn sàng
2. **Listening** (Đỏ) - Đang nghe
3. **Processing** (Xanh + animation) - Đang xử lý NLP
4. **Completed** (Xanh dương) - Hoàn thành

## 📝 So sánh với Google Voice Search

### ❌ Google Voice Search (Cũ)
- Chỉ có speech-to-text
- Không phân tích ý định
- Không trích xuất entities
- Không mở rộng query

### ✅ NLP Voice Search (Mới)
- Speech-to-text + 11 thuật toán NLP
- ✅ Intent Classification (Naive Bayes + SVM)
- ✅ Named Entity Recognition (NER)
- ✅ Query Expansion (Synonyms)
- ✅ Spell Correction
- ✅ Semantic Similarity
- ✅ TF-IDF Vectorization
- ✅ Levenshtein Distance
- ✅ Jaccard Similarity
- ✅ Cosine Similarity
- ✅ N-gram Similarity
- ✅ Word Embeddings

## 🎓 Thuật toán được sử dụng

Khi bạn nói "Tìm phim hành động mới nhất năm 2024", hệ thống sẽ:

1. **Tokenization** → [tìm, phim, hành, động, mới, nhất, năm, 2024]
2. **Stemming** → [tim, phim, hanh, dong, moi, nhat, nam, 2024]
3. **Stop Words Removal** → [phim, hành, động, mới, nhất, 2024]
4. **Text Normalization** → [movie, action, new, latest, 2024]
5. **Intent Classification** → search_by_genre (Naive Bayes + SVM)
6. **NER** → genres: [action], years: [2024]
7. **Query Expansion** → [action movies 2024, adventure films 2024]
8. **Spell Correction** → Sửa lỗi nếu có
9. **TF-IDF** → Tính trọng số từ
10. **Cosine Similarity** → So sánh với database
11. **Fuzzy Matching** → Tìm phim gần giống

## ✅ Checklist Test

- [ ] Backend NLP đang chạy (port 8002)
- [ ] Flutter app đã build thành công
- [ ] Nhấn nút mic → màu đỏ (listening)
- [ ] Nói tiếng Việt/Anh
- [ ] Button chuyển màu xanh + animation (processing)
- [ ] Dialog hiển thị kết quả NLP
- [ ] Intent đúng
- [ ] Entities được trích xuất
- [ ] Processed query chính xác
- [ ] Navigate to search page
- [ ] Kết quả tìm kiếm đúng

## 🎉 Kết quả mong đợi

Sau khi test thành công, bạn sẽ thấy:

1. ✅ Voice recognition hoạt động
2. ✅ NLP processing nhanh (<2s)
3. ✅ Intent classification chính xác (>80%)
4. ✅ Entities được trích xuất đúng
5. ✅ Query được xử lý và mở rộng
6. ✅ Kết quả tìm kiếm thông minh hơn

## 📹 Demo Flow

```
User: "Tìm phim hành động mới nhất năm 2024"
  ↓
[Speech-to-Text]
  ↓
[NLP Processing - 11 algorithms]
  ↓
Dialog shows:
  🎤 Voice Input: Tìm phim hành động mới nhất năm 2024
  🔄 Processed: action movie 2024 new latest
  🎯 Intent: search_by_genre (89%)
  🏷️ Entities:
     • genres: action
     • years: 2024
     • time_expressions: mới nhất, new, latest
  🔍 Expanded Queries:
     • action movies 2024
     • adventure films 2024
     • thriller movies 2024
  ↓
[User clicks Search]
  ↓
Navigate to VoiceSearchResultPage
  ↓
Show results from TMDB API
```

## 🔗 Links hữu ích

- Backend API Docs: http://localhost:8002/docs
- Health Check: http://localhost:8002/health
- Test Algorithms: `python test_nlp_algorithms.py`

Chúc bạn test thành công! 🚀

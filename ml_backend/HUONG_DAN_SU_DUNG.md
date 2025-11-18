# HƯỚNG DẪN SỬ DỤNG HỆ THỐNG NLP

## 🎯 Mục đích

Thay thế việc sử dụng thư viện `speech_to_text` bằng các **thuật toán NLP tự code** để xử lý tìm kiếm phim bằng giọng nói, áp dụng kiến thức môn Ngôn ngữ tự nhiên.

## 📁 Cấu trúc thư mục

```
ml_backend/
├── nlp_preprocessing.py           # Tiền xử lý: Tokenization, Stemming, TF-IDF
├── nlp_intent_classifier.py       # Phân loại ý định: Naive Bayes, SVM
├── nlp_ner.py                     # Nhận dạng thực thể (NER)
├── nlp_semantic_similarity.py     # Độ tương đồng: Levenshtein, Jaccard, Cosine
├── nlp_query_expansion.py         # Mở rộng query, sửa lỗi chính tả
├── nlp_service.py                 # FastAPI service
├── test_nlp_algorithms.py         # Test tất cả thuật toán
├── requirements.txt               # Dependencies
├── NLP_README.md                  # Tài liệu chi tiết
├── ALGORITHMS_SUMMARY.md          # Tổng hợp thuật toán
├── INTEGRATION_GUIDE.md           # Hướng dẫn tích hợp Flutter
└── start_nlp_service.bat          # Script khởi động (Windows)
```

## 🚀 Bắt đầu nhanh

### Bước 1: Cài đặt

```bash
cd ml_backend
pip install -r requirements.txt
```

### Bước 2: Test thuật toán

```bash
python test_nlp_algorithms.py
```

Bạn sẽ thấy kết quả của tất cả 11 thuật toán:
- ✅ Tokenization
- ✅ Porter Stemmer
- ✅ TF-IDF
- ✅ Cosine Similarity
- ✅ Naive Bayes
- ✅ SVM
- ✅ Levenshtein Distance
- ✅ Jaccard Similarity
- ✅ N-gram Similarity
- ✅ Word Embeddings
- ✅ Spell Correction

### Bước 3: Chạy NLP Service

**Windows:**
```bash
start_nlp_service.bat
```

**Linux/Mac:**
```bash
python nlp_service.py
```

Service sẽ chạy trên: `http://localhost:8001`

### Bước 4: Kiểm tra API

Mở trình duyệt:
- API Docs: http://localhost:8001/docs
- Health Check: http://localhost:8001/health

## 📝 Sử dụng API

### 1. Voice Search (Tìm kiếm giọng nói)

**Endpoint:** `POST /api/nlp/voice-search`

**Request:**
```json
{
  "voice_text": "Tìm phim hành động mới nhất năm 2024",
  "language": "vi"
}
```

**Response:**
```json
{
  "original_text": "Tìm phim hành động mới nhất năm 2024",
  "processed_query": "action movie 2024 new latest",
  "intent": "search_by_genre",
  "confidence": 0.89,
  "entities": {
    "genres": ["action"],
    "years": ["2024"],
    "time_expressions": ["mới nhất", "new", "latest"]
  },
  "search_parameters": {
    "genres": ["action"],
    "years": ["2024"],
    "sort_by": "release_date_desc"
  },
  "expanded_queries": [
    "action movies 2024",
    "adventure films 2024",
    "thriller movies 2024"
  ],
  "suggestions": [
    "Top action movies",
    "New action releases"
  ]
}
```

### 2. Intent Classification (Phân loại ý định)

**Endpoint:** `POST /api/nlp/intent`

**Request:**
```json
{
  "text": "Find action movies"
}
```

**Response:**
```json
{
  "intent": "search_by_genre",
  "confidence": 0.85,
  "details": {
    "naive_bayes": {
      "intent": "search_by_genre",
      "confidence": 0.82
    },
    "svm": {
      "intent": "search_by_genre",
      "confidence": 0.88
    },
    "rule_based": "search_by_genre",
    "tokens": ["find", "action", "movie"]
  }
}
```

### 3. Similarity (Độ tương đồng)

**Endpoint:** `POST /api/nlp/similarity`

**Request:**
```json
{
  "text1": "action movies",
  "text2": "adventure films",
  "method": "all"
}
```

**Response:**
```json
{
  "similarities": {
    "levenshtein": 0.357,
    "jaccard": 0.0,
    "cosine": 0.0,
    "ngram_2": 0.222,
    "ngram_3": 0.125,
    "average": 0.141
  },
  "most_similar_method": "levenshtein",
  "average_similarity": 0.141
}
```

### 4. Fuzzy Match (Tìm kiếm mờ)

**Endpoint:** `POST /api/nlp/fuzzy-match`

**Request:**
```json
{
  "query": "avenger",
  "candidates": [
    "The Avengers",
    "Avengers: Endgame",
    "Avatar",
    "The Amazing Spider-Man"
  ],
  "threshold": 0.6
}
```

**Response:**
```json
{
  "matches": [
    {"text": "The Avengers", "score": 0.85},
    {"text": "Avengers: Endgame", "score": 0.78}
  ],
  "best_match": {
    "text": "The Avengers",
    "score": 0.85
  }
}
```

### 5. Query Expansion (Mở rộng truy vấn)

**Endpoint:** `POST /api/nlp/expand-query`

**Request:**
```json
{
  "query": "tim phim hanh dong moi nhat",
  "max_expansions": 5
}
```

**Response:**
```json
{
  "original_query": "tim phim hanh dong moi nhat",
  "corrected_query": "tìm phim hành động mới nhất",
  "simplified_query": "phim hành động mới nhất",
  "expanded_queries": [
    "search phim hành động mới nhất",
    "find phim hành động mới nhất",
    "tìm film hành động mới nhất"
  ],
  "rewritten_queries": [
    "action movies",
    "best action films"
  ],
  "suggestions": [
    "action movies 2024",
    "best action films"
  ]
}
```

## 🧪 Test với Python

```python
import requests

# Test voice search
response = requests.post(
    "http://localhost:8001/api/nlp/voice-search",
    json={
        "voice_text": "Tìm phim hành động mới nhất",
        "language": "vi"
    }
)

result = response.json()
print(f"Intent: {result['intent']}")
print(f"Processed Query: {result['processed_query']}")
print(f"Entities: {result['entities']}")
```

## 🔗 Tích hợp với Flutter

### Tạo service trong Flutter

```dart
// lib/services/nlp_api_service.dart
class NLPApiService {
  final String baseUrl = 'http://localhost:8001';
  
  Future<Map<String, dynamic>> processVoiceSearch(String voiceText) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/nlp/voice-search'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'voice_text': voiceText,
        'language': 'vi'
      }),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('NLP Service error');
    }
  }
}
```

### Sử dụng trong widget

```dart
// Trong voice search widget
final nlpService = NLPApiService();

// Sau khi nhận dạng giọng nói
String recognizedText = result.recognizedWords;

// Xử lý với NLP algorithms
var nlpResult = await nlpService.processVoiceSearch(recognizedText);

// Sử dụng kết quả
String intent = nlpResult['intent'];
String processedQuery = nlpResult['processed_query'];
List genres = nlpResult['entities']['genres'];
```

## 📊 Các thuật toán đã triển khai

### 1. Preprocessing (Tiền xử lý)
- **Tokenization**: Tách văn bản thành từ
- **Porter Stemmer**: Đưa từ về dạng gốc
- **Stop Words Removal**: Loại bỏ từ dừng
- **Text Normalization**: Chuẩn hóa tiếng Việt

### 2. Feature Extraction (Trích xuất đặc trưng)
- **TF-IDF**: Term Frequency - Inverse Document Frequency
- **N-grams**: Bigrams, Trigrams
- **Word Frequency**: Tần suất từ

### 3. Classification (Phân loại)
- **Naive Bayes**: Phân loại xác suất với Laplace Smoothing
- **SVM**: Support Vector Machine với Gradient Descent

### 4. Similarity (Độ tương đồng)
- **Levenshtein Distance**: Khoảng cách chỉnh sửa
- **Jaccard Similarity**: Độ tương đồng tập hợp
- **Cosine Similarity**: Độ tương đồng vector
- **N-gram Similarity**: Độ tương đồng n-gram

### 5. Advanced (Nâng cao)
- **Word Embeddings**: Vector hóa từ
- **Spell Correction**: Sửa lỗi chính tả
- **Query Expansion**: Mở rộng truy vấn
- **Named Entity Recognition**: Nhận dạng thực thể

## 🎓 Giải thích thuật toán

### Naive Bayes

**Công thức:**
```
P(class|document) = P(class) × ∏ P(word|class)
```

**Ví dụ:**
```
Training:
  "action movie" → search_by_genre
  "find movie" → search_by_title

Predict: "action movie"
  P(genre|doc) = P(genre) × P(action|genre) × P(movie|genre)
  P(title|doc) = P(title) × P(action|title) × P(movie|title)
  
  → Chọn class có xác suất cao hơn
```

### TF-IDF

**Công thức:**
```
TF(t,d) = count(t in d) / total_words(d)
IDF(t) = log(N / (df(t) + 1))
TF-IDF(t,d) = TF(t,d) × IDF(t)
```

**Ví dụ:**
```
Document: "action movie good"
Term: "action"

TF = 1/3 = 0.333
IDF = log(100/10) = 1.0
TF-IDF = 0.333 × 1.0 = 0.333
```

### Levenshtein Distance

**Công thức:**
```
D[i,j] = min(
    D[i-1,j] + 1,        # xóa
    D[i,j-1] + 1,        # thêm
    D[i-1,j-1] + cost    # thay thế
)
```

**Ví dụ:**
```
"avenger" → "avengers"
Distance = 1 (thêm 's')
```

## 🔧 Troubleshooting

### Lỗi: Module not found

```bash
pip install -r requirements.txt
```

### Lỗi: Port 8001 đã được sử dụng

```bash
# Chạy trên port khác
NLP_PORT=8002 python nlp_service.py
```

### Lỗi: Kết nối từ Flutter

Đảm bảo:
1. NLP Service đang chạy
2. URL đúng (localhost hoặc IP máy)
3. Firewall không chặn

## 📚 Tài liệu tham khảo

- `NLP_README.md`: Tài liệu chi tiết về NLP Service
- `ALGORITHMS_SUMMARY.md`: Tổng hợp tất cả thuật toán
- `INTEGRATION_GUIDE.md`: Hướng dẫn tích hợp Flutter
- `test_nlp_algorithms.py`: Code test và ví dụ

## ✅ Checklist

- [x] Tokenization & Stemming
- [x] TF-IDF Vectorization
- [x] Naive Bayes Classifier
- [x] SVM Classifier
- [x] Named Entity Recognition
- [x] Levenshtein Distance
- [x] Jaccard Similarity
- [x] Cosine Similarity
- [x] N-gram Similarity
- [x] Word Embeddings
- [x] Spell Correction
- [x] Query Expansion
- [x] FastAPI Service
- [x] Integration Guide
- [x] Test Scripts

## 🎉 Kết luận

Bạn đã có một hệ thống NLP hoàn chỉnh với **11 thuật toán** được code từ đầu để xử lý tìm kiếm phim bằng giọng nói!

**Điểm mạnh:**
- ✅ Tự code tất cả thuật toán (không dùng thư viện NLP)
- ✅ Hiểu rõ cách hoạt động của từng thuật toán
- ✅ Áp dụng kiến thức môn Ngôn ngữ tự nhiên
- ✅ Có thể tùy chỉnh và mở rộng
- ✅ Hỗ trợ cả tiếng Việt và tiếng Anh

**Sử dụng:**
1. Chạy NLP Service: `python nlp_service.py`
2. Test thuật toán: `python test_nlp_algorithms.py`
3. Tích hợp với Flutter theo `INTEGRATION_GUIDE.md`

Chúc bạn thành công! 🚀

# NLP Service for Movie Voice Search

## Tổng quan

Dự án này triển khai các thuật toán xử lý ngôn ngữ tự nhiên (NLP) từ đầu (from scratch) để xử lý tìm kiếm phim bằng giọng nói. Thay vì sử dụng thư viện có sẵn, chúng ta tự code các thuật toán để áp dụng kiến thức môn Ngôn ngữ tự nhiên.

## Các Module NLP

### 1. **nlp_preprocessing.py** - Tiền xử lý văn bản

#### Thuật toán được triển khai:

- **Tokenization**: Tách văn bản thành các token (từ)
- **Porter Stemmer**: Thuật toán stemming cho tiếng Anh
  - Loại bỏ hậu tố (suffixes)
  - Chuẩn hóa từ về dạng gốc
- **Vietnamese Stemmer**: Stemming cho tiếng Việt
- **Stop Words Removal**: Loại bỏ từ dừng (stop words)
- **Text Normalization**: Chuẩn hóa văn bản
  - Chuyển đổi tiếng Việt sang tiếng Anh
  - Loại bỏ dấu thanh
- **TF-IDF Vectorizer**: Tính toán TF-IDF từ đầu
  - Term Frequency (TF)
  - Inverse Document Frequency (IDF)
  - Cosine Similarity

#### Công thức toán học:

```
TF(t,d) = count(t in d) / total_words(d)
IDF(t) = log(N / (df(t) + 1))
TF-IDF(t,d) = TF(t,d) × IDF(t)

Cosine Similarity = (A · B) / (||A|| × ||B||)
```

### 2. **nlp_intent_classifier.py** - Phân loại ý định

#### Thuật toán được triển khai:

- **Naive Bayes Classifier**: 
  - Thuật toán xác suất Bayes
  - Laplace Smoothing
  - Công thức: P(class|doc) ∝ P(class) × ∏P(word|class)

- **Support Vector Machine (SVM)**:
  - Gradient Descent
  - One-vs-Rest approach
  - Hinge Loss optimization

#### Các intent được nhận dạng:

1. `search_by_title` - Tìm theo tên phim
2. `search_by_genre` - Tìm theo thể loại
3. `search_by_year` - Tìm theo năm
4. `search_popular` - Tìm phim phổ biến
5. `search_high_rating` - Tìm phim đánh giá cao
6. `search_similar` - Tìm phim tương tự
7. `search_by_actor` - Tìm theo diễn viên

### 3. **nlp_ner.py** - Named Entity Recognition

#### Thuật toán được triển khai:

- **Entity Recognition**: Nhận dạng thực thể
  - Genres (thể loại)
  - Years (năm)
  - People (diễn viên/đạo diễn)
  - Titles (tên phim)
  
- **Feature Extraction**: Trích xuất đặc trưng
  - N-grams (bigrams, trigrams)
  - Word frequency
  - Entity features

- **Query Analysis**: Phân tích truy vấn
  - Query type classification
  - Complexity calculation
  - Parameter extraction

### 4. **nlp_semantic_similarity.py** - Độ tương đồng ngữ nghĩa

#### Thuật toán được triển khai:

- **Levenshtein Distance**: Khoảng cách chỉnh sửa
  - Dynamic Programming
  - Edit operations: insert, delete, substitute
  - Công thức: D[i,j] = min(D[i-1,j]+1, D[i,j-1]+1, D[i-1,j-1]+cost)

- **Jaccard Similarity**: Độ tương đồng tập hợp
  - Công thức: J(A,B) = |A ∩ B| / |A ∪ B|

- **Cosine Similarity**: Độ tương đồng vector
  - Đã mô tả ở trên

- **N-gram Similarity**: Độ tương đồng n-gram
  - Character-level n-grams
  - Jaccard similarity trên n-grams

- **Word Embeddings**: Vector hóa từ
  - Co-occurrence matrix
  - Dimensionality reduction
  - Vector averaging

### 5. **nlp_query_expansion.py** - Mở rộng truy vấn

#### Thuật toán được triển khai:

- **Spell Correction**: Sửa lỗi chính tả
  - Edit distance (1 và 2 edits)
  - Frequency-based selection
  - Vietnamese spell correction

- **Query Expansion**: Mở rộng truy vấn
  - Synonym expansion (từ đồng nghĩa)
  - Hypernym expansion (từ tổng quát hơn)
  - Hyponym expansion (từ cụ thể hơn)

- **Query Rewriting**: Viết lại truy vấn
  - Template-based rewriting
  - Query simplification

- **Query Suggestion**: Gợi ý truy vấn
  - Prefix matching
  - Frequency-based ranking

### 6. **nlp_service.py** - API Service

FastAPI service cung cấp các endpoint:

#### Endpoints:

1. **POST /api/nlp/voice-search**
   - Xử lý tìm kiếm giọng nói hoàn chỉnh
   - Kết hợp tất cả các thuật toán NLP

2. **POST /api/nlp/intent**
   - Phân loại ý định người dùng
   - Sử dụng Naive Bayes + SVM

3. **POST /api/nlp/analyze**
   - Phân tích truy vấn chi tiết
   - NER + Feature extraction

4. **POST /api/nlp/similarity**
   - Tính độ tương đồng giữa 2 văn bản
   - Multiple similarity methods

5. **POST /api/nlp/fuzzy-match**
   - Fuzzy matching cho tên phim
   - Levenshtein + N-gram + Jaccard

6. **POST /api/nlp/expand-query**
   - Mở rộng truy vấn
   - Spell correction + Synonyms

7. **POST /api/nlp/preprocess**
   - Tiền xử lý văn bản
   - Tokenization + Stemming + N-grams

## Cài đặt

```bash
cd ml_backend
pip install -r requirements.txt
```

## Chạy NLP Service

```bash
# Chạy trên port 8001
python nlp_service.py

# Hoặc chỉ định port khác
NLP_PORT=8002 python nlp_service.py
```

## Sử dụng

### 1. Voice Search Processing

```python
import requests

response = requests.post(
    "http://localhost:8001/api/nlp/voice-search",
    json={
        "voice_text": "Tìm phim hành động mới nhất năm 2024",
        "language": "vi"
    }
)

result = response.json()
print(f"Intent: {result['intent']}")
print(f"Processed Query: {result['processed_query']}")
print(f"Entities: {result['entities']}")
```

### 2. Intent Classification

```python
response = requests.post(
    "http://localhost:8001/api/nlp/intent",
    json={"text": "Find action movies"}
)

result = response.json()
print(f"Intent: {result['intent']}")
print(f"Confidence: {result['confidence']}")
```

### 3. Similarity Calculation

```python
response = requests.post(
    "http://localhost:8001/api/nlp/similarity",
    json={
        "text1": "action movies",
        "text2": "adventure films",
        "method": "all"
    }
)

result = response.json()
print(f"Similarities: {result['similarities']}")
```

### 4. Fuzzy Matching

```python
response = requests.post(
    "http://localhost:8001/api/nlp/fuzzy-match",
    json={
        "query": "avenger",
        "candidates": [
            "The Avengers",
            "Avengers: Endgame",
            "Avatar",
            "The Amazing Spider-Man"
        ],
        "threshold": 0.6
    }
)

result = response.json()
print(f"Best Match: {result['best_match']}")
```

## Kiến trúc hệ thống

```
Voice Input (Giọng nói)
    ↓
Speech-to-Text (Flutter)
    ↓
NLP Service (Python)
    ├── Preprocessing (Tiền xử lý)
    ├── Intent Classification (Phân loại ý định)
    ├── NER (Nhận dạng thực thể)
    ├── Semantic Analysis (Phân tích ngữ nghĩa)
    ├── Query Expansion (Mở rộng truy vấn)
    └── Similarity Matching (Tìm kiếm tương đồng)
    ↓
Search Results (Kết quả tìm kiếm)
```

## Thuật toán chính

### 1. Naive Bayes

```python
P(class|document) = P(class) × ∏ P(word|class)

# Với Laplace Smoothing:
P(word|class) = (count(word, class) + 1) / (count(class) + |V|)
```

### 2. SVM (Gradient Descent)

```python
# Hinge Loss
L = max(0, 1 - y × (w·x + b))

# Weight Update
w = w + α × (y × x - 2λ × w)
b = b + α × y
```

### 3. TF-IDF

```python
TF(t,d) = count(t in d) / total_words(d)
IDF(t) = log(N / (df(t) + 1))
TF-IDF(t,d) = TF(t,d) × IDF(t)
```

### 4. Cosine Similarity

```python
cos(A, B) = (A · B) / (||A|| × ||B||)
         = Σ(Ai × Bi) / (√Σ(Ai²) × √Σ(Bi²))
```

### 5. Levenshtein Distance

```python
D[i,j] = min(
    D[i-1,j] + 1,      # deletion
    D[i,j-1] + 1,      # insertion
    D[i-1,j-1] + cost  # substitution (cost=0 if same, 1 if different)
)
```

### 6. Jaccard Similarity

```python
J(A, B) = |A ∩ B| / |A ∪ B|
```

## Testing

Chạy các file test:

```bash
# Test preprocessing
python nlp_preprocessing.py

# Test intent classification
python nlp_intent_classifier.py

# Test NER
python nlp_ner.py

# Test similarity
python nlp_semantic_similarity.py

# Test query expansion
python nlp_query_expansion.py
```

## Ví dụ kết quả

### Input:
```
"Tìm phim hành động mới nhất năm 2024"
```

### Output:
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
  ]
}
```

## Tích hợp với Flutter

Trong Flutter app, gọi NLP service:

```dart
// lib/services/nlp_service.dart
class NLPService {
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
    
    return jsonDecode(response.body);
  }
}
```

## Đóng góp

Các thuật toán được triển khai từ đầu để học tập và hiểu rõ cách hoạt động của NLP. Có thể cải thiện:

1. Thêm thuật toán Word2Vec/GloVe
2. Triển khai LSTM/Transformer cho intent classification
3. Thêm thuật toán CRF cho NER
4. Cải thiện Vietnamese processing
5. Thêm caching và optimization

## License

MIT License

## Tác giả

Dự án môn Ngôn ngữ tự nhiên - Tìm kiếm phim bằng giọng nói

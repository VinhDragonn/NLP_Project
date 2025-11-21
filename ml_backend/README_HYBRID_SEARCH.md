# Hybrid Search Engine Setup Guide

## Tổng quan

Hệ thống tìm kiếm hybrid sử dụng:
- **Tang 1**: BiLSTM + Attention để phân loại intent (TITLE, PLOT, CATEGORY)
- **Tang 2**: Hybrid Search kết hợp TF-IDF và SBERT để tìm phim

## Cài đặt Dependencies

```bash
pip install -r requirements.txt
```

Các thư viện cần thiết:
- `tensorflow>=2.13.0` - Cho BiLSTM + Attention
- `sentence-transformers>=2.2.0` - Cho SBERT embeddings
- `torch>=2.0.0` - Cho PyTorch (sentence-transformers dependency)
- `googletrans-py>=4.0.0` - Cho translation

## Chuẩn bị Dataset

1. Tải dataset `rotten_tomatoes_ENRICHED.csv` và đặt vào thư mục `data/`
2. Dataset cần có các cột:
   - `movie_title`: Tên phim
   - `movie_info`: Mô tả phim
   - `genres`: Thể loại
   - `keywords`: Từ khóa

## Khởi tạo và Training

### 1. Load Dataset và Khởi tạo TF-IDF + SBERT

```python
from hybrid_search_engine import HybridSearchEngine

# Khởi tạo engine
engine = HybridSearchEngine(data_dir="data")

# Load dataset
engine.load_dataset("data/rotten_tomatoes_ENRICHED.csv")

# Khởi tạo TF-IDF
engine.initialize_tfidf()

# Khởi tạo SBERT (lần đầu sẽ mất thời gian để tạo embeddings)
engine.initialize_sbert()
```

### 2. Training Intent Classifier (BiLSTM + Attention)

```python
# Training model (sẽ mất vài phút)
engine.train_intent_classifier(n_samples=2000)

# Model sẽ được lưu vào: data/intent_classifier.h5
```

### 3. Sử dụng Hybrid Search

```python
# Tìm kiếm
results = engine.search_hybrid("action movies with tom cruise", top_k=5)

for result in results:
    print(f"Title: {result['movie_title']}")
    print(f"Score: {result['score']:.4f}")
    print(f"Intent: {result['intent']}")
    print(f"Alpha: {result['alpha']}")
    print("---")
```

## Sử dụng qua API

### Endpoint: `/api/nlp/hybrid-search`

**Request:**
```json
{
  "query": "action movies with tom cruise",
  "top_k": 5
}
```

**Response:**
```json
{
  "query": "action movies with tom cruise",
  "intent": "CATEGORY",
  "alpha": 0.9,
  "processing_time_ms": 123.45,
  "results": [
    {
      "movie_title": "top gun",
      "genres": "action drama",
      "keywords": "military fighter pilot",
      "plot": "...",
      "score": 0.9234,
      "intent": "CATEGORY",
      "alpha": 0.9
    }
  ]
}
```

## Cấu hình

### Environment Variables

- `MOVIE_DATASET_PATH`: Đường dẫn đến dataset CSV (mặc định: `data/rotten_tomatoes_ENRICHED.csv`)

### Intent Classification và Alpha Values

- **TITLE** (Label 0): `alpha = 0.05` - Ưu tiên TF-IDF (95%)
- **PLOT** (Label 1): `alpha = 0.8` - Ưu tiên SBERT (80%)
- **CATEGORY** (Label 2): `alpha = 0.9` - Ưu tiên SBERT cao nhất (90%)

## Lưu ý

1. Lần đầu chạy `initialize_sbert()` sẽ mất thời gian để tạo embeddings (có thể 10-30 phút tùy dataset)
2. Embeddings sẽ được cache vào `data/movie_embeddings_ENRICHED.pt`
3. Intent classifier cần được train trước khi sử dụng
4. Nếu không có GPU, quá trình sẽ chậm hơn nhưng vẫn chạy được

## Troubleshooting

### Lỗi: "Dataset not found"
- Đảm bảo dataset CSV đã được đặt đúng đường dẫn
- Kiểm tra tên file và cấu trúc cột

### Lỗi: "TensorFlow not available"
- Cài đặt: `pip install tensorflow>=2.13.0`

### Lỗi: "sentence-transformers not available"
- Cài đặt: `pip install sentence-transformers>=2.2.0`

### Lỗi: "Intent classifier not found"
- Chạy `engine.train_intent_classifier()` để train model






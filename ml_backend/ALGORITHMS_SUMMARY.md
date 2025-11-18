# Tổng hợp các thuật toán NLP đã triển khai

## 📚 Danh sách thuật toán

### 1. Text Preprocessing (Tiền xử lý văn bản)

#### 1.1 Tokenization
**File**: `nlp_preprocessing.py` - Class `VietnameseTokenizer`

**Mô tả**: Tách văn bản thành các token (từ)

**Thuật toán**:
```python
def tokenize(text):
    1. Chuyển text về lowercase
    2. Loại bỏ ký tự đặc biệt (giữ lại dấu tiếng Việt)
    3. Tách theo khoảng trắng
    4. Loại bỏ token rỗng
    return tokens
```

**Ví dụ**:
```
Input:  "Tìm phim hành động!"
Output: ["tìm", "phim", "hành", "động"]
```

---

#### 1.2 Porter Stemmer
**File**: `nlp_preprocessing.py` - Class `PorterStemmer`

**Mô tả**: Cắt bỏ hậu tố để đưa từ về dạng gốc (tiếng Anh)

**Thuật toán**:
```python
def stem(word):
    1. Xác định measure m của từ (số lượng chuỗi VC)
    2. Loại bỏ plurals (sses → ss, ies → i, s → ∅)
    3. Loại bỏ past tense (eed, ed, ing)
    4. Loại bỏ double consonants
    return stemmed_word
```

**Công thức measure**:
```
Word = [C](VC)^m[V]
m = số lần xuất hiện của pattern VC
```

**Ví dụ**:
```
running → run
movies → movi
played → play
```

---

#### 1.3 Stop Words Removal
**File**: `nlp_preprocessing.py` - Class `StopWordsRemover`

**Mô tả**: Loại bỏ từ dừng (stop words) không mang nhiều ý nghĩa

**Danh sách stop words**:
- Tiếng Việt: và, của, có, được, trong, là, với, cho...
- Tiếng Anh: the, a, an, and, or, but, in, on, at...

**Ví dụ**:
```
Input:  ["tìm", "phim", "hành", "động", "của", "tôi"]
Output: ["phim", "hành", "động"]
```

---

### 2. TF-IDF (Term Frequency - Inverse Document Frequency)

**File**: `nlp_preprocessing.py` - Class `TFIDFVectorizer`

**Mô tả**: Tính trọng số của từ trong tài liệu

**Công thức toán học**:

```
TF(t,d) = count(t in d) / total_words(d)

IDF(t) = log(N / (df(t) + 1))
    N = tổng số documents
    df(t) = số documents chứa term t

TF-IDF(t,d) = TF(t,d) × IDF(t)
```

**Thuật toán**:
```python
def fit(documents):
    1. Xây dựng vocabulary từ tất cả documents
    2. Tính document frequency cho mỗi term
    3. Tính IDF cho mỗi term: log(N / (df + 1))

def transform(document):
    1. Tính term frequency cho document
    2. Nhân TF với IDF
    3. Return TF-IDF vector
```

**Ví dụ**:
```
Documents:
  D1: "action movie"
  D2: "comedy movie"
  D3: "action film"

TF-IDF cho "action" trong D1:
  TF = 1/2 = 0.5
  IDF = log(3/2) = 0.176
  TF-IDF = 0.5 × 0.176 = 0.088
```

---

### 3. Cosine Similarity (Độ tương đồng Cosine)

**File**: `nlp_preprocessing.py`, `nlp_semantic_similarity.py`

**Mô tả**: Tính độ tương đồng giữa 2 vectors

**Công thức toán học**:

```
cos(A, B) = (A · B) / (||A|| × ||B||)

A · B = Σ(Ai × Bi)  (dot product)

||A|| = √(Σ(Ai²))  (magnitude)
```

**Thuật toán**:
```python
def cosine_similarity(vec1, vec2):
    1. Tìm common keys giữa 2 vectors
    2. Tính dot product: Σ(vec1[k] × vec2[k])
    3. Tính magnitude của vec1: √(Σ(vec1[k]²))
    4. Tính magnitude của vec2: √(Σ(vec2[k]²))
    5. Return dot_product / (mag1 × mag2)
```

**Ví dụ**:
```
vec1 = {action: 0.5, movie: 0.3}
vec2 = {action: 0.4, movie: 0.6}

dot_product = 0.5×0.4 + 0.3×0.6 = 0.38
mag1 = √(0.5² + 0.3²) = 0.583
mag2 = √(0.4² + 0.6²) = 0.721
similarity = 0.38 / (0.583 × 0.721) = 0.904
```

---

### 4. Naive Bayes Classifier

**File**: `nlp_intent_classifier.py` - Class `NaiveBayesClassifier`

**Mô tả**: Phân loại văn bản dựa trên xác suất Bayes

**Công thức toán học**:

```
P(class|document) = P(class) × ∏ P(word|class)

P(class) = count(class) / total_documents

P(word|class) với Laplace Smoothing:
P(word|class) = (count(word, class) + 1) / (count(class) + |V|)
    |V| = vocabulary size
```

**Thuật toán**:

```python
def train(documents, labels):
    1. Tính P(class) cho mỗi class
    2. Đếm số lần xuất hiện của mỗi word trong mỗi class
    3. Tính P(word|class) với Laplace smoothing

def predict(document):
    1. Với mỗi class:
        score = log(P(class))
        Với mỗi word trong document:
            score += log(P(word|class))
    2. Return class có score cao nhất
```

**Ví dụ**:
```
Training data:
  "action movie" → search_by_genre
  "find movie" → search_by_title
  "action film" → search_by_genre

Predict: "action movie"
  P(search_by_genre|doc) = P(search_by_genre) × P(action|genre) × P(movie|genre)
  P(search_by_title|doc) = P(search_by_title) × P(action|title) × P(movie|title)
  
  → Choose class with higher probability
```

---

### 5. Support Vector Machine (SVM)

**File**: `nlp_intent_classifier.py` - Class `SimpleSVM`

**Mô tả**: Phân loại bằng cách tìm hyperplane tối ưu

**Công thức toán học**:

```
Decision function: f(x) = w·x + b

Hinge Loss: L = max(0, 1 - y × f(x))

Weight update (Gradient Descent):
  if margin < 1:
      w = w + α × (y × x - 2λ × w)
      b = b + α × y
  else:
      w = w + α × (-2λ × w)
```

**Thuật toán**:

```python
def train(documents, labels):
    1. Chuyển documents thành feature vectors
    2. Với mỗi class (one-vs-rest):
        a. Tạo binary labels (1 cho class, -1 cho others)
        b. Khởi tạo weights w và bias b
        c. Gradient descent:
            Với mỗi sample (x, y):
                margin = y × (w·x + b)
                if margin < 1:
                    w += α × (y×x - 2λ×w)
                    b += α × y
                else:
                    w += α × (-2λ×w)

def predict(document):
    1. Chuyển document thành feature vector
    2. Tính score cho mỗi class: w·x + b
    3. Return class có score cao nhất
```

**Ví dụ**:
```
Training với 2 classes:
  Class A: [1, 0, 1] → 1
  Class B: [0, 1, 0] → -1

Sau training:
  w = [0.5, -0.3, 0.4]
  b = 0.1

Predict [1, 0, 1]:
  score = 0.5×1 + (-0.3)×0 + 0.4×1 + 0.1 = 1.0
  → Class A
```

---

### 6. Levenshtein Distance (Edit Distance)

**File**: `nlp_semantic_similarity.py` - Class `LevenshteinDistance`

**Mô tả**: Tính khoảng cách chỉnh sửa giữa 2 chuỗi

**Công thức toán học**:

```
D[i,j] = min(
    D[i-1,j] + 1,        # deletion
    D[i,j-1] + 1,        # insertion
    D[i-1,j-1] + cost    # substitution
)

cost = 0 if s1[i] == s2[j] else 1
```

**Thuật toán (Dynamic Programming)**:

```python
def calculate(s1, s2):
    1. Tạo matrix D[len(s1)+1][len(s2)+1]
    2. Khởi tạo hàng đầu và cột đầu: D[i,0]=i, D[0,j]=j
    3. Với mỗi i từ 1 đến len(s1):
        Với mỗi j từ 1 đến len(s2):
            if s1[i-1] == s2[j-1]:
                cost = 0
            else:
                cost = 1
            D[i,j] = min(
                D[i-1,j] + 1,      # delete
                D[i,j-1] + 1,      # insert
                D[i-1,j-1] + cost  # substitute
            )
    4. Return D[len(s1)][len(s2)]
```

**Ví dụ**:
```
s1 = "kitten"
s2 = "sitting"

Matrix D:
      ""  s  i  t  t  i  n  g
  ""   0  1  2  3  4  5  6  7
  k    1  1  2  3  4  5  6  7
  i    2  2  1  2  3  4  5  6
  t    3  3  2  1  2  3  4  5
  t    4  4  3  2  1  2  3  4
  e    5  5  4  3  2  2  3  4
  n    6  6  5  4  3  3  2  3

Distance = 3
Operations: k→s, e→i, insert g
```

---

### 7. Jaccard Similarity

**File**: `nlp_semantic_similarity.py` - Class `JaccardSimilarity`

**Mô tả**: Tính độ tương đồng giữa 2 tập hợp

**Công thức toán học**:

```
J(A, B) = |A ∩ B| / |A ∪ B|

|A ∩ B| = số phần tử chung
|A ∪ B| = tổng số phần tử (không trùng)
```

**Thuật toán**:

```python
def calculate(set1, set2):
    1. Tính intersection: set1 ∩ set2
    2. Tính union: set1 ∪ set2
    3. Return |intersection| / |union|
```

**Ví dụ**:
```
A = {action, movie, 2024}
B = {action, film, 2024}

A ∩ B = {action, 2024}  → size = 2
A ∪ B = {action, movie, film, 2024}  → size = 4

J(A,B) = 2/4 = 0.5
```

---

### 8. N-gram Similarity

**File**: `nlp_semantic_similarity.py` - Class `NGramSimilarity`

**Mô tả**: Tính độ tương đồng dựa trên n-grams ký tự

**Thuật toán**:

```python
def get_ngrams(text, n):
    1. Chuyển text về lowercase
    2. Tạo n-grams: [text[i:i+n] for i in range(len(text)-n+1)]
    3. Return set of n-grams

def calculate(text1, text2, n):
    1. Tạo n-grams cho text1
    2. Tạo n-grams cho text2
    3. Tính Jaccard similarity giữa 2 sets n-grams
```

**Ví dụ (bigrams, n=2)**:
```
text1 = "action"
text2 = "actor"

bigrams1 = {ac, ct, ti, io, on}
bigrams2 = {ac, ct, to, or}

Common = {ac, ct}  → size = 2
Union = {ac, ct, ti, io, on, to, or}  → size = 7

Similarity = 2/7 = 0.286
```

---

### 9. Word Embeddings (Co-occurrence)

**File**: `nlp_semantic_similarity.py` - Class `WordEmbedding`

**Mô tả**: Tạo vector biểu diễn từ dựa trên co-occurrence

**Thuật toán**:

```python
def train(documents, window_size):
    1. Xây dựng vocabulary
    2. Tạo co-occurrence matrix:
        Với mỗi document:
            Với mỗi word w:
                Với mỗi context word c trong window:
                    cooccurrence[w][c] += 1
    3. Chuyển co-occurrence thành vectors:
        Với mỗi word:
            Lấy top-k co-occurring words
            Normalize vector
    4. Return word vectors

def similarity(word1, word2):
    1. Lấy vector của word1 và word2
    2. Tính cosine similarity
```

**Ví dụ**:
```
Documents:
  "action movie good"
  "action film great"
  "comedy movie funny"

Co-occurrence (window=1):
  action: {movie: 1, film: 1}
  movie: {action: 1, good: 1, comedy: 1, funny: 1}
  film: {action: 1, great: 1}

Vector cho "action":
  {movie: 0.707, film: 0.707}  (normalized)
```

---

### 10. Spell Correction

**File**: `nlp_query_expansion.py` - Class `SpellCorrector`

**Mô tả**: Sửa lỗi chính tả dựa trên edit distance và frequency

**Thuật toán**:

```python
def correct(word):
    1. Nếu word trong vocabulary → return word
    2. Tạo candidates với edit distance = 1:
        - Deletions: bỏ 1 ký tự
        - Transpositions: đổi chỗ 2 ký tự liền kề
        - Replacements: thay 1 ký tự
        - Insertions: thêm 1 ký tự
    3. Lọc candidates có trong vocabulary
    4. Nếu không có, tạo candidates với edit distance = 2
    5. Return candidate có frequency cao nhất
```

**Ví dụ**:
```
word = "acton"
vocabulary = {action, actor, act}

Edits distance 1:
  - Deletions: cton, aton, acon, actn, acto
  - Transpositions: caton, atcon, acton, actno
  - Replacements: bcton, ccton, ..., actio, ...
  - Insertions: aacton, bacton, ..., actionn, ...

Candidates in vocabulary: {action, actor}

Frequencies:
  action: 100
  actor: 50

Return: "action"
```

---

### 11. Query Expansion

**File**: `nlp_query_expansion.py` - Class `QueryExpander`

**Mô tả**: Mở rộng query với synonyms, hypernyms, hyponyms

**Thuật toán**:

```python
def expand_with_synonyms(query):
    1. Tokenize query
    2. Với mỗi token:
        if token có synonyms:
            Tạo expanded queries bằng cách thay token bằng synonyms
    3. Return list of expanded queries

def expand_with_hypernyms(query):
    1. Tokenize query
    2. Với mỗi token:
        if token có hypernym (từ tổng quát hơn):
            Tạo expanded query với hypernym
    3. Return expanded queries

def expand_with_hyponyms(query):
    1. Tokenize query
    2. Với mỗi token:
        if token có hyponyms (từ cụ thể hơn):
            Tạo expanded queries với hyponyms
    3. Return expanded queries
```

**Ví dụ**:
```
Query: "good action movie"

Synonyms:
  good → [great, excellent, amazing]
  movie → [film, cinema]

Expanded:
  - "great action movie"
  - "excellent action movie"
  - "good action film"
  - "great action film"

Hypernyms:
  action → movie

Expanded:
  - "good movie"

Hyponyms:
  movie → [action, comedy, horror]

Expanded:
  - "good action movie action"
  - "good action movie comedy"
```

---

## 📊 Tổng kết

### Số lượng thuật toán: **11 thuật toán chính**

1. ✅ Tokenization
2. ✅ Porter Stemmer
3. ✅ TF-IDF
4. ✅ Cosine Similarity
5. ✅ Naive Bayes
6. ✅ SVM (Gradient Descent)
7. ✅ Levenshtein Distance
8. ✅ Jaccard Similarity
9. ✅ N-gram Similarity
10. ✅ Word Embeddings
11. ✅ Spell Correction

### Độ phức tạp thuật toán

| Thuật toán | Time Complexity | Space Complexity |
|-----------|----------------|------------------|
| Tokenization | O(n) | O(n) |
| Porter Stemmer | O(n) | O(1) |
| TF-IDF | O(n×m) | O(v) |
| Cosine Similarity | O(min(v1,v2)) | O(1) |
| Naive Bayes | O(n×m) train, O(m) predict | O(v×c) |
| SVM | O(n×m×i) | O(m×c) |
| Levenshtein | O(n×m) | O(n×m) |
| Jaccard | O(n+m) | O(n+m) |
| N-gram | O(n+m) | O(n+m) |
| Word Embeddings | O(n×w×d) | O(v×d) |
| Spell Correction | O(n×26^2) | O(v) |

Trong đó:
- n, m: độ dài chuỗi/document
- v: vocabulary size
- c: số classes
- i: số iterations
- w: window size
- d: embedding dimension

### Files tương ứng

```
ml_backend/
├── nlp_preprocessing.py          # Algorithms 1-4
├── nlp_intent_classifier.py      # Algorithms 5-6
├── nlp_semantic_similarity.py    # Algorithms 7-10
├── nlp_query_expansion.py        # Algorithm 11
├── nlp_ner.py                    # Entity Recognition
├── nlp_service.py                # FastAPI Service
└── test_nlp_algorithms.py        # Test all algorithms
```

## 🎓 Áp dụng kiến thức môn học

Tất cả các thuật toán trên đều được code từ đầu (from scratch) để:

1. **Hiểu rõ cách hoạt động** của từng thuật toán
2. **Áp dụng kiến thức** môn Ngôn ngữ tự nhiên
3. **Tùy chỉnh** theo nhu cầu cụ thể của dự án
4. **Không phụ thuộc** vào thư viện NLP có sẵn

Đây là một hệ thống NLP hoàn chỉnh cho tìm kiếm phim bằng giọng nói! 🚀

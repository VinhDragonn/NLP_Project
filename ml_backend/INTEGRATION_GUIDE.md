# Hướng dẫn tích hợp NLP Service với Flutter App

## Tổng quan

Tài liệu này hướng dẫn cách tích hợp NLP Service (Python backend) với Flutter app để thay thế việc sử dụng thư viện `speech_to_text` bằng các thuật toán NLP tự code.

## Kiến trúc mới

```
Flutter App (Frontend)
    ↓
Speech-to-Text (Device API)
    ↓
NLP Service (Python Backend) ← THUẬT TOÁN TỰ CODE
    ├── Preprocessing
    ├── Intent Classification
    ├── NER
    ├── Semantic Analysis
    └── Query Expansion
    ↓
TMDB API (Movie Database)
    ↓
Results to Flutter App
```

## Bước 1: Chạy NLP Service

### Cài đặt dependencies

```bash
cd ml_backend
pip install -r requirements.txt
```

### Chạy service

```bash
# Chạy trên port 8001
python nlp_service.py

# Hoặc chỉ định port khác
NLP_PORT=8002 python nlp_service.py
```

### Kiểm tra service

```bash
curl http://localhost:8001/health
```

## Bước 2: Tạo NLP Service Client trong Flutter

Tạo file `lib/services/nlp_api_service.dart`:

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class NLPApiService {
  // Thay đổi URL này theo môi trường của bạn
  final String baseUrl = 'http://localhost:8001';
  
  /// Xử lý voice search với NLP algorithms
  Future<Map<String, dynamic>> processVoiceSearch({
    required String voiceText,
    String language = 'vi',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/nlp/voice-search'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'voice_text': voiceText,
          'language': language,
        }),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('NLP Service error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error calling NLP service: $e');
      rethrow;
    }
  }
  
  /// Phân loại intent
  Future<Map<String, dynamic>> classifyIntent(String text) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/nlp/intent'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'text': text}),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Intent classification failed');
    }
  }
  
  /// Tính độ tương đồng
  Future<Map<String, dynamic>> calculateSimilarity({
    required String text1,
    required String text2,
    String method = 'all',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/nlp/similarity'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'text1': text1,
        'text2': text2,
        'method': method,
      }),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Similarity calculation failed');
    }
  }
  
  /// Fuzzy matching cho tên phim
  Future<Map<String, dynamic>> fuzzyMatch({
    required String query,
    required List<String> candidates,
    double threshold = 0.6,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/nlp/fuzzy-match'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'query': query,
        'candidates': candidates,
        'threshold': threshold,
      }),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Fuzzy matching failed');
    }
  }
  
  /// Mở rộng query
  Future<Map<String, dynamic>> expandQuery({
    required String query,
    int maxExpansions = 10,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/nlp/expand-query'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'query': query,
        'max_expansions': maxExpansions,
      }),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Query expansion failed');
    }
  }
}
```

## Bước 3: Cập nhật Voice Search Widget

Cập nhật `lib/RepeatedFunction/google_voice_search_widget.dart`:

```dart
import 'package:r08fullmovieapp/services/nlp_api_service.dart';

class CustomNLPVoiceSearchWidget extends StatefulWidget {
  final Function(String, Map<String, dynamic>) onResult;
  
  const CustomNLPVoiceSearchWidget({
    Key? key,
    required this.onResult,
  }) : super(key: key);

  @override
  State<CustomNLPVoiceSearchWidget> createState() => _CustomNLPVoiceSearchWidgetState();
}

class _CustomNLPVoiceSearchWidgetState extends State<CustomNLPVoiceSearchWidget> {
  final NLPApiService _nlpService = NLPApiService();
  final SpeechToText _speechToText = SpeechToText();
  bool _isListening = false;
  bool _isProcessing = false;
  
  Future<void> _startVoiceSearch() async {
    // Bước 1: Nhận dạng giọng nói (sử dụng device API)
    bool available = await _speechToText.initialize();
    
    if (!available) {
      _showToast("Speech recognition not available");
      return;
    }
    
    setState(() {
      _isListening = true;
    });
    
    await _speechToText.listen(
      onResult: (result) async {
        if (result.finalResult) {
          String recognizedText = result.recognizedWords;
          
          setState(() {
            _isListening = false;
            _isProcessing = true;
          });
          
          try {
            // Bước 2: Xử lý với NLP algorithms (Python backend)
            Map<String, dynamic> nlpResult = await _nlpService.processVoiceSearch(
              voiceText: recognizedText,
              language: 'vi',
            );
            
            setState(() {
              _isProcessing = false;
            });
            
            // Bước 3: Trả kết quả về
            widget.onResult(recognizedText, nlpResult);
            
            // Hiển thị kết quả NLP
            _showNLPResultDialog(recognizedText, nlpResult);
            
          } catch (e) {
            setState(() {
              _isProcessing = false;
            });
            _showToast("NLP processing error: $e");
          }
        }
      },
      localeId: 'vi-VN',
    );
  }
  
  void _showNLPResultDialog(String voiceText, Map<String, dynamic> nlpResult) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color.fromRGBO(25, 25, 25, 1),
        title: Row(
          children: [
            Icon(Icons.psychology, color: Colors.green),
            SizedBox(width: 8),
            Text('NLP Analysis', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('Voice Input:', voiceText),
              SizedBox(height: 8),
              _buildInfoRow('Processed Query:', nlpResult['processed_query']),
              SizedBox(height: 8),
              _buildInfoRow('Intent:', nlpResult['intent']),
              SizedBox(height: 8),
              _buildInfoRow('Confidence:', '${(nlpResult['confidence'] * 100).toStringAsFixed(1)}%'),
              SizedBox(height: 8),
              if (nlpResult['entities'] != null) ...[
                Text('Entities:', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ...nlpResult['entities'].entries.map((entry) {
                  if (entry.value is List && (entry.value as List).isNotEmpty) {
                    return Padding(
                      padding: EdgeInsets.only(left: 16, top: 4),
                      child: Text(
                        '${entry.key}: ${entry.value.join(", ")}',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    );
                  }
                  return SizedBox.shrink();
                }).toList(),
              ],
              SizedBox(height: 8),
              if (nlpResult['expanded_queries'] != null) ...[
                Text('Expanded Queries:', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ...((nlpResult['expanded_queries'] as List).take(3)).map((query) {
                  return Padding(
                    padding: EdgeInsets.only(left: 16, top: 4),
                    child: Text(
                      '• $query',
                      style: TextStyle(color: Colors.amber, fontSize: 11),
                    ),
                  );
                }).toList(),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: Colors.amber)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Thực hiện tìm kiếm với processed query
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: Text('Search'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey, fontSize: 12)),
        Text(value, style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _startVoiceSearch,
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: _isProcessing 
              ? Colors.green.withOpacity(0.2)
              : (_isListening ? Colors.red.withOpacity(0.2) : Colors.amber.withOpacity(0.2)),
          shape: BoxShape.circle,
          border: Border.all(
            color: _isProcessing ? Colors.green : (_isListening ? Colors.red : Colors.amber),
            width: 3,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              _isListening ? Icons.mic : Icons.mic_none,
              color: _isProcessing ? Colors.green : (_isListening ? Colors.red : Colors.amber),
              size: 32,
            ),
            if (_isProcessing)
              Positioned(
                top: 5,
                right: 5,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.psychology, color: Colors.white, size: 8),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
```

## Bước 4: Sử dụng trong Search Screen

Cập nhật `lib/RepeatedFunction/searchbarfunc.dart`:

```dart
import 'package:r08fullmovieapp/services/nlp_api_service.dart';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final NLPApiService _nlpService = NLPApiService();
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  
  Future<void> _handleVoiceSearchResult(String voiceText, Map<String, dynamic> nlpResult) async {
    // Lấy processed query từ NLP
    String processedQuery = nlpResult['processed_query'];
    String intent = nlpResult['intent'];
    Map<String, dynamic> searchParams = nlpResult['search_parameters'];
    
    // Cập nhật search field
    _searchController.text = processedQuery;
    
    // Thực hiện tìm kiếm dựa trên intent và parameters
    await _performSmartSearch(processedQuery, intent, searchParams);
  }
  
  Future<void> _performSmartSearch(
    String query,
    String intent,
    Map<String, dynamic> params,
  ) async {
    // Build TMDB API URL dựa trên intent
    String apiUrl = _buildSearchUrl(query, intent, params);
    
    // Call TMDB API
    final response = await http.get(Uri.parse(apiUrl));
    
    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      setState(() {
        _searchResults = data['results'];
      });
    }
  }
  
  String _buildSearchUrl(String query, String intent, Map<String, dynamic> params) {
    String baseUrl = 'https://api.themoviedb.org/3';
    String apiKey = dotenv.env['apikey'] ?? '';
    
    // Xây dựng URL dựa trên intent
    switch (intent) {
      case 'search_by_genre':
        // Tìm theo thể loại
        String genreId = _getGenreId(params['genres']?.first ?? '');
        return '$baseUrl/discover/movie?api_key=$apiKey&with_genres=$genreId';
        
      case 'search_by_year':
        // Tìm theo năm
        String year = params['years']?.first ?? '';
        return '$baseUrl/discover/movie?api_key=$apiKey&year=$year';
        
      case 'search_popular':
        // Tìm phim phổ biến
        return '$baseUrl/movie/popular?api_key=$apiKey';
        
      case 'search_high_rating':
        // Tìm phim đánh giá cao
        return '$baseUrl/discover/movie?api_key=$apiKey&sort_by=vote_average.desc&vote_count.gte=1000';
        
      default:
        // Tìm kiếm chung
        return '$baseUrl/search/multi?api_key=$apiKey&query=${Uri.encodeComponent(query)}';
    }
  }
  
  String _getGenreId(String genreName) {
    Map<String, String> genreMap = {
      'action': '28',
      'adventure': '12',
      'animation': '16',
      'comedy': '35',
      'crime': '80',
      'documentary': '99',
      'drama': '18',
      'family': '10751',
      'fantasy': '14',
      'horror': '27',
      'romance': '10749',
      'scifi': '878',
      'sci-fi': '878',
      'thriller': '53',
    };
    return genreMap[genreName.toLowerCase()] ?? '';
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search movies...',
            border: InputBorder.none,
          ),
          onSubmitted: (query) async {
            // Xử lý text search với NLP
            var nlpResult = await _nlpService.processVoiceSearch(
              voiceText: query,
              language: 'en',
            );
            await _handleVoiceSearchResult(query, nlpResult);
          },
        ),
        actions: [
          // Voice search button
          CustomNLPVoiceSearchWidget(
            onResult: _handleVoiceSearchResult,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          var movie = _searchResults[index];
          return ListTile(
            title: Text(movie['title'] ?? movie['name'] ?? ''),
            subtitle: Text(movie['overview'] ?? ''),
          );
        },
      ),
    );
  }
}
```

## Bước 5: Test NLP Algorithms

Chạy test script để xem các thuật toán hoạt động:

```bash
cd ml_backend
python test_nlp_algorithms.py
```

## Bước 6: Deploy

### Development (Local)

```bash
# Terminal 1: Run NLP Service
cd ml_backend
python nlp_service.py

# Terminal 2: Run Flutter App
flutter run
```

### Production

1. Deploy NLP Service lên server (Heroku, AWS, GCP, etc.)
2. Cập nhật `baseUrl` trong `NLPApiService`
3. Build Flutter app

## So sánh: Trước và Sau

### Trước (Sử dụng thư viện)

```dart
// Chỉ sử dụng speech_to_text library
await _speechToText.listen(
  onResult: (result) {
    String text = result.recognizedWords;
    // Tìm kiếm trực tiếp với text
    searchMovies(text);
  }
);
```

### Sau (Sử dụng thuật toán tự code)

```dart
// Sử dụng custom NLP algorithms
await _speechToText.listen(
  onResult: (result) async {
    String text = result.recognizedWords;
    
    // Xử lý với NLP algorithms
    var nlpResult = await _nlpService.processVoiceSearch(
      voiceText: text,
      language: 'vi',
    );
    
    // Tìm kiếm thông minh dựa trên:
    // - Intent classification (Naive Bayes + SVM)
    // - Entity recognition (NER)
    // - Query expansion (Synonyms)
    // - Spell correction
    // - Semantic similarity
    smartSearch(nlpResult);
  }
);
```

## Lợi ích của việc tự code thuật toán

1. **Hiểu rõ cách hoạt động**: Biết chính xác thuật toán làm gì
2. **Tùy chỉnh được**: Có thể điều chỉnh theo nhu cầu cụ thể
3. **Áp dụng kiến thức**: Sử dụng kiến thức môn Ngôn ngữ tự nhiên
4. **Độc lập**: Không phụ thuộc vào thư viện bên ngoài
5. **Học tập**: Hiểu sâu về NLP và ML

## Troubleshooting

### Lỗi kết nối NLP Service

```dart
// Thêm error handling
try {
  var result = await _nlpService.processVoiceSearch(voiceText: text);
} catch (e) {
  // Fallback to simple search
  simpleSearch(text);
}
```

### NLP Service chậm

- Sử dụng caching
- Tối ưu hóa thuật toán
- Deploy service gần user (CDN)

### Độ chính xác thấp

- Train thêm data
- Điều chỉnh hyperparameters
- Kết hợp nhiều thuật toán

## Kết luận

Bây giờ bạn đã có một hệ thống NLP hoàn chỉnh với các thuật toán tự code:

✅ Tokenization & Stemming  
✅ TF-IDF Vectorization  
✅ Naive Bayes Classifier  
✅ SVM Classifier  
✅ Named Entity Recognition  
✅ Semantic Similarity (Levenshtein, Jaccard, Cosine, N-gram)  
✅ Query Expansion & Spell Correction  
✅ FastAPI Service  

Tất cả đều được code từ đầu để áp dụng kiến thức môn Ngôn ngữ tự nhiên! 🎓

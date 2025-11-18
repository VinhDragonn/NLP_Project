# Hướng dẫn tích hợp NLP Voice Search vào Flutter

## ✅ Đã tạo các file

1. **`lib/services/nlp_api_service.dart`** - Service gọi NLP API
2. **`lib/services/nlp_voice_service.dart`** - Voice service tích hợp NLP
3. **`lib/widgets/nlp_voice_search_button.dart`** - Widget button voice search

## 🔧 Cách sử dụng

### Bước 1: Thêm dependency vào pubspec.yaml

```yaml
dependencies:
  http: ^1.1.0
  speech_to_text: ^6.3.0
  permission_handler: ^11.0.0
  fluttertoast: ^8.2.2
```

Chạy:
```bash
flutter pub get
```

### Bước 2: Sử dụng trong Screen

#### Ví dụ 1: Trong Search Screen

```dart
import 'package:flutter/material.dart';
import 'package:r08fullmovieapp/widgets/nlp_voice_search_button.dart';
import 'package:r08fullmovieapp/services/nlp_voice_service.dart';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];

  void _handleVoiceSearchResult(String recognizedText, Map<String, dynamic> nlpResult) {
    // Lấy processed query từ NLP
    String processedQuery = nlpResult['processed_query'];
    String intent = nlpResult['intent'];
    Map<String, dynamic> searchParams = nlpResult['search_parameters'];
    
    // Cập nhật search field
    setState(() {
      _searchController.text = processedQuery;
    });
    
    // Thực hiện tìm kiếm thông minh dựa trên intent
    _performSmartSearch(processedQuery, intent, searchParams);
  }

  void _performSmartSearch(
    String query,
    String intent,
    Map<String, dynamic> params,
  ) async {
    // TODO: Build TMDB API URL dựa trên intent và params
    // Ví dụ:
    // - search_by_genre → /discover/movie?with_genres=...
    // - search_by_year → /discover/movie?year=...
    // - search_popular → /movie/popular
    // - search_high_rating → /discover/movie?sort_by=vote_average.desc
    
    print('🔍 Searching with:');
    print('   Query: $query');
    print('   Intent: $intent');
    print('   Params: $params');
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
            prefixIcon: Icon(Icons.search),
          ),
          onSubmitted: (query) async {
            // Xử lý text search với NLP
            var nlpResult = await NLPVoiceService.processTextSearch(query);
            _handleVoiceSearchResult(query, nlpResult);
          },
        ),
        actions: [
          // Voice search button với NLP
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: NLPVoiceSearchButton(
              onResult: _handleVoiceSearchResult,
              language: 'vi-VN',
            ),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          var movie = _searchResults[index];
          return ListTile(
            title: Text(movie['title'] ?? ''),
            subtitle: Text(movie['overview'] ?? ''),
          );
        },
      ),
    );
  }
}
```

#### Ví dụ 2: Floating Voice Button

```dart
import 'package:flutter/material.dart';
import 'package:r08fullmovieapp/widgets/nlp_voice_search_button.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Movies')),
      body: Center(child: Text('Movie List')),
      floatingActionButton: NLPVoiceSearchButton(
        onResult: (recognizedText, nlpResult) {
          // Xử lý kết quả
          print('Voice: $recognizedText');
          print('Intent: ${nlpResult['intent']}');
          
          // Navigate to search screen với kết quả
          Navigator.pushNamed(
            context,
            '/search',
            arguments: nlpResult,
          );
        },
      ),
    );
  }
}
```

### Bước 3: Build TMDB Search URL dựa trên Intent

```dart
String buildSearchUrl(String query, String intent, Map<String, dynamic> params) {
  String baseUrl = 'https://api.themoviedb.org/3';
  String apiKey = 'YOUR_TMDB_API_KEY';
  
  switch (intent) {
    case 'search_by_genre':
      // Tìm theo thể loại
      List<String> genres = params['genres'] ?? [];
      if (genres.isNotEmpty) {
        String genreId = getGenreId(genres.first);
        return '$baseUrl/discover/movie?api_key=$apiKey&with_genres=$genreId';
      }
      break;
      
    case 'search_by_year':
      // Tìm theo năm
      List<String> years = params['years'] ?? [];
      if (years.isNotEmpty) {
        return '$baseUrl/discover/movie?api_key=$apiKey&year=${years.first}';
      }
      break;
      
    case 'search_popular':
      // Tìm phim phổ biến
      return '$baseUrl/movie/popular?api_key=$apiKey';
      
    case 'search_high_rating':
      // Tìm phim đánh giá cao
      return '$baseUrl/discover/movie?api_key=$apiKey&sort_by=vote_average.desc&vote_count.gte=1000';
      
    case 'search_by_actor':
      // Tìm theo diễn viên (cần search person ID trước)
      // TODO: Implement person search
      break;
      
    default:
      // Tìm kiếm chung
      return '$baseUrl/search/multi?api_key=$apiKey&query=${Uri.encodeComponent(query)}';
  }
  
  return '$baseUrl/search/multi?api_key=$apiKey&query=${Uri.encodeComponent(query)}';
}

String getGenreId(String genreName) {
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
    'war': '10752',
    'western': '37',
  };
  return genreMap[genreName.toLowerCase()] ?? '';
}
```

## 🧪 Test

### Test 1: Kiểm tra NLP Service

```dart
import 'package:r08fullmovieapp/services/nlp_api_service.dart';

void testNLPService() async {
  final nlpService = NLPApiService();
  
  // Test health check
  bool isHealthy = await nlpService.checkHealth();
  print('NLP Service healthy: $isHealthy');
  
  // Test voice search
  var result = await nlpService.processVoiceSearch(
    voiceText: 'Tìm phim hành động mới nhất',
    language: 'vi',
  );
  
  print('Intent: ${result['intent']}');
  print('Confidence: ${result['confidence']}');
  print('Processed: ${result['processed_query']}');
}
```

### Test 2: Test Voice Service

```dart
import 'package:r08fullmovieapp/services/nlp_voice_service.dart';

void testVoiceService() async {
  // Initialize
  bool initialized = await NLPVoiceService.initializeSpeech();
  print('Speech initialized: $initialized');
  
  // Start listening
  await NLPVoiceService.startListening(
    onResult: (text, nlpResult) {
      print('Recognized: $text');
      print('NLP Result: $nlpResult');
    },
    onStatusChange: (status) {
      print('Status: $status');
    },
  );
}
```

## 🔧 Cấu hình

### Thay đổi URL của NLP Service

Trong file `lib/services/nlp_api_service.dart`, dòng 10:

```dart
// Localhost (development)
final String baseUrl = 'http://localhost:8002';

// Hoặc IP máy chạy backend
final String baseUrl = 'http://192.168.1.100:8002';

// Hoặc server production
final String baseUrl = 'https://your-nlp-service.com';
```

### Thay đổi ngôn ngữ

```dart
NLPVoiceSearchButton(
  onResult: _handleResult,
  language: 'en-US', // Tiếng Anh
  // language: 'vi-VN', // Tiếng Việt (mặc định)
)
```

## 📊 So sánh: Trước và Sau

### ❌ Trước (Dùng thư viện)

```dart
// Chỉ có speech-to-text
await _speechToText.listen(
  onResult: (result) {
    String text = result.recognizedWords;
    // Tìm kiếm trực tiếp với text
    searchMovies(text);
  }
);
```

### ✅ Sau (Dùng NLP algorithms tự code)

```dart
// Speech-to-text + NLP algorithms
await NLPVoiceService.startListening(
  onResult: (text, nlpResult) {
    // Có đầy đủ thông tin từ NLP:
    // - Intent classification (Naive Bayes + SVM)
    // - Entity recognition (NER)
    // - Query expansion (Synonyms)
    // - Spell correction
    // - Semantic similarity
    
    String intent = nlpResult['intent'];
    String processedQuery = nlpResult['processed_query'];
    Map entities = nlpResult['entities'];
    
    // Tìm kiếm thông minh
    smartSearch(intent, processedQuery, entities);
  },
);
```

## 🎯 Lợi ích

1. **Hiểu rõ ý định người dùng** - Intent classification
2. **Trích xuất thông tin** - NER (genres, years, actors)
3. **Xử lý lỗi chính tả** - Spell correction
4. **Mở rộng tìm kiếm** - Query expansion với synonyms
5. **Tìm kiếm mờ** - Fuzzy matching cho tên phim
6. **Tính độ tương đồng** - Semantic similarity

## 🚀 Chạy

1. **Backend (Python):**
   ```bash
   cd ml_backend
   python nlp_service.py
   # Hoặc: $env:NLP_PORT=8002; python nlp_service.py
   ```

2. **Frontend (Flutter):**
   ```bash
   flutter run
   ```

## 🐛 Troubleshooting

### Lỗi: NLP Service không khả dụng

- Kiểm tra backend có đang chạy không
- Kiểm tra URL trong `nlp_api_service.dart`
- Kiểm tra firewall

### Lỗi: Permission denied

- Cấp quyền microphone trong AndroidManifest.xml
- Request permission trong code

### Lỗi: Timeout

- Tăng timeout trong API calls
- Kiểm tra network connection

## 📝 Ghi chú

- NLP Service phải chạy trước khi test Flutter app
- Thay đổi `baseUrl` nếu chạy trên máy khác
- Có thể fallback về simple search nếu NLP service không khả dụng

Chúc bạn thành công! 🎉

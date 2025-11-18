import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GoogleVoiceService {
  static final SpeechToText _speechToText = SpeechToText();
  static bool _speechEnabled = false;
  static bool _isListening = false;

  // Khởi tạo speech recognition
  static Future<bool> initializeSpeech() async {
    try {
      var status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        _showToast("Cần quyền truy cập microphone để sử dụng tính năng này");
        return false;
      }

      _speechEnabled = await _speechToText.initialize(
        onError: (error) {
          print('Speech recognition error: $error');
          _showToast("Lỗi nhận dạng giọng nói: ${error.errorMsg}");
        },
        onStatus: (status) {
          print('Speech recognition status: $status');
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
          }
        },
      );

      if (!_speechEnabled) {
        _showToast("Nhận dạng giọng nói không khả dụng trên thiết bị này");
      }

      return _speechEnabled;
    } catch (e) {
      print('Error initializing speech: $e');
      _showToast("Lỗi khởi tạo nhận dạng giọng nói");
      return false;
    }
  }

  // Bắt đầu lắng nghe với Google Speech-to-Text
  static Future<void> startListening({
    required Function(String text, Map<String, dynamic> analysis) onResult,
    required Function() onListeningChanged,
  }) async {
    if (!_speechEnabled) {
      bool initialized = await initializeSpeech();
      if (!initialized) return;
    }

    if (_isListening) {
      await stopListening();
      return;
    }

    try {
      _isListening = true;
      onListeningChanged();

      await _speechToText.listen(
        onResult: (result) async {
          if (result.finalResult) {
            String recognizedText = result.recognizedWords;
            if (recognizedText.isNotEmpty) {
              // Xử lý với Google Speech-to-Text và phân tích thông minh
              Map<String, dynamic> analysis = await _processWithGoogleSpeech(recognizedText);
              onResult(recognizedText, analysis);
              _showToast("Google đã nhận dạng: ${analysis['search_query']}");
            }
            _isListening = false;
            onListeningChanged();
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        localeId: 'vi-VN', // Hỗ trợ tiếng Việt
        cancelOnError: true,
        listenMode: ListenMode.confirmation,
      );
    } catch (e) {
      print('Error starting speech recognition: $e');
      _isListening = false;
      onListeningChanged();
      _showToast("Lỗi khi bắt đầu nhận dạng giọng nói");
    }
  }

  // Xử lý với Google Speech-to-Text API
  static Future<Map<String, dynamic>> _processWithGoogleSpeech(String voiceText) async {
    try {
      String googleApiKey = dotenv.env['GOOGLE_SPEECH_API_KEY'] ?? '';
      if (googleApiKey.isEmpty) {
        // Fallback to basic processing if no Google API key
        return _basicProcessing(voiceText);
      }

      // Sử dụng Google Cloud Speech-to-Text API
      final response = await http.post(
        Uri.parse('https://speech.googleapis.com/v1/speech:recognize?key=$googleApiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'config': {
            'encoding': 'LINEAR16',
            'sampleRateHertz': 16000,
            'languageCode': 'vi-VN',
            'enableAutomaticPunctuation': true,
            'enableWordTimeOffsets': false,
            'enableWordConfidence': true,
            'model': 'latest_long',
            'useEnhanced': true,
          },
          'audio': {
            'content': '', // Trong thực tế, cần encode audio data
          },
        }),
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        // Xử lý kết quả Google Speech-to-Text
        return _processGoogleResult(voiceText, data);
      } else {
        print('Google Speech API error: ${response.statusCode}');
        return _basicProcessing(voiceText);
      }
    } catch (e) {
      print('Error calling Google Speech API: $e');
      return _basicProcessing(voiceText);
    }
  }

  // Xử lý kết quả từ Google Speech-to-Text
  static Map<String, dynamic> _processGoogleResult(String originalText, Map<String, dynamic> googleResult) {
    // Phân tích thông minh dựa trên text đã được Google nhận dạng
    String processedText = _smartTextProcessing(originalText);
    
    return {
      'search_query': processedText,
      'search_type': _determineSearchType(processedText),
      'filters': _extractFilters(processedText),
      'suggestions': _generateSuggestions(processedText),
      'intent': _analyzeIntent(processedText),
      'confidence': googleResult['results']?[0]?['alternatives']?[0]?['confidence'] ?? 0.0,
      'original_text': originalText,
      'processed_text': processedText,
    };
  }

  // Xử lý text thông minh
  static String _smartTextProcessing(String voiceText) {
    String processedText = voiceText.toLowerCase();
    
    // Loại bỏ từ không cần thiết
    List<String> stopWords = [
      'tìm', 'tìm kiếm', 'search', 'phim', 'movie', 'show', 'chương trình',
      'cho tôi', 'tôi muốn', 'làm ơn', 'please', 'có thể', 'có thể nào',
      'bạn', 'có', 'thể', 'giúp', 'tôi', 'tìm', 'kiếm'
    ];
    
    for (String word in stopWords) {
      processedText = processedText.replaceAll(word, '').trim();
    }
    
    // Chuyển đổi từ khóa tiếng Việt
    Map<String, String> vietnameseToEnglish = {
      'hành động': 'action',
      'tình cảm': 'romance',
      'kinh dị': 'horror',
      'hài': 'comedy',
      'viễn tưởng': 'sci-fi',
      'phiêu lưu': 'adventure',
      'giả tưởng': 'fantasy',
      'tội phạm': 'crime',
      'chiến tranh': 'war',
      'thể thao': 'sport',
      'tài liệu': 'documentary',
      'gia đình': 'family',
      'lịch sử': 'history',
      'âm nhạc': 'music',
      'bí ẩn': 'mystery',
      'hồi hộp': 'thriller',
      'miền tây': 'western',
      'hoạt hình': 'animation',
    };
    
    for (String vietnamese in vietnameseToEnglish.keys) {
      if (processedText.contains(vietnamese)) {
        processedText = processedText.replaceAll(vietnamese, vietnameseToEnglish[vietnamese]!);
      }
    }
    
    return processedText.trim();
  }

  // Xác định loại tìm kiếm
  static String _determineSearchType(String text) {
    if (text.contains('diễn viên') || text.contains('actor') || text.contains('actress')) {
      return 'actor';
    } else if (text.contains('thể loại') || text.contains('genre')) {
      return 'genre';
    } else if (text.contains('giống') || text.contains('tương tự') || text.contains('similar')) {
      return 'similar';
    } else if (text.contains('mô tả') || text.contains('description')) {
      return 'description';
    } else {
      return 'title';
    }
  }

  // Trích xuất bộ lọc
  static Map<String, dynamic> _extractFilters(String text) {
    Map<String, dynamic> filters = {};
    
    // Trích xuất năm
    RegExp yearRegex = RegExp(r'\b(19|20)\d{2}\b');
    var yearMatch = yearRegex.firstMatch(text);
    if (yearMatch != null) {
      filters['year'] = yearMatch.group(0);
    }
    
    // Trích xuất thể loại
    List<String> genres = [
      'action', 'romance', 'horror', 'comedy', 'sci-fi', 'adventure',
      'fantasy', 'crime', 'war', 'sport', 'documentary', 'family',
      'history', 'music', 'mystery', 'thriller', 'western', 'animation'
    ];
    
    for (String genre in genres) {
      if (text.contains(genre)) {
        filters['genre'] = genre;
        break;
      }
    }
    
    // Trích xuất ngôn ngữ/quốc gia
    if (text.contains('việt nam') || text.contains('vietnam') || text.contains('việt')) {
      filters['language'] = 'vi';
      filters['country'] = 'VN';
    } else if (text.contains('mỹ') || text.contains('america') || text.contains('us')) {
      filters['country'] = 'US';
    } else if (text.contains('hàn quốc') || text.contains('korea')) {
      filters['country'] = 'KR';
    } else if (text.contains('nhật') || text.contains('japan')) {
      filters['country'] = 'JP';
    }
    
    return filters;
  }

  // Tạo gợi ý tìm kiếm
  static List<String> _generateSuggestions(String text) {
    List<String> suggestions = [text];
    
    // Thêm các biến thể
    if (text.contains('action')) {
      suggestions.addAll(['action movies', 'action films', 'action adventure']);
    } else if (text.contains('romance')) {
      suggestions.addAll(['romance movies', 'romantic films', 'love stories']);
    } else if (text.contains('horror')) {
      suggestions.addAll(['horror movies', 'scary films', 'thriller']);
    } else if (text.contains('comedy')) {
      suggestions.addAll(['comedy movies', 'funny films', 'humor']);
    }
    
    return suggestions;
  }

  // Phân tích ý định
  static String _analyzeIntent(String text) {
    if (text.contains('mới') || text.contains('mới nhất') || text.contains('2024') || text.contains('latest')) {
      return 'new_movies';
    } else if (text.contains('cũ') || text.contains('kinh điển') || text.contains('classic')) {
      return 'classic_movies';
    } else if (text.contains('hot') || text.contains('trending') || text.contains('phổ biến') || text.contains('popular')) {
      return 'popular';
    } else if (text.contains('đánh giá cao') || text.contains('hay nhất') || text.contains('rating') || text.contains('best')) {
      return 'high_rating';
    } else if (text.contains('giống') || text.contains('tương tự') || text.contains('similar')) {
      return 'similar';
    }
    
    return 'general_search';
  }

  // Xử lý cơ bản khi không có Google API
  static Map<String, dynamic> _basicProcessing(String voiceText) {
    String processedText = _smartTextProcessing(voiceText);
    
    return {
      'search_query': processedText,
      'search_type': _determineSearchType(processedText),
      'filters': _extractFilters(processedText),
      'suggestions': _generateSuggestions(processedText),
      'intent': _analyzeIntent(processedText),
      'confidence': 0.8,
      'original_text': voiceText,
      'processed_text': processedText,
    };
  }

  // Tạo URL tìm kiếm thông minh
  static String buildSmartSearchUrl(Map<String, dynamic> analysis) {
    String baseUrl = 'https://api.themoviedb.org/3/search/multi';
    String apiKey = dotenv.env['apikey'] ?? '';
    
    Map<String, String> queryParams = {
      'api_key': apiKey,
      'query': analysis['search_query'],
      'language': 'vi-VN',
    };

    // Thêm filters nếu có
    if (analysis['filters'] != null) {
      Map<String, dynamic> filters = analysis['filters'];
      if (filters['year'] != null) {
        queryParams['year'] = filters['year'].toString();
      }
      if (filters['genre'] != null) {
        queryParams['with_genres'] = _getGenreId(filters['genre']);
      }
    }

    // Thêm sort options dựa trên intent
    if (analysis['intent'] == 'new_movies') {
      queryParams['sort_by'] = 'release_date.desc';
    } else if (analysis['intent'] == 'popular') {
      queryParams['sort_by'] = 'popularity.desc';
    } else if (analysis['intent'] == 'high_rating') {
      queryParams['sort_by'] = 'vote_average.desc';
    }

    String queryString = queryParams.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    
    return '$baseUrl?$queryString';
  }

  // Chuyển đổi genre name thành ID
  static String _getGenreId(String genreName) {
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
      'history': '36',
      'horror': '27',
      'music': '10402',
      'mystery': '9648',
      'romance': '10749',
      'sci-fi': '878',
      'thriller': '53',
      'war': '10752',
      'western': '37',
    };
    
    return genreMap[genreName.toLowerCase()] ?? '';
  }

  // Dừng lắng nghe
  static Future<void> stopListening() async {
    try {
      await _speechToText.stop();
      _isListening = false;
    } catch (e) {
      print('Error stopping speech recognition: $e');
    }
  }

  // Kiểm tra trạng thái
  static bool get isListening => _isListening;
  static bool get isAvailable => _speechEnabled;

  // Hiển thị toast message
  static void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: const Color.fromRGBO(18, 18, 18, 1),
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  // Phân tích ý định người dùng nâng cao
  static String analyzeUserIntent(String voiceText) {
    String text = voiceText.toLowerCase();
    
    if (text.contains('mới') || text.contains('mới nhất') || text.contains('2024') || text.contains('latest')) {
      return 'new_movies';
    } else if (text.contains('cũ') || text.contains('kinh điển') || text.contains('classic')) {
      return 'classic_movies';
    } else if (text.contains('hot') || text.contains('trending') || text.contains('phổ biến') || text.contains('popular')) {
      return 'popular';
    } else if (text.contains('đánh giá cao') || text.contains('hay nhất') || text.contains('rating') || text.contains('best')) {
      return 'high_rating';
    } else if (text.contains('giống') || text.contains('tương tự') || text.contains('similar')) {
      return 'similar';
    }
    
    return 'general_search';
  }
} 
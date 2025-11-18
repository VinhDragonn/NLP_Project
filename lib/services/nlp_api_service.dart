import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service để gọi NLP API (Python backend)
/// Thay thế việc sử dụng thư viện speech_to_text
class NLPApiService {
  // URL của NLP Service (đang chạy trên port 8002)
  // IP máy tính: 192.168.100.219 (cập nhật theo ipconfig)
  // Nếu không kết nối được, chạy: ipconfig | findstr /i "IPv4" để tìm IP mới
  final String baseUrl = 'http://192.168.100.219:8002';
  
  /// Xử lý voice search với tất cả thuật toán NLP
  /// 
  /// Thuật toán được sử dụng:
  /// - Tokenization & Stemming
  /// - TF-IDF
  /// - Naive Bayes + SVM (Intent Classification)
  /// - Named Entity Recognition (NER)
  /// - Semantic Similarity
  /// - Query Expansion
  /// - Spell Correction
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
      ).timeout(const Duration(seconds: 60)); // Timeout 60s cho NLP processing (có thể mất 7-8s cho lần đầu)
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('NLP Service error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error calling NLP service: $e');
      rethrow;
    }
  }
  
  /// Phân loại ý định người dùng
  /// Sử dụng Naive Bayes và SVM
  Future<Map<String, dynamic>> classifyIntent(String text) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/nlp/intent'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': text}),
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Intent classification failed');
      }
    } catch (e) {
      print('❌ Error classifying intent: $e');
      rethrow;
    }
  }
  
  /// Tính độ tương đồng giữa 2 văn bản
  /// Sử dụng: Levenshtein, Jaccard, Cosine, N-gram
  Future<Map<String, dynamic>> calculateSimilarity({
    required String text1,
    required String text2,
    String method = 'all',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/nlp/similarity'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text1': text1,
          'text2': text2,
          'method': method,
        }),
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Similarity calculation failed');
      }
    } catch (e) {
      print('❌ Error calculating similarity: $e');
      rethrow;
    }
  }
  
  /// Fuzzy matching cho tên phim
  /// Tìm phim gần giống nhất với query
  Future<Map<String, dynamic>> fuzzyMatch({
    required String query,
    required List<String> candidates,
    double threshold = 0.6,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/nlp/fuzzy-match'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'query': query,
          'candidates': candidates,
          'threshold': threshold,
        }),
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Fuzzy matching failed');
      }
    } catch (e) {
      print('❌ Error in fuzzy matching: $e');
      rethrow;
    }
  }
  
  /// Mở rộng query với synonyms và spell correction
  Future<Map<String, dynamic>> expandQuery({
    required String query,
    int maxExpansions = 10,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/nlp/expand-query'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'query': query,
          'max_expansions': maxExpansions,
        }),
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Query expansion failed');
      }
    } catch (e) {
      print('❌ Error expanding query: $e');
      rethrow;
    }
  }
  
  /// Phân tích query với NER
  Future<Map<String, dynamic>> analyzeQuery(String text) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/nlp/analyze'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': text}),
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Query analysis failed');
      }
    } catch (e) {
      print('❌ Error analyzing query: $e');
      rethrow;
    }
  }
  
  /// Kiểm tra NLP service có hoạt động không
  Future<bool> checkHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
      ).timeout(const Duration(seconds: 3));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] == 'ok';
      }
      return false;
    } catch (e) {
      print('❌ NLP Service is not available: $e');
      return false;
    }
  }
}

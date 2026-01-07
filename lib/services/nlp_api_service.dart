import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Service để gọi NLP API (Python backend)
class NLPApiService {

  // =============================================================
  // Đọc IP từ file .env (key: NLP_URL)
  // Fallback: http://10.199.12.150:8002 nếu không có trong .env
  // Lưu ý: Đảm bảo server Python đang chạy host='0.0.0.0' port=8002
  // Lưu ý: Đảm bảo điện thoại và máy tính cùng mạng WiFi
  // =============================================================
  final String baseUrl = dotenv.env['NLP_URL'] ?? "http://192.168.100.219:8002";

  /// Xử lý voice search với tất cả thuật toán NLP
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
      ).timeout(const Duration(seconds: 60));

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

  /// Hybrid search using BiLSTM + SBERT backend
  Future<Map<String, dynamic>> hybridSearch({
    required String query,
    int topK = 10,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/nlp/hybrid-search'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'query': query,
          'top_k': topK,
        }),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Hybrid Search error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error calling Hybrid search: $e');
      rethrow;
    }
  }

  /// Phân loại ý định người dùng
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
        // Kiểm tra linh hoạt hơn phòng khi key khác
        return data['status'] == 'ok' || data['status'] == 'success';
      }
      return false;
    } catch (e) {
      print('❌ NLP Service is not available: $e');
      return false;
    }
  }
}
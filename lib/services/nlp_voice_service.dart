import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'nlp_api_service.dart';

/// Voice Service tích hợp với NLP algorithms (tự code)
/// Thay thế GoogleVoiceService cũ
class NLPVoiceService {
  static final SpeechToText _speechToText = SpeechToText();
  static final NLPApiService _nlpService = NLPApiService();
  static bool _speechEnabled = false;
  static bool _isListening = false;
  static bool _isProcessing = false;

  /// Khởi tạo speech recognition
  static Future<bool> initializeSpeech() async {
    try {
      var status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        _showToast("Cần quyền truy cập microphone");
        return false;
      }

      _speechEnabled = await _speechToText.initialize(
        onError: (error) {
          print('❌ Speech error: $error');
          _showToast("Lỗi nhận dạng: ${error.errorMsg}");
          _isListening = false;
        },
        onStatus: (status) {
          print('📊 Speech status: $status');
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
          }
        },
      );

      if (!_speechEnabled) {
        _showToast("Nhận dạng giọng nói không khả dụng");
      }

      return _speechEnabled;
    } catch (e) {
      print('❌ Error initializing speech: $e');
      _showToast("Lỗi khởi tạo");
      return false;
    }
  }

  /// Bắt đầu lắng nghe và xử lý với NLP algorithms
  static Future<void> startListening({
    required Function(String recognizedText, Map<String, dynamic> nlpResult) onResult,
    required Function(String status) onStatusChange,
    String language = 'vi-VN',
  }) async {
    if (!_speechEnabled) {
      bool initialized = await initializeSpeech();
      if (!initialized) return;
    }

    if (_isListening) {
      _showToast("Đang lắng nghe...");
      return;
    }

    // Kiểm tra NLP service có hoạt động không
    bool nlpAvailable = await _nlpService.checkHealth();
    if (!nlpAvailable) {
      _showToast("⚠️ NLP Service không khả dụng. Vui lòng khởi động backend.");
      return;
    }

    _isListening = true;
    onStatusChange('listening');

    try {
      await _speechToText.listen(
        onResult: (result) async {
          if (result.finalResult) {
            String recognizedText = result.recognizedWords;
            print('🎤 Recognized: $recognizedText');

            _isListening = false;
            _isProcessing = true;
            onStatusChange('processing');

            try {
              // Xử lý với NLP algorithms (Python backend)
              print('🧠 Processing with NLP algorithms...');
              Map<String, dynamic> nlpResult = await _nlpService.processVoiceSearch(
                voiceText: recognizedText,
                language: language == 'vi-VN' ? 'vi' : 'en',
              );

              print('✅ NLP Result:');
              print('   Intent: ${nlpResult['intent']}');
              print('   Confidence: ${nlpResult['confidence']}');
              print('   Processed: ${nlpResult['processed_query']}');

              _isProcessing = false;
              onStatusChange('completed');

              // Trả kết quả về
              onResult(recognizedText, nlpResult);

            } catch (e) {
              print('❌ NLP processing error: $e');
              _isProcessing = false;
              onStatusChange('error');
              _showToast("Lỗi xử lý NLP: $e");
              
              // Fallback: trả về kết quả đơn giản
              onResult(recognizedText, {
                'original_text': recognizedText,
                'processed_query': recognizedText,
                'intent': 'search_by_title',
                'confidence': 0.5,
                'entities': {},
                'error': e.toString(),
              });
            }
          }
        },
        localeId: language,
        listenMode: ListenMode.confirmation,
        cancelOnError: true,
        partialResults: false,
      );
    } catch (e) {
      print('❌ Error starting listener: $e');
      _isListening = false;
      _isProcessing = false;
      onStatusChange('error');
      _showToast("Lỗi: $e");
    }
  }

  /// Dừng lắng nghe
  static Future<void> stopListening() async {
    if (_isListening) {
      await _speechToText.stop();
      _isListening = false;
    }
  }

  /// Xử lý text search (không dùng giọng nói)
  static Future<Map<String, dynamic>> processTextSearch(String text) async {
    try {
      print('🔍 Processing text search: $text');
      
      Map<String, dynamic> nlpResult = await _nlpService.processVoiceSearch(
        voiceText: text,
        language: 'vi',
      );
      
      return nlpResult;
    } catch (e) {
      print('❌ Error processing text: $e');
      return {
        'original_text': text,
        'processed_query': text,
        'intent': 'search_by_title',
        'confidence': 0.5,
        'entities': {},
        'error': e.toString(),
      };
    }
  }

  /// Phân tích query với NER
  static Future<Map<String, dynamic>> analyzeQuery(String text) async {
    try {
      return await _nlpService.analyzeQuery(text);
    } catch (e) {
      print('❌ Error analyzing query: $e');
      rethrow;
    }
  }

  /// Tính độ tương đồng
  static Future<Map<String, dynamic>> calculateSimilarity(
    String text1,
    String text2,
  ) async {
    try {
      return await _nlpService.calculateSimilarity(
        text1: text1,
        text2: text2,
      );
    } catch (e) {
      print('❌ Error calculating similarity: $e');
      rethrow;
    }
  }

  /// Fuzzy match cho tên phim
  static Future<Map<String, dynamic>> fuzzyMatchMovies(
    String query,
    List<String> movieTitles,
  ) async {
    try {
      return await _nlpService.fuzzyMatch(
        query: query,
        candidates: movieTitles,
        threshold: 0.5,
      );
    } catch (e) {
      print('❌ Error in fuzzy match: $e');
      rethrow;
    }
  }

  // Getters
  static bool get isListening => _isListening;
  static bool get isProcessing => _isProcessing;
  static bool get isEnabled => _speechEnabled;

  // Toast helper
  static void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.black87,
      textColor: Colors.white,
      fontSize: 14.0,
    );
  }
}

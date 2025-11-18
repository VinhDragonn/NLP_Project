import 'package:flutter/material.dart';
import 'package:r08fullmovieapp/services/nlp_api_service.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:fluttertoast/fluttertoast.dart';

/// Voice Search Button tích hợp NLP algorithms
class NLPVoiceSearchButton extends StatefulWidget {
  final Function(String recognizedText, Map<String,
      dynamic> nlpResult) onResult;
  final String? initialLanguage; // 'vi-VN' or 'en-US', null for auto-detect

  const NLPVoiceSearchButton({
    Key? key,
    required this.onResult,
    this.initialLanguage,
  }) : super(key: key);

  @override
  State<NLPVoiceSearchButton> createState() => _NLPVoiceSearchButtonState();
}

class _NLPVoiceSearchButtonState extends State<NLPVoiceSearchButton>
    with SingleTickerProviderStateMixin {
  String _status = 'idle'; // idle, listening, processing, completed, error
  String _recognizedText = '';
  String _currentSearchText = ''; // Text đang tìm
  late String _currentLanguage;
  late AnimationController _animationController;
  final SpeechToText _speechToText = SpeechToText();

  // Detect language from text (Vietnamese or English)
  String _detectLanguage(String text) {
    // If language is explicitly set, use it
    if (widget.initialLanguage != null) {
      return widget.initialLanguage!;
    }

    // Auto-detect language based on text content
    final vietnameseRegex = RegExp(
      r'[àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ]',
      caseSensitive: false,
    );

    return vietnameseRegex.hasMatch(text) ? 'vi-VN' : 'en-US';
  }

  @override
  void initState() {
    super.initState();
    _currentLanguage =
        widget.initialLanguage ?? 'vi-VN'; // Default to Vietnamese
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )
      ..repeat();
    _initSpeech();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _speechToText.stop();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    bool available = await _speechToText.initialize(
      onStatus: (status) {
        // Chỉ gọi stopListening khi speech recognition engine thực sự xong việc
        // và trạng thái của widget vẫn đang là 'listening'.
        if (status == 'done' && _status == 'listening') {
          _stopListening();
        }
      },
      onError: (error) {
        print('Speech recognition error: $error');
        setState(() => _status = 'idle');
        _showError(_currentLanguage == 'vi-VN'
            ? 'Lỗi nhận dạng giọng nói: $error'
            : 'Speech recognition error: $error');
      },
    );

    if (!available) {
      _showError(_currentLanguage == 'vi-VN'
          ? 'Không thể khởi tạo nhận dạng giọng nói'
          : 'Could not initialize speech recognition');
    }
  }

  Future<void> _stopListening() async {
    // Ngăn việc gọi stop nhiều lần không cần thiết
    if (!_speechToText.isListening) {
      if (_recognizedText
          .trim()
          .isEmpty) {
        setState(() => _status = 'idle');
      }
      return;
    }

    try {
      await _speechToText.stop();
      // Sau khi stop, onStatus sẽ chuyển thành 'done',
      // và logic xử lý cuối cùng sẽ được thực hiện trong onResult với finalResult=true.
      // Tuy nhiên, nếu người dùng không nói gì, finalResult có thể không được gọi.
      // Xử lý trường hợp không nhận dạng được gì.
      if (_recognizedText
          .trim()
          .isEmpty) {
        setState(() => _status = 'idle');
      }
    } catch (e) {
      _showError(_currentLanguage == 'vi-VN'
          ? 'Lỗi dừng nhận dạng giọng nói: $e'
          : 'Error stopping speech recognition: $e');
      setState(() => _status = 'idle');
    }
  }

  void _handleButtonPress() async {
    // Nếu đang nghe, nhấn lần nữa để dừng và xử lý
    if (_speechToText.isListening) {
      _stopListening();
    } else
    if (_status == 'idle' || _status == 'completed' || _status == 'error') {
      await _startListening();
    }
  }

  Future<void> _startListening() async {
    setState(() {
      _status = 'listening';
      _recognizedText = '';
      _currentSearchText = '';
    });

    try {
      await _speechToText.listen(
        onResult: (result) {
          setState(() {
            _recognizedText = result.recognizedWords;
            // Chỉ hiển thị text khi đang nghe, không hiển thị khi đã xong
            if (!result.finalResult) {
              final wordCount = result.recognizedWords
                  .trim()
                  .split(' ')
                  .length;
              _currentSearchText =
              'Đang nghe: "${result.recognizedWords}" ($wordCount từ)';
            }
          });

          // Auto-detect language from recognized text
          if (_recognizedText
              .trim()
              .isNotEmpty) {
            final detectedLang = _detectLanguage(_recognizedText);
            if (detectedLang != _currentLanguage) {
              setState(() {
                _currentLanguage = detectedLang;
              });
              print('🌐 Language detected: $_currentLanguage');
            }
          }

          // CHỈ tìm khi đã đọc xong (finalResult = true)
          if (result.finalResult) {

            // =======================================================
            // ===== <<< FIX: SỬA LOGIC TÌM KIẾM TẠI ĐÂY >>> =====
            // =======================================================

            // Đếm số từ (đảm bảo trim() để " " không bị đếm là 1 từ)
            final textToSearch = _recognizedText.trim();
            final wordCount = textToSearch.isEmpty ? 0 : textToSearch.split(' ').length;

            if (wordCount >= 1) {
              // ✅ HỢP LÝ: Gửi đi nếu có ít nhất 1 từ
              // (Backend sẽ lo việc "Avatar" (tốt) hay "phim" (xấu))
              _processText(textToSearch);

            } else {
              // ❌ LỖI: Báo lỗi nếu không nghe được gì
              setState(() {
                _status = 'idle'; // Quay về idle ngay
                _currentSearchText = '🔇 Không nghe rõ. Vui lòng thử lại.';
              });

              // Reset sau 3 giây
              Future.delayed(const Duration(seconds: 3), () {
                if (mounted && _currentSearchText.startsWith('🔇')) {
                  setState(() {
                    _status = 'idle';
                    _currentSearchText = '';
                  });
                }
              });
            }
            // =======================================================
            // ===== <<< HẾT PHẦN SỬA >>> =====
            // =======================================================
          }
        },
        localeId: _currentLanguage,
        listenMode: ListenMode.dictation,
        partialResults: true,
        listenFor: const Duration(seconds: 15),
        // Tăng thời gian nghe tối đa
        pauseFor: const Duration(
            seconds: 5), // ***FIX: Tăng thời gian chờ khi tạm ngưng nói***
      );
    } catch (e) {
      _showError('Lỗi khi nghe: $e');
      setState(() => _status = 'idle');
    }
  }

  void _processText(String text) async {
    // <<< FIX: Đã chuyển check text rỗng lên hàm onResult >>>
    // if (text
    //     .trim()
    //     .isEmpty) {
    //   setState(() => _status = 'idle');
    //   return;
    // }

    setState(() {
      _status = 'processing';
      _currentSearchText =
      'Đang tìm: "$text"'; // Hiển thị text đang tìm với dấu ngoặc kép
    });

    try {
      final nlpService = NLPApiService();
      final result = await nlpService.processVoiceSearch(
        voiceText: text,
        language: _currentLanguage,
      );

      // <<< FIX: Xử lý trường hợp backend trả về intent "generic_query" (truy vấn rác) >>>
      if (mounted) {
        if (result['intent'] == 'generic_query') {
          // Đây là truy vấn rác (ví dụ: "phim", "xem")
          setState(() {
            _status = 'error'; // Dùng trạng thái error để báo lỗi
            _currentSearchText = '❌ Vui lòng tìm cụ thể hơn (ví dụ: "phim avatar")';
          });

          // Reset sau 3 giây
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted && _currentSearchText.startsWith('❌')) {
              setState(() {
                _status = 'idle';
                _currentSearchText = '';
              });
            }
          });

        } else {
          // Tìm kiếm thành công
          setState(() {
            _status = 'completed';
            _currentSearchText = '✅ Đã tìm: "$text"';
          });
          widget.onResult(text, result);

          // Reset về idle sau 1 giây để có thể tìm tiếp ngay
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              setState(() {
                _status = 'idle';
                _currentSearchText = '';
              });
            }
          });
        }
      }
    } catch (e) {
      _showError('${_currentLanguage == 'vi-VN'
          ? 'Lỗi xử lý'
          : 'Processing error'}: $e');
      if (mounted) {
        setState(() {
          _status = 'error';
          // Hiển thị lại câu đã tìm bị lỗi để người dùng biết
          _currentSearchText = 'Lỗi khi tìm: "$text"';
        });
      }
    }
  }

  void _showError(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.red,
      textColor: Colors.white,
    );
  }

  String _getStatusText() {
    // Nếu có text đang tìm thì hiển thị text đó
    if (_currentSearchText.isNotEmpty) {
      return _currentSearchText;
    }

    switch (_status) {
      case 'listening':
        return _currentLanguage == 'vi-VN'
            ? '🎤 Đang nghe... (nhấn để dừng)'
            : '🎤 Listening... (tap to stop)';
      case 'processing':
        return _currentLanguage == 'vi-VN' ? '🧠 Đang tìm...' : '🧠 Searching...';
      case 'completed':
        return _currentLanguage == 'vi-VN' ? '✅ Tìm xong' : '✅ Found';
      case 'error':
      // <<< FIX: Đã có _currentSearchText lo việc này, nhưng để dự phòng >>>
        return _currentLanguage == 'vi-VN' ? '❌ Lỗi' : '❌ Error';
      default:
        return _currentLanguage == 'vi-VN' ? '🎤 Nhấn để nói' : '🎤 Tap to speak';
    }
  }

  IconData _getStatusIcon() {
    switch (_status) {
      case 'listening':
        return Icons
            .stop_circle_outlined; // Thay đổi icon để báo hiệu có thể dừng
      case 'processing':
        return Icons.psychology;
      case 'completed':
        return Icons.check_circle;
      case 'error':
        return Icons.error;
      default:
        return Icons.mic_none;
    }
  }

  Color _getStatusColor() {
    switch (_status) {
      case 'listening':
        return Colors.red;
      case 'processing':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'error':
        return Colors.red;
      default:
        return Colors.amber;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _handleButtonPress,
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: _getStatusColor().withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: _getStatusColor(),
                width: 3,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (_status == 'listening' || _status == 'processing')
                  RotationTransition(
                    turns: _animationController,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _getStatusColor().withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                Icon(
                  _getStatusIcon(),
                  color: _getStatusColor(),
                  size: 32,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
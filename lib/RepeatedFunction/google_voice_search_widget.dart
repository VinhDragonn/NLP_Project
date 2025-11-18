import 'package:flutter/material.dart';
import 'package:r08fullmovieapp/services/google_voice_service.dart';
import 'package:fluttertoast/fluttertoast.dart';

class GoogleVoiceSearchWidget extends StatefulWidget {
  final Function(String, Map<String, dynamic>) onGoogleResult;
  final bool showHint;

  const GoogleVoiceSearchWidget({
    Key? key,
    required this.onGoogleResult,
    this.showHint = true,
  }) : super(key: key);

  @override
  State<GoogleVoiceSearchWidget> createState() => _GoogleVoiceSearchWidgetState();
}

class _GoogleVoiceSearchWidgetState extends State<GoogleVoiceSearchWidget>
    with TickerProviderStateMixin {
  bool _isListening = false;
  bool _isVoiceAvailable = false;
  bool _isGoogleProcessing = false;
  late AnimationController _animationController;
  late AnimationController _googleAnimationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _googleScaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _checkVoiceAvailability();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _googleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _googleScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _googleAnimationController,
      curve: Curves.easeInOut,
    ));

    _colorAnimation = ColorTween(
      begin: Colors.amber,
      end: Colors.green,
    ).animate(CurvedAnimation(
      parent: _googleAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _checkVoiceAvailability() async {
    _isVoiceAvailable = await GoogleVoiceService.initializeSpeech();
    setState(() {});
  }

  Future<void> _startGoogleVoiceSearch() async {
    if (!_isVoiceAvailable) {
      Fluttertoast.showToast(
        msg: "Tính năng Google Voice Search không khả dụng",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    await GoogleVoiceService.startListening(
      onResult: (String recognizedText, Map<String, dynamic> analysis) {
        setState(() {
          _isGoogleProcessing = false;
        });
        _googleAnimationController.stop();
        _googleAnimationController.reset();
        
        widget.onGoogleResult(recognizedText, analysis);
        
        // Hiển thị thông tin Google analysis
        _showGoogleAnalysisDialog(recognizedText, analysis);
      },
      onListeningChanged: () {
        setState(() {
          _isListening = GoogleVoiceService.isListening;
          if (_isListening) {
            _isGoogleProcessing = true;
            _animationController.repeat(reverse: true);
            _googleAnimationController.repeat(reverse: true);
          } else {
            _animationController.stop();
            _animationController.reset();
          }
        });
      },
    );
  }

  void _showGoogleAnalysisDialog(String voiceText, Map<String, dynamic> analysis) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color.fromRGBO(25, 25, 25, 1),
          title: Row(
            children: [
              Icon(Icons.mic, color: Colors.green),
              const SizedBox(width: 8),
              Text(
                'Google Voice Search',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bạn đã nói:',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              Text(
                '"$voiceText"',
                style: TextStyle(color: Colors.amber, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              Text(
                'Google hiểu là:',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              Text(
                analysis['search_query'] ?? '',
                style: TextStyle(color: Colors.green, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              _buildAnalysisInfo(analysis),
              if (analysis['confidence'] != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Độ chính xác: ${(analysis['confidence'] * 100).toStringAsFixed(1)}%',
                  style: TextStyle(color: Colors.green, fontSize: 12),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Đóng', style: TextStyle(color: Colors.amber)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Có thể thêm logic tìm kiếm nâng cao ở đây
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: Text('Tìm kiếm nâng cao'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAnalysisInfo(Map<String, dynamic> analysis) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (analysis['search_type'] != null) ...[
          Text(
            'Loại tìm kiếm: ${_getSearchTypeText(analysis['search_type'])}',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
          const SizedBox(height: 4),
        ],
        if (analysis['intent'] != null) ...[
          Text(
            'Ý định: ${_getIntentText(analysis['intent'])}',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
          const SizedBox(height: 4),
        ],
        if (analysis['filters'] != null && analysis['filters'].isNotEmpty) ...[
          Text(
            'Bộ lọc: ${_getFiltersText(analysis['filters'])}',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ],
    );
  }

  String _getSearchTypeText(String searchType) {
    Map<String, String> typeMap = {
      'title': 'Tên phim',
      'genre': 'Thể loại',
      'actor': 'Diễn viên',
      'description': 'Mô tả',
      'similar': 'Phim tương tự',
    };
    return typeMap[searchType] ?? searchType;
  }

  String _getIntentText(String intent) {
    Map<String, String> intentMap = {
      'new_movies': 'Phim mới',
      'classic_movies': 'Phim kinh điển',
      'popular': 'Phim phổ biến',
      'high_rating': 'Phim đánh giá cao',
      'similar': 'Phim tương tự',
      'general_search': 'Tìm kiếm chung',
    };
    return intentMap[intent] ?? intent;
  }

  String _getFiltersText(Map<String, dynamic> filters) {
    List<String> filterTexts = [];
    filters.forEach((key, value) {
      filterTexts.add('$key: $value');
    });
    return filterTexts.join(', ');
  }

  @override
  void dispose() {
    _animationController.dispose();
    _googleAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVoiceAvailable) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        // Google Voice search button
        GestureDetector(
          onTap: _startGoogleVoiceSearch,
          child: AnimatedBuilder(
            animation: _isGoogleProcessing ? _googleAnimationController : _animationController,
            builder: (context, child) {
              return Transform.scale(
                scale: _isGoogleProcessing ? _googleScaleAnimation.value : _scaleAnimation.value,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: _isGoogleProcessing 
                        ? (_colorAnimation.value?.withOpacity(0.2) ?? Colors.green.withOpacity(0.2))
                        : (_isListening 
                            ? Colors.red.withOpacity(0.2) 
                            : Colors.amber.withOpacity(0.2)),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _isGoogleProcessing 
                          ? (_colorAnimation.value ?? Colors.green)
                          : (_isListening ? Colors.red : Colors.amber),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _isGoogleProcessing 
                            ? (_colorAnimation.value ?? Colors.green).withOpacity(0.3)
                            : (_isListening ? Colors.red : Colors.amber).withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        color: _isGoogleProcessing 
                            ? (_colorAnimation.value ?? Colors.green)
                            : (_isListening ? Colors.red : Colors.amber),
                        size: 32,
                      ),
                      if (_isGoogleProcessing)
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
                            child: Icon(
                              Icons.g_mobiledata,
                              color: Colors.white,
                              size: 8,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Status indicator
        if (_isGoogleProcessing)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.g_mobiledata,
                  color: Colors.green,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  "Google đang xử lý...",
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          )
        else if (_isListening)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.mic,
                  color: Colors.red,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  "Đang lắng nghe...",
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          )
        else if (widget.showHint)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amber.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Text(
                  "Google Voice Search",
                  style: TextStyle(
                    color: Colors.amber,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  "Nhấn để tìm phim với Google",
                  style: TextStyle(
                    color: Colors.amber.withOpacity(0.8),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// Floating Google Voice Search Button
class FloatingGoogleVoiceSearchButton extends StatefulWidget {
  final Function(String, Map<String, dynamic>) onGoogleResult;

  const FloatingGoogleVoiceSearchButton({
    Key? key,
    required this.onGoogleResult,
  }) : super(key: key);

  @override
  State<FloatingGoogleVoiceSearchButton> createState() =>
      _FloatingGoogleVoiceSearchButtonState();
}

class _FloatingGoogleVoiceSearchButtonState extends State<FloatingGoogleVoiceSearchButton>
    with TickerProviderStateMixin {
  bool _isListening = false;
  bool _isVoiceAvailable = false;
  bool _isGoogleProcessing = false;
  late AnimationController _animationController;
  late AnimationController _googleAnimationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _googleScaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _checkVoiceAvailability();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _googleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _googleScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _googleAnimationController,
      curve: Curves.easeInOut,
    ));

    _colorAnimation = ColorTween(
      begin: Colors.amber,
      end: Colors.green,
    ).animate(CurvedAnimation(
      parent: _googleAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _checkVoiceAvailability() async {
    _isVoiceAvailable = await GoogleVoiceService.initializeSpeech();
    setState(() {});
  }

  Future<void> _startGoogleVoiceSearch() async {
    if (!_isVoiceAvailable) {
      Fluttertoast.showToast(
        msg: "Tính năng Google Voice Search không khả dụng",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    await GoogleVoiceService.startListening(
      onResult: (String recognizedText, Map<String, dynamic> analysis) {
        setState(() {
          _isGoogleProcessing = false;
        });
        _googleAnimationController.stop();
        _googleAnimationController.reset();
        
        widget.onGoogleResult(recognizedText, analysis);
      },
      onListeningChanged: () {
        setState(() {
          _isListening = GoogleVoiceService.isListening;
          if (_isListening) {
            _isGoogleProcessing = true;
            _animationController.repeat(reverse: true);
            _googleAnimationController.repeat(reverse: true);
          } else {
            _animationController.stop();
            _animationController.reset();
          }
        });
      },
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _googleAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVoiceAvailable) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: 20,
      right: 20,
      child: AnimatedBuilder(
        animation: _isGoogleProcessing ? _googleAnimationController : _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _isGoogleProcessing ? _googleScaleAnimation.value : _scaleAnimation.value,
            child: FloatingActionButton(
              onPressed: _startGoogleVoiceSearch,
              backgroundColor: _isGoogleProcessing 
                  ? (_colorAnimation.value ?? Colors.green)
                  : (_isListening ? Colors.red : Colors.amber),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color: Colors.white,
                    size: 30,
                  ),
                  if (_isGoogleProcessing)
                    Positioned(
                      top: 5,
                      right: 5,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.g_mobiledata,
                          color: Colors.green,
                          size: 8,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
} 
import 'package:flutter/material.dart';
import 'package:r08fullmovieapp/DetailScreen/checker.dart';
import 'package:r08fullmovieapp/RepeatedFunction/repttext.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class VoiceSearchResultPage extends StatefulWidget {
  final String searchQuery;
  final Map<String, dynamic>? aiAnalysis;

  const VoiceSearchResultPage({
    Key? key,
    required this.searchQuery,
    this.aiAnalysis,
  }) : super(key: key);

  @override
  State<VoiceSearchResultPage> createState() => _VoiceSearchResultPageState();
}

class _VoiceSearchResultPageState extends State<VoiceSearchResultPage> {
  List<Map<String, dynamic>> searchResults = [];
  bool isLoading = true;
  bool hasError = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _performSearch();
  }

  Future<void> _performSearch() async {
    setState(() {
      isLoading = true;
      hasError = false;
      searchResults.clear();
    });

    try {
      // Xây dựng URL dựa trên intent từ NLP
      String searchUrl = _buildSearchUrl();
      
      print('🔍 Search URL: $searchUrl');
      
      var response = await http.get(Uri.parse(searchUrl));
      
      print('📡 Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        var results = data['results'] as List;
        
        print('📊 Results count: ${results.length}');
        
        for (var item in results) {
          if (item['id'] != null &&
              item['poster_path'] != null &&
              item['vote_average'] != null) {
            searchResults.add({
              'id': item['id'],
              'poster_path': item['poster_path'],
              'vote_average': item['vote_average'],
              'media_type': item['media_type'] ?? 'movie', // Default to movie
              'popularity': item['popularity'],
              'overview': item['overview'],
              'title': item['title'] ?? item['name'] ?? 'Unknown',
            });
          }
        }
        
        print('✅ Added ${searchResults.length} results');
        
        // Giới hạn kết quả
        if (searchResults.length > 20) {
          searchResults = searchResults.take(20).toList();
        }
      } else {
        setState(() {
          hasError = true;
          errorMessage = 'Lỗi kết nối: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        hasError = true;
        errorMessage = 'Lỗi: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Xây dựng URL tìm kiếm dựa trên intent từ NLP
  String _buildSearchUrl() {
    String baseUrl = 'https://api.themoviedb.org/3';
    String apiKey = dotenv.env['apikey'] ?? '';
    String intent = widget.aiAnalysis?['intent'] ?? 'search_by_title';
    
    // Ưu tiên entities hơn intent (fix cho trường hợp intent sai)
    var entities = widget.aiAnalysis?['entities'];
    
    print('🎯 Building URL for intent: $intent');
    print('🏷️ Entities: $entities');
    
    // Nếu có title entity, ưu tiên tìm theo title (chỉ dùng title, bỏ phần "tìm phim")
    if (entities != null && entities['titles'] != null && (entities['titles'] as List).isNotEmpty) {
      String title = (entities['titles'] as List).first;
      print('✅ Using title search: $title');
      return '$baseUrl/search/multi?api_key=$apiKey&query=${Uri.encodeComponent(title)}';
    }
    
    // Nếu có genre entity, ưu tiên tìm theo genre
    if (entities != null && entities['genres'] != null && (entities['genres'] as List).isNotEmpty) {
      String genreId = _getGenreId((entities['genres'] as List).first);
      if (genreId.isNotEmpty) {
        print('✅ Using genre search: $genreId');
        return '$baseUrl/discover/movie?api_key=$apiKey&with_genres=$genreId&sort_by=popularity.desc';
      }
    }
    
    // Nếu có people entity (diễn viên/đạo diễn), tìm theo tên người
    if (entities != null && entities['people'] != null && (entities['people'] as List).isNotEmpty) {
      String person = (entities['people'] as List).first;
      print('✅ Using people search: $person');
      // Tìm theo tên người (TMDB sẽ tự động tìm phim liên quan)
      return '$baseUrl/search/multi?api_key=$apiKey&query=${Uri.encodeComponent(person)}';
    }
    
    // Nếu có year entity, ưu tiên tìm theo năm
    if (entities != null && entities['years'] != null && (entities['years'] as List).isNotEmpty) {
      String year = (entities['years'] as List).first;
      print('✅ Using year search: $year');
      return '$baseUrl/discover/movie?api_key=$apiKey&year=$year&sort_by=popularity.desc';
    }
    
    switch (intent) {
      case 'search_by_genre':
        // Tìm theo thể loại
        var genres = widget.aiAnalysis?['entities']?['genres'] as List?;
        if (genres != null && genres.isNotEmpty) {
          String genreId = _getGenreId(genres.first);
          return '$baseUrl/discover/movie?api_key=$apiKey&with_genres=$genreId&sort_by=popularity.desc';
        }
        break;
        
      case 'search_by_year':
        // Tìm theo năm
        var years = widget.aiAnalysis?['entities']?['years'] as List?;
        if (years != null && years.isNotEmpty) {
          return '$baseUrl/discover/movie?api_key=$apiKey&year=${years.first}&sort_by=popularity.desc';
        }
        break;
        
      case 'search_popular':
        // Phim phổ biến
        return '$baseUrl/movie/popular?api_key=$apiKey';
        
      case 'search_high_rating':
        // Phim đánh giá cao
        return '$baseUrl/discover/movie?api_key=$apiKey&sort_by=vote_average.desc&vote_count.gte=1000';
        
      case 'search_by_actor':
        // Tìm theo diễn viên (fallback to search)
        var people = widget.aiAnalysis?['entities']?['people'] as List?;
        if (people != null && people.isNotEmpty) {
          return '$baseUrl/search/person?api_key=$apiKey&query=${Uri.encodeComponent(people.first)}';
        }
        break;
        
      case 'search_similar':
      case 'search_by_title':
      default:
        // Tìm kiếm chung
        return '$baseUrl/search/multi?api_key=$apiKey&query=${Uri.encodeComponent(widget.searchQuery)}';
    }
    
    // Fallback
    return '$baseUrl/search/multi?api_key=$apiKey&query=${Uri.encodeComponent(widget.searchQuery)}';
  }
  
  // Map genre name to TMDB genre ID
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
      'war': '10752',
      'western': '37',
    };
    return genreMap[genreName.toLowerCase()] ?? '';
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(18, 18, 18, 1),
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(18, 18, 18, 0.9),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kết quả tìm kiếm',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '"${widget.searchQuery}"',
              style: TextStyle(
                color: Colors.amber,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.amber),
            onPressed: _performSearch,
          ),
        ],
      ),
      body: Column(
        children: [
          // Voice search info with AI
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.aiAnalysis != null 
                  ? Colors.blue.withOpacity(0.1)
                  : Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.aiAnalysis != null 
                    ? Colors.blue.withOpacity(0.3)
                    : Colors.amber.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      widget.aiAnalysis != null ? Icons.psychology : Icons.mic,
                      color: widget.aiAnalysis != null ? Colors.blue : Colors.amber,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.aiAnalysis != null 
                                ? 'AI Voice Search'
                                : 'Tìm kiếm bằng giọng nói',
                            style: TextStyle(
                              color: widget.aiAnalysis != null ? Colors.blue : Colors.amber,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Đã nhận dạng: "${widget.searchQuery}"',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (widget.aiAnalysis != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Phân Tích:',
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (widget.aiAnalysis!['search_type'] != null)
                          Text(
                            'Loại: ${_getSearchTypeText(widget.aiAnalysis!['search_type'])}',
                            style: TextStyle(color: Colors.white, fontSize: 11),
                          ),
                        if (widget.aiAnalysis!['intent'] != null)
                          Text(
                            'Ý định: ${_getIntentText(widget.aiAnalysis!['intent'])}',
                            style: TextStyle(color: Colors.white, fontSize: 11),
                          ),
                        if (widget.aiAnalysis!['filters'] != null && 
                            widget.aiAnalysis!['filters'].isNotEmpty)
                          Text(
                            'Bộ lọc: ${_getFiltersText(widget.aiAnalysis!['filters'])}',
                            style: TextStyle(color: Colors.white, fontSize: 11),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Search results
          Expanded(
            child: isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.amber),
                        const SizedBox(height: 16),
                        Text(
                          'Đang tìm kiếm...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : hasError
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 64,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Có lỗi xảy ra',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              errorMessage,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _performSearch,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber,
                                foregroundColor: Colors.black,
                              ),
                              child: Text('Thử lại'),
                            ),
                          ],
                        ),
                      )
                    : searchResults.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  color: Colors.white.withOpacity(0.5),
                                  size: 64,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Không tìm thấy kết quả',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Thử tìm kiếm với từ khóa khác',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: searchResults.length,
                            itemBuilder: (context, index) {
                              final item = searchResults[index];
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => descriptioncheckui(
                                        item['id'],
                                        item['media_type'],
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  height: 180,
                                  decoration: BoxDecoration(
                                    color: const Color.fromRGBO(20, 20, 20, 1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      // Poster
                                      Container(
                                        width: MediaQuery.of(context).size.width * 0.4,
                                        decoration: BoxDecoration(
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(12),
                                            bottomLeft: Radius.circular(12),
                                          ),
                                          image: DecorationImage(
                                            image: NetworkImage(
                                              'https://image.tmdb.org/t/p/w500${item['poster_path']}',
                                            ),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      
                                      const SizedBox(width: 16),
                                      
                                      // Content
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // Title and media type
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      item['title'],
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.amber.withOpacity(0.2),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Text(
                                                      item['media_type'].toUpperCase(),
                                                      style: const TextStyle(
                                                        color: Colors.amber,
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              
                                              const SizedBox(height: 12),
                                              
                                              // Rating and popularity
                                              Wrap(
                                                spacing: 8,
                                                runSpacing: 4,
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 3,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.amber.withOpacity(0.2),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        const Icon(
                                                          Icons.star,
                                                          color: Colors.amber,
                                                          size: 14,
                                                        ),
                                                        const SizedBox(width: 3),
                                                        Text(
                                                          '${item['vote_average']}',
                                                          style: const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 11,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 3,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.amber.withOpacity(0.2),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        const Icon(
                                                          Icons.people_outline,
                                                          color: Colors.amber,
                                                          size: 14,
                                                        ),
                                                        const SizedBox(width: 3),
                                                        Text(
                                                          '${item['popularity']?.toStringAsFixed(0) ?? 0}',
                                                          style: const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 11,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              
                                              const SizedBox(height: 12),
                                              
                                              // Overview
                                              Expanded(
                                                child: Text(
                                                  item['overview'] ?? 'Không có mô tả',
                                                  style: TextStyle(
                                                    color: Colors.white.withOpacity(0.7),
                                                    fontSize: 12,
                                                  ),
                                                  maxLines: 3,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
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
        ],
      ),
    );
  }
} 
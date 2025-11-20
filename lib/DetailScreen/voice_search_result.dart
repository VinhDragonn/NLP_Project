import 'package:flutter/material.dart';
import 'package:r08fullmovieapp/DetailScreen/checker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:r08fullmovieapp/services/nlp_api_service.dart';
import 'package:translator/translator.dart';
import 'dart:convert';

class VoiceSearchResultPage extends StatefulWidget {
  final String searchQuery;
  final Map<String, dynamic>? aiAnalysis;
  final bool useHybrid;

  const VoiceSearchResultPage({
    Key? key,
    required this.searchQuery,
    this.aiAnalysis,
    this.useHybrid = false,
  }) : super(key: key);

  @override
  State<VoiceSearchResultPage> createState() => _VoiceSearchResultPageState();
}

class _VoiceSearchResultPageState extends State<VoiceSearchResultPage> {
  List<Map<String, dynamic>> searchResults = [];
  bool isLoading = true;
  bool hasError = false;
  String errorMessage = '';
  final NLPApiService _nlpApiService = NLPApiService();
  final GoogleTranslator _translator = GoogleTranslator();
  String? hybridIntent;
  double? hybridAlpha;
  String? translatedQuery;
  final Map<String, Map<String, dynamic>?> _posterCache = {};

  bool get _useHybrid => widget.useHybrid;

  @override
  void initState() {
    super.initState();
    _performSearch();
  }

  Future<void> _performSearch() async {
    setState(() {
      isLoading = true;
      hasError = false;
      errorMessage = '';
      searchResults.clear();
      if (_useHybrid) {
        hybridIntent = null;
        hybridAlpha = null;
      }
    });

    try {
      if (_useHybrid) {
        await _performHybridSearch();
      } else {
        await _performTmdbSearch();
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

  Future<void> _performHybridSearch() async {
    final rawQuery = _normalizeVoiceText(widget.aiAnalysis?['processed_query'] ??
        widget.aiAnalysis?['search_query'] ??
        widget.searchQuery);
    String queryForBackend = rawQuery;

    try {
      final translation = await _translator.translate(rawQuery, to: 'en');
      queryForBackend = translation.text.trim();
      translatedQuery = queryForBackend;
      print('🌐 Flutter translation: "$rawQuery" -> "$queryForBackend"');
    } catch (e) {
      print('⚠️ Translator error: $e');
      translatedQuery = null;
    }

    final response = await _nlpApiService.hybridSearch(
      query: queryForBackend,
      topK: 12,
    );

    final results = (response['results'] as List?) ?? [];
    final mappedResults = results
        .map((item) => {
      'title': (item['movie_title'] ?? '').toString().trim(),
      'plot': item['plot'] ?? '',
      'genres': item['genres'] ?? '',
      'keywords': item['keywords'] ?? '',
      'score': (item['score'] as num?)?.toDouble() ?? 0.0,
    })
        .toList();

    await _attachPostersToHybridResults(mappedResults);

    setState(() {
      hybridIntent = response['intent']?.toString();
      hybridAlpha = (response['alpha'] as num?)?.toDouble();
      searchResults = mappedResults;
    });
  }

  Future<void> _attachPostersToHybridResults(
      List<Map<String, dynamic>> results) async {
    final futures = results.map((item) async {
      final title = (item['title'] ?? '').toString();
      if (title.isEmpty) return;
      final posterData = await _fetchPosterData(title);
      if (posterData != null) {
        item['poster_url'] = posterData['posterUrl'];
        item['tmdb_id'] = posterData['tmdbId'];
        item['media_type'] = posterData['mediaType'];
        item['overview'] = posterData['overview'];
        item['vote_average'] = posterData['voteAverage'];
      }
    });
    await Future.wait(futures);
  }

  Future<Map<String, dynamic>?> _fetchPosterData(String title) async {
    if (title.trim().isEmpty) return null;
    if (_posterCache.containsKey(title)) {
      return _posterCache[title];
    }

    final apiKey = dotenv.env['apikey'];
    if (apiKey == null || apiKey.isEmpty) {
      _posterCache[title] = null;
      return null;
    }

    try {
      final url =
          'https://api.themoviedb.org/3/search/multi?api_key=$apiKey&query=${Uri.encodeComponent(title)}';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final results = (data['results'] as List?) ?? [];
        if (results.isEmpty) {
          _posterCache[title] = null;
          return null;
        }

        final match = results.firstWhere(
              (item) => item['poster_path'] != null,
          orElse: () => results.first,
        );
        final posterPath = match['poster_path'];
        final posterUrl = posterPath != null
            ? 'https://image.tmdb.org/t/p/w500$posterPath'
            : null;

        final mapped = {
          'posterUrl': posterUrl,
          'tmdbId': match['id'],
          'mediaType': (match['media_type'] ?? 'movie').toString(),
          'overview': match['overview'],
          'voteAverage': (match['vote_average'] as num?)?.toDouble() ?? 0.0,
        };
        _posterCache[title] = mapped;
        return mapped;
      }
    } catch (e) {
      print('⚠️ Poster fetch error for "$title": $e');
    }

    _posterCache[title] = null;
    return null;
  }

  Future<void> _performTmdbSearch() async {
    String searchUrl = _buildSearchUrl();
    print('🔍 Search URL: $searchUrl');

    final response = await http.get(Uri.parse(searchUrl));
    print('📡 Response status: ${response.statusCode}');

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      var results = data['results'] as List;

      print('📊 Results count: ${results.length}');

      List<Map<String, dynamic>> tmdbResults = [];
      for (var item in results) {
        if (item['id'] != null &&
            item['poster_path'] != null &&
            item['vote_average'] != null) {
          tmdbResults.add({
            'id': item['id'],
            'poster_path': item['poster_path'],
            'vote_average': item['vote_average'],
            'media_type': item['media_type'] ?? 'movie',
            'popularity': item['popularity'],
            'overview': item['overview'],
            'title': item['title'] ?? item['name'] ?? 'Unknown',
          });
        }
      }

      if (tmdbResults.length > 20) {
        tmdbResults = tmdbResults.take(20).toList();
      }

      setState(() {
        searchResults = tmdbResults;
      });
    } else {
      throw Exception('Lỗi kết nối: ${response.statusCode}');
    }
  }

  String _buildSearchUrl() {
    String baseUrl = 'https://api.themoviedb.org/3';
    String apiKey = dotenv.env['apikey'] ?? '';
    String intent = widget.aiAnalysis?['intent'] ?? 'search_by_title';

    var entities = widget.aiAnalysis?['entities'];

    if (entities != null &&
        entities['titles'] != null &&
        (entities['titles'] as List).isNotEmpty) {
      String title = (entities['titles'] as List).first;
      return '$baseUrl/search/multi?api_key=$apiKey&query=${Uri.encodeComponent(title)}';
    }

    if (entities != null &&
        entities['genres'] != null &&
        (entities['genres'] as List).isNotEmpty) {
      String genreId = _getGenreId((entities['genres'] as List).first);
      if (genreId.isNotEmpty) {
        return '$baseUrl/discover/movie?api_key=$apiKey&with_genres=$genreId&sort_by=popularity.desc';
      }
    }

    if (entities != null &&
        entities['people'] != null &&
        (entities['people'] as List).isNotEmpty) {
      String person = (entities['people'] as List).first;
      return '$baseUrl/search/multi?api_key=$apiKey&query=${Uri.encodeComponent(person)}';
    }

    if (entities != null &&
        entities['years'] != null &&
        (entities['years'] as List).isNotEmpty) {
      String year = (entities['years'] as List).first;
      return '$baseUrl/discover/movie?api_key=$apiKey&year=$year&sort_by=popularity.desc';
    }

    final defaultQuery = _getDefaultSearchQuery();

    switch (intent) {
      case 'search_by_genre':
        var genres = widget.aiAnalysis?['entities']?['genres'] as List?;
        if (genres != null && genres.isNotEmpty) {
          String genreId = _getGenreId(genres.first);
          return '$baseUrl/discover/movie?api_key=$apiKey&with_genres=$genreId&sort_by=popularity.desc';
        }
        break;

      case 'search_by_year':
        var years = widget.aiAnalysis?['entities']?['years'] as List?;
        if (years != null && years.isNotEmpty) {
          return '$baseUrl/discover/movie?api_key=$apiKey&year=${years.first}&sort_by=popularity.desc';
        }
        break;

      case 'search_popular':
        return '$baseUrl/movie/popular?api_key=$apiKey';

      case 'search_high_rating':
        return '$baseUrl/discover/movie?api_key=$apiKey&sort_by=vote_average.desc&vote_count.gte=1000';

      case 'search_by_actor':
        var people = widget.aiAnalysis?['entities']?['people'] as List?;
        if (people != null && people.isNotEmpty) {
          return '$baseUrl/search/person?api_key=$apiKey&query=${Uri.encodeComponent(people.first)}';
        }
        break;

      case 'search_similar':
      case 'search_by_title':
      default:
        return '$baseUrl/search/multi?api_key=$apiKey&query=${Uri.encodeComponent(defaultQuery)}';
    }

    return '$baseUrl/search/multi?api_key=$apiKey&query=${Uri.encodeComponent(defaultQuery)}';
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

  // 🎯 OPTIMIZED TMDB CARD
  Widget _buildTmdbResultCard(BuildContext context, Map<String, dynamic> item) {
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Poster Image
            Container(
              width: MediaQuery.of(context).size.width * 0.35,
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

            // Content Side
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: Title + Type
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item['title'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(left: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item['media_type'].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.amber,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Scrollable Content Area
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Stats Row
                            Padding(
                              padding: const EdgeInsets.only(top: 6, bottom: 6),
                              child: Row(
                                children: [
                                  _buildInfoChip(
                                    icon: Icons.star,
                                    label: '${item['vote_average']}',
                                  ),
                                  const SizedBox(width: 8),
                                  _buildInfoChip(
                                    icon: Icons.people_outline,
                                    label:
                                    '${item['popularity']?.toStringAsFixed(0) ?? 0}',
                                  ),
                                ],
                              ),
                            ),

                            // Description
                            Text(
                              item['overview'] ?? 'Không có mô tả',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 12,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
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
  }

  // 🎯 OPTIMIZED HYBRID CARD (Cleaned up)
  Widget _buildHybridResultCard(Map<String, dynamic> item) {
    final title = (item['title'] ?? '').toString();
    final score = (item['score'] as num?)?.toDouble() ?? 0.0;
    final plot = (item['plot'] ?? '').toString();
    final posterUrl = (item['poster_url'] ?? '').toString();
    final tmdbId = item['tmdb_id'];
    final mediaType = (item['media_type'] ?? 'movie').toString();
    final voteAverage = item['vote_average'];

    return GestureDetector(
      onTap: tmdbId != null
          ? () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => descriptioncheckui(
              tmdbId,
              mediaType,
            ),
          ),
        );
      }
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 200,
        decoration: BoxDecoration(
          color: const Color.fromRGBO(20, 20, 20, 1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.withOpacity(0.2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Poster Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: posterUrl.isNotEmpty
                  ? Image.network(
                posterUrl,
                width: 110,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildPosterPlaceholder(),
              )
                  : SizedBox(
                width: 110,
                child: _buildPosterPlaceholder(),
              ),
            ),

            // Content Side
            Expanded(
              child: Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title + Score Header (Always Visible)
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title.isNotEmpty ? title : 'Chưa rõ tên phim',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(left: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.bolt,
                                  color: Colors.greenAccent, size: 12),
                              const SizedBox(width: 2),
                              Text(
                                score.toStringAsFixed(3),
                                style: const TextStyle(
                                  color: Colors.greenAccent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // SCROLLABLE CONTENT (Only Plot + Rating)
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (voteAverage != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 6, bottom: 4),
                                child: _buildInfoChip(
                                  icon: Icons.star,
                                  label: voteAverage.toString(),
                                ),
                              ),

                            // Plot (Clean, scrollable)
                            if (plot.trim().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  plot,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.85),
                                    fontSize: 12,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                          ],
                        ),
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
  }

  Widget _buildPosterPlaceholder() {
    return Container(
      color: Colors.grey.withOpacity(0.1),
      child: const Center(
        child: Icon(Icons.movie_filter, color: Colors.white24, size: 30),
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.amber, size: 12),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
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
                  fontWeight: FontWeight.w600),
            ),
            Text(
              '"${widget.searchQuery}"',
              style: TextStyle(
                  color: Colors.amber,
                  fontSize: 14,
                  fontWeight: FontWeight.w400),
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
          // Voice search info
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(12),
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
                      color: widget.aiAnalysis != null
                          ? Colors.blue
                          : Colors.amber,
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
                              color: widget.aiAnalysis != null
                                  ? Colors.blue
                                  : Colors.amber,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Đã nhận dạng: "${widget.searchQuery}"',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 13),
                          ),
                          if (_useHybrid &&
                              translatedQuery != null &&
                              translatedQuery!.isNotEmpty)
                            Text(
                              'EN: "$translatedQuery"',
                              style: TextStyle(
                                  color: Colors.greenAccent.withOpacity(0.9),
                                  fontSize: 11),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Search results
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator(color: Colors.amber))
                : hasError
                ? Center(
                child: Text(errorMessage,
                    style: TextStyle(color: Colors.white)))
                : searchResults.isEmpty
                ? Center(
                child: Text('Không tìm thấy kết quả',
                    style: TextStyle(color: Colors.white)))
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: searchResults.length,
              itemBuilder: (context, index) {
                final item = searchResults[index];
                return _useHybrid
                    ? _buildHybridResultCard(item)
                    : _buildTmdbResultCard(context, item);
              },
            ),
          ),
        ],
      ),
    );
  }

  String _normalizeVoiceText(String text) {
    return text
        .replaceAll(RegExp(r'\bfim\b', caseSensitive: false), 'phim')
        .replaceAll(RegExp(r'\bfin\b', caseSensitive: false), 'phim');
  }

  String _getDefaultSearchQuery() {
    final raw = widget.aiAnalysis?['processed_query'] ??
        widget.aiAnalysis?['search_query'] ??
        widget.searchQuery;
    return _normalizeVoiceText(raw);
  }
}
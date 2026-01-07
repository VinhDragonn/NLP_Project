import 'package:flutter/material.dart';
import 'package:r08fullmovieapp/DetailScreen/checker.dart';
import 'package:r08fullmovieapp/DetailScreen/voice_search_result.dart';
import 'package:r08fullmovieapp/RepeatedFunction/repttext.dart';
import 'package:r08fullmovieapp/services/nlp_api_service.dart';
// import 'package:r08fullmovieapp/apikey/apikey.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:translator/translator.dart';

import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:async';
import 'dart:convert';

class searchbarfun extends StatefulWidget {
  const searchbarfun({super.key});

  @override
  State<searchbarfun> createState() => _searchbarfunState();
}

class _searchbarfunState extends State<searchbarfun> {
  ////////////////////////////////search bar function/////////////////////////////////////////////
  List<Map<String, dynamic>> searchresult = [];
  List<Map<String, dynamic>> hybridResults = [];
  bool isLoadingHybrid = false;
  Timer? _debounceTimer;
  final NLPApiService _nlpApiService = NLPApiService();

  Future<void> searchlistfunction(val) async {
    var searchurl =
        'https://api.themoviedb.org/3/search/multi?api_key=${dotenv.env['apikey']}&query=$val';
    var searchresponse = await http.get(Uri.parse(searchurl));
    if (searchresponse.statusCode == 200) {
      var tempdata = jsonDecode(searchresponse.body);
      var searchjson = tempdata['results'];
      for (var i = 0; i < searchjson.length; i++) {
        //only add value if all are present
        if (searchjson[i]['id'] != null &&
            searchjson[i]['poster_path'] != null &&
            searchjson[i]['vote_average'] != null &&
            searchjson[i]['media_type'] != null) {
          searchresult.add({
            'id': searchjson[i]['id'],
            'poster_path': searchjson[i]['poster_path'],
            'vote_average': searchjson[i]['vote_average'],
            'media_type': searchjson[i]['media_type'],
            'popularity': searchjson[i]['popularity'],
            'overview': searchjson[i]['overview'],
          });

          // searchresult = searchresult.toSet().toList();

          if (searchresult.length > 20) {
            searchresult.removeRange(20, searchresult.length);
          }
        } else {
          // Skip null values
        }
      }
    }
  }

  final TextEditingController searchtext = TextEditingController();
  bool showlist = false;
  var val1;
  
  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
  
  Future<void> _performHybridSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        hybridResults.clear();
        isLoadingHybrid = false;
      });
      return;
    }
    
    setState(() {
      isLoadingHybrid = true;
      hybridResults.clear();
    });
    
    try {
      // Translate to English for backend
      final GoogleTranslator translator = GoogleTranslator();
      final translation = await translator.translate(query.trim(), to: 'en');
      final englishQuery = translation.text.trim();
      
      // Call hybrid search
      final response = await _nlpApiService.hybridSearch(
        query: englishQuery,
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
      
      // Fetch poster data for each result
      await _attachPostersToHybridResults(mappedResults);
      
      if (mounted) {
        setState(() {
          hybridResults = mappedResults;
          isLoadingHybrid = false;
        });
      }
    } catch (e) {
      print('❌ Hybrid search error: $e');
      if (mounted) {
        setState(() {
          hybridResults.clear();
          isLoadingHybrid = false;
        });
      }
    }
  }
  
  Future<void> _attachPostersToHybridResults(List<Map<String, dynamic>> results) async {
    final Map<String, Map<String, dynamic>?> posterCache = {};
    
    for (var item in results) {
      final title = (item['title'] ?? '').toString().trim();
      if (title.isEmpty) continue;
      
      try {
        final searchUrl = 'https://api.themoviedb.org/3/search/multi?api_key=${dotenv.env['apikey']}&query=${Uri.encodeComponent(title)}';
        final response = await http.get(Uri.parse(searchUrl));
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final matches = (data['results'] as List?) ?? [];
          
          if (matches.isNotEmpty) {
            final match = matches[0];
            final posterPath = match['poster_path'];
            final posterUrl = posterPath != null 
                ? 'https://image.tmdb.org/t/p/w500$posterPath'
                : null;
            
            item['posterUrl'] = posterUrl;
            item['tmdbId'] = match['id'];
            item['mediaType'] = (match['media_type'] ?? 'movie').toString();
            item['overview'] = match['overview'];
            item['voteAverage'] = (match['vote_average'] as num?)?.toDouble() ?? 0.0;
          }
        }
      } catch (e) {
        print('⚠️ Error fetching poster for $title: $e');
      }
    }
  }
  
  ////////////////////////////////search bar function/////////////////////////////////////////////
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
        showlist = !showlist;
      },
      child: Padding(
          padding:
              const EdgeInsets.only(left: 10.0, top: 30, bottom: 20, right: 10),
          child: Column(
            children: [
              Container(
                height: 50,
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.all(Radius.circular(10))),
                child: TextField(
                  autofocus: false,
                  controller: searchtext,
                  onSubmitted: (value) async {
                    if (value.trim().isEmpty) {
                      return;
                    }
                    
                    // Clear focus
                    FocusManager.instance.primaryFocus?.unfocus();
                    
                    // Process with NLP and navigate to hybrid search
                    try {
                      final nlpResult = await _nlpApiService.processVoiceSearch(
                        voiceText: value.trim(),
                        language: 'vi',
                      );
                      
                      // Navigate to hybrid search result page
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VoiceSearchResultPage(
                            searchQuery: value.trim(),
                            useHybrid: true,
                            aiAnalysis: {
                              'search_query': nlpResult['processed_query'],
                              'processed_query': nlpResult['processed_query'] ?? value.trim(),
                              'original_query': value.trim(),
                              'intent': nlpResult['intent'],
                              'confidence': nlpResult['confidence'],
                              'entities': nlpResult['entities'],
                              'search_parameters': nlpResult['search_parameters'],
                              'expanded_queries': nlpResult['expanded_queries'],
                              'nlp_analysis': nlpResult['analysis'],
                            },
                          ),
                        ),
                      );
                    } catch (e) {
                      // Fallback to old search if NLP fails
                      print('❌ NLP Error: $e');
                      searchresult.clear();
                      setState(() {
                        val1 = value;
                        FocusManager.instance.primaryFocus?.unfocus();
                      });
                      await searchlistfunction(value);
                    }
                  },
                  onChanged: (value) {
                    setState(() {
                      val1 = value;
                    });
                    
                    // Debounce hybrid search
                    _debounceTimer?.cancel();
                    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
                      _performHybridSearch(value);
                    });
                  },
                  decoration: InputDecoration(
                      suffixIcon: IconButton(
                        onPressed: () {
                          Fluttertoast.showToast(
                              webBgColor: "#000000",
                              webPosition: "center",
                              webShowClose: true,
                              msg: "Search Cleared",
                              toastLength: Toast.LENGTH_SHORT,
                              gravity: ToastGravity.BOTTOM,
                              timeInSecForIosWeb: 2,
                              backgroundColor: Color.fromRGBO(18, 18, 18, 1),
                              textColor: Colors.white,
                              fontSize: 16.0);

                          setState(() {
                            searchtext.clear();
                            FocusManager.instance.primaryFocus?.unfocus();
                          });
                        },
                        icon: Icon(
                          Icons.arrow_back_ios_rounded,
                          color: Colors.amber.withOpacity(0.6),
                        ),
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.amber,
                      ),
                      hintText: 'Search',
                      hintStyle:
                          TextStyle(color: Colors.white.withOpacity(0.2)),
                      border: InputBorder.none),
                ),
              ),
              //
              //
              SizedBox(
                height: 5,
              ),

              //if textfield has focus and search result is not empty then display search result

              searchtext.text.isNotEmpty
                  ? isLoadingHybrid
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(
                              color: Colors.amber,
                            ),
                          ),
                        )
                      : hybridResults.isEmpty
                          ? Container()
                          : SizedBox(
                              height: 400,
                              child: ListView.builder(
                                  itemCount: hybridResults.length,
                                  scrollDirection: Axis.vertical,
                                  physics: BouncingScrollPhysics(),
                                  itemBuilder: (context, index) {
                                    final item = hybridResults[index];
                                    final title = (item['title'] ?? '').toString();
                                    final score = (item['score'] as num?)?.toDouble() ?? 0.0;
                                    final genres = (item['genres'] ?? '').toString();
                                    final plot = (item['plot'] ?? '').toString();
                                    final posterUrl = item['posterUrl'] as String?;
                                    final tmdbId = item['tmdbId'];
                                    final mediaType = item['mediaType'] ?? 'movie';
                                    
                                    return GestureDetector(
                                        onTap: tmdbId != null
                                            ? () {
                                                Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (context) =>
                                                            descriptioncheckui(
                                                              tmdbId,
                                                              mediaType,
                                                            )));
                                              }
                                            : null,
                                        child: Container(
                                            margin: EdgeInsets.only(
                                                top: 4, bottom: 4),
                                            height: 180,
                                            width: MediaQuery.of(context)
                                                .size
                                                .width,
                                            decoration: BoxDecoration(
                                                color: Color.fromRGBO(
                                                    20, 20, 20, 1),
                                                borderRadius: BorderRadius.all(
                                                    Radius.circular(10)),
                                                border: Border.all(
                                                    color: Colors.green
                                                        .withOpacity(0.2))),
                                            child: Row(children: [
                                              // Poster image
                                              Container(
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.4,
                                                decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.only(
                                                          topLeft: Radius.circular(10),
                                                          bottomLeft: Radius.circular(10),
                                                        ),
                                                    image: posterUrl != null
                                                        ? DecorationImage(
                                                            image: NetworkImage(posterUrl),
                                                            fit: BoxFit.cover,
                                                          )
                                                        : null,
                                                    color: posterUrl == null
                                                        ? Colors.grey.withOpacity(0.3)
                                                        : null),
                                                child: posterUrl == null
                                                    ? Icon(
                                                        Icons.movie_outlined,
                                                        color: Colors.grey,
                                                        size: 40,
                                                      )
                                                    : null,
                                              ),
                                              SizedBox(
                                                width: 12,
                                              ),
                                              Expanded(
                                                child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(8.0),
                                                    child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment.start,
                                                        mainAxisAlignment:
                                                            MainAxisAlignment.spaceBetween,
                                                        children: [
                                                          // Title and score
                                                          Row(
                                                            children: [
                                                              Expanded(
                                                                child: Text(
                                                                  title.isNotEmpty
                                                                      ? title
                                                                      : 'Chưa rõ tên phim',
                                                                  style: TextStyle(
                                                                      color: Colors.white,
                                                                      fontSize: 14,
                                                                      fontWeight: FontWeight.w600),
                                                                  maxLines: 2,
                                                                  overflow: TextOverflow.ellipsis,
                                                                ),
                                                              ),
                                                              Container(
                                                                padding: EdgeInsets.symmetric(
                                                                    horizontal: 8, vertical: 4),
                                                                decoration: BoxDecoration(
                                                                    color: Colors.green
                                                                        .withOpacity(0.15),
                                                                    borderRadius:
                                                                        BorderRadius.circular(20)),
                                                                child: Row(
                                                                  mainAxisSize: MainAxisSize.min,
                                                                  children: [
                                                                    Icon(Icons.bolt,
                                                                        color: Colors.greenAccent,
                                                                        size: 14),
                                                                    SizedBox(width: 4),
                                                                    Text(
                                                                      score.toStringAsFixed(2),
                                                                      style: TextStyle(
                                                                          color: Colors.greenAccent,
                                                                          fontSize: 11,
                                                                          fontWeight: FontWeight.w600),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          SizedBox(height: 4),
                                                          // Genres
                                                          if (genres.isNotEmpty)
                                                            Text(
                                                              genres.length > 50
                                                                  ? '${genres.substring(0, 50)}...'
                                                                  : genres,
                                                              style: TextStyle(
                                                                  color: Colors.amber,
                                                                  fontSize: 11),
                                                              maxLines: 1,
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                          SizedBox(height: 4),
                                                          // Plot
                                                          Expanded(
                                                            child: Text(
                                                              plot.trim().isNotEmpty
                                                                  ? plot
                                                                  : 'Không có mô tả.',
                                                              style: TextStyle(
                                                                  fontSize: 11,
                                                                  color: Colors.white.withOpacity(0.7)),
                                                              maxLines: 4,
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                          ),
                                                        ])),
                                              ),
                                            ])));
                                  }))
                          : Container(),
            ],
          )),
    );
  }
}

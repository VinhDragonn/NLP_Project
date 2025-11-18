import 'package:flutter/material.dart';
import 'package:r08fullmovieapp/DetailScreen/checker.dart';
import 'package:r08fullmovieapp/RepeatedFunction/repttext.dart';
import 'package:r08fullmovieapp/services/google_voice_service.dart';
// import 'package:r08fullmovieapp/apikey/apikey.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';

import 'dart:convert';

class searchbarfun extends StatefulWidget {
  const searchbarfun({super.key});

  @override
  State<searchbarfun> createState() => _searchbarfunState();
}

class _searchbarfunState extends State<searchbarfun> {
  ////////////////////////////////search bar function/////////////////////////////////////////////
  List<Map<String, dynamic>> searchresult = [];
  bool _isListening = false;
  bool _isVoiceAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkVoiceAvailability();
  }

  Future<void> _checkVoiceAvailability() async {
    _isVoiceAvailable = await GoogleVoiceService.initializeSpeech();
    if (mounted) {
      setState(() {});
    }
  }
  
  @override
  void dispose() {
    // Clean up resources
    super.dispose();
  }

  void _showGoogleAnalysisInfo(String voiceText, Map<String, dynamic> googleAnalysis) {
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
                googleAnalysis['search_query'] ?? '',
                style: TextStyle(color: Colors.green, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              if (googleAnalysis['search_type'] != null)
                Text(
                  'Loại tìm kiếm: ${_getSearchTypeText(googleAnalysis['search_type'])}',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              if (googleAnalysis['intent'] != null)
                Text(
                  'Ý định: ${_getIntentText(googleAnalysis['intent'])}',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              if (googleAnalysis['confidence'] != null)
                Text(
                  'Độ chính xác: ${(googleAnalysis['confidence'] * 100).toStringAsFixed(1)}%',
                  style: TextStyle(color: Colors.green, fontSize: 12),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Đóng', style: TextStyle(color: Colors.amber)),
            ),
          ],
        );
      },
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
                  onSubmitted: (value) {
                    searchresult.clear();
                    setState(() {
                      val1 = value;
                      FocusManager.instance.primaryFocus?.unfocus();
                    });
                  },
                  onChanged: (value) {
                    searchresult.clear();

                    setState(() {
                      val1 = value;
                    });
                  },
                  decoration: InputDecoration(
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Voice search button
                          if (_isVoiceAvailable)
                            IconButton(
                              onPressed: () async {
                                await GoogleVoiceService.startListening(
                                  onResult: (String recognizedText, Map<String, dynamic> googleAnalysis) {
                                    String processedText = googleAnalysis['search_query'] ?? recognizedText;
                                    setState(() {
                                      searchtext.text = processedText;
                                      val1 = processedText;
                                      searchresult.clear();
                                    });
                                    // Trigger search with Google analysis
                                    searchlistfunction(processedText);
                                    
                                    // Show Google analysis info
                                    _showGoogleAnalysisInfo(recognizedText, googleAnalysis);
                                  },
                                  onListeningChanged: () {
                                    setState(() {
                                      _isListening = GoogleVoiceService.isListening;
                                    });
                                  },
                                );
                              },
                              icon: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                child: Icon(
                                  _isListening ? Icons.mic : Icons.mic_none,
                                  color: _isListening 
                                      ? Colors.red 
                                      : Colors.amber.withOpacity(0.6),
                                ),
                              ),
                            ),
                          // Clear search button
                          IconButton(
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
                        ],
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

              // Voice search status indicator
              if (_isListening)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.mic,
                        color: Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Đang lắng nghe... Hãy nói tên phim bạn muốn tìm",
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              //if textfield has focus and search result is not empty then display search result

              searchtext.text.isNotEmpty
                  ? FutureBuilder(
                      future: searchlistfunction(val1),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done) {
                          return SizedBox(
                              height: 400,
                              child: ListView.builder(
                                  itemCount: searchresult.length,
                                  scrollDirection: Axis.vertical,
                                  physics: BouncingScrollPhysics(),
                                  itemBuilder: (context, index) {
                                    return GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      descriptioncheckui(
                                                        searchresult[index]
                                                            ['id'],
                                                        searchresult[index]
                                                            ['media_type'],
                                                      )));
                                        },
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
                                                    Radius.circular(10))),
                                            child: Row(children: [
                                              Container(
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.4,
                                                decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.all(
                                                            Radius.circular(
                                                                10)),
                                                    image: DecorationImage(
                                                        //color filter

                                                        image: NetworkImage(
                                                            'https://image.tmdb.org/t/p/w500${searchresult[index]['poster_path']}'),
                                                        fit: BoxFit.fill)),
                                              ),
                                              SizedBox(
                                                width: 20,
                                              ),
                                              Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: Container(
                                                      child: Column(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                          children: [
                                                        ///////////////////////
                                                        //media type
                                                        Container(
                                                          alignment: Alignment
                                                              .topCenter,
                                                          child: tittletext(
                                                            '${searchresult[index]['media_type']}',
                                                          ),
                                                        ),

                                                        Container(
                                                          child: Row(
                                                            children: [
                                                              //vote average box
                                                              Container(
                                                                padding:
                                                                    EdgeInsets
                                                                        .all(5),
                                                                height: 30,
                                                                // width:
                                                                //     100,
                                                                decoration: BoxDecoration(
                                                                    color: Colors
                                                                        .amber
                                                                        .withOpacity(
                                                                            0.2),
                                                                    borderRadius:
                                                                        BorderRadius.all(
                                                                            Radius.circular(6))),
                                                                child: Center(
                                                                  child: Row(
                                                                    mainAxisAlignment:
                                                                        MainAxisAlignment
                                                                            .center,
                                                                    children: [
                                                                      Icon(
                                                                        Icons
                                                                            .star,
                                                                        color: Colors
                                                                            .amber,
                                                                        size:
                                                                            20,
                                                                      ),
                                                                      SizedBox(
                                                                        width:
                                                                            5,
                                                                      ),
                                                                      ratingtext(
                                                                          '${searchresult[index]['vote_average']}')
                                                                    ],
                                                                  ),
                                                                ),
                                                              ),
                                                              SizedBox(
                                                                width: 10,
                                                              ),

                                                              //popularity
                                                              Container(
                                                                padding:
                                                                    EdgeInsets
                                                                        .all(5),
                                                                height: 30,
                                                                decoration: BoxDecoration(
                                                                    color: Colors
                                                                        .amber
                                                                        .withOpacity(
                                                                            0.2),
                                                                    borderRadius:
                                                                        BorderRadius.all(
                                                                            Radius.circular(8))),
                                                                child: Center(
                                                                  child: Row(
                                                                    mainAxisAlignment:
                                                                        MainAxisAlignment
                                                                            .center,
                                                                    children: [
                                                                      Icon(
                                                                        Icons
                                                                            .people_outline_sharp,
                                                                        color: Colors
                                                                            .amber,
                                                                        size:
                                                                            20,
                                                                      ),
                                                                      SizedBox(
                                                                        width:
                                                                            5,
                                                                      ),
                                                                      ratingtext(
                                                                          '${searchresult[index]['popularity']}')
                                                                    ],
                                                                  ),
                                                                ),
                                                              ),

                                                              //
                                                            ],
                                                          ),
                                                        ),

                                                        SizedBox(
                                                            width: MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width *
                                                                0.4,
                                                            height: 85,
                                                            child: Text(
                                                                textAlign:
                                                                    TextAlign
                                                                        .left,
                                                                ' ${searchresult[index]['overview']}',
                                                                // 'dsfsafsdffdsfsdf sdfsadfsdf sadfsafd',
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        12,
                                                                    color: Colors
                                                                        .white)))
                                                      ])))
                                            ])));
                                  }));
                        } else {
                          return Center(
                              child: CircularProgressIndicator(
                            color: Colors.amber,
                          ));
                        }
                      })
                  : Container(),
            ],
          )),
    );
  }
}

import 'dart:async';
import 'dart:convert';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:r08fullmovieapp/DetailScreen/checker.dart';
import 'package:r08fullmovieapp/DetailScreen/voice_search_result.dart';
import 'package:r08fullmovieapp/RepeatedFunction/repttext.dart';
import 'package:flutter/material.dart';
import 'package:r08fullmovieapp/RepeatedFunction/searchbarfunc.dart';
import 'package:r08fullmovieapp/widgets/nlp_voice_search_button.dart'; // NLP Voice Search
import '../SectionHomeUi/movie.dart';
import '../SectionHomeUi/tvseries.dart';
import '../SectionHomeUi/upcomming.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import '../RepeatedFunction/Drawer.dart';

class MyHomePage extends StatefulWidget {
  final String? apikey;
  const MyHomePage({super.key, this.apikey});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  List<Map<String, dynamic>> trendingweek = [];
  int uval = 1;

  Future<void> trendinglist(int checkerno) async {
    if (widget.apikey == null) {
      return;
    }

    if (checkerno == 1) {
      var trendingweekurl =
          'https://api.themoviedb.org/3/trending/all/week?api_key=${widget.apikey}';
      var trendingweekresponse = await http.get(Uri.parse(trendingweekurl));
      if (trendingweekresponse.statusCode == 200) {
        var tempdata = jsonDecode(trendingweekresponse.body);
        var trendingweekjson = tempdata['results'];
        for (var i = 0; i < trendingweekjson.length; i++) {
          trendingweek.add({
            'id': trendingweekjson[i]['id'],
            'poster_path': trendingweekjson[i]['poster_path'],
            'vote_average': trendingweekjson[i]['vote_average'],
            'media_type': trendingweekjson[i]['media_type'],
            'indexno': i,
          });
        }
      } else {
        // Error handling
      }
    } else if (checkerno == 2) {
      var trendingweekurl =
          'https://api.themoviedb.org/3/trending/all/day?api_key=${widget.apikey}';
      var trendingweekresponse = await http.get(Uri.parse(trendingweekurl));
      if (trendingweekresponse.statusCode == 200) {
        var tempdata = jsonDecode(trendingweekresponse.body);
        var trendingweekjson = tempdata['results'];
        for (var i = 0; i < trendingweekjson.length; i++) {
          trendingweek.add({
            'id': trendingweekjson[i]['id'],
            'poster_path': trendingweekjson[i]['poster_path'],
            'vote_average': trendingweekjson[i]['vote_average'],
            'media_type': trendingweekjson[i]['media_type'],
            'indexno': i,
          });
        }
      } else {
        // Error handling
      }
    }
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    // Gọi trendinglist trong initState để đảm bảo dữ liệu được tải trước
    trendinglist(uval);
  }

  @override
  Widget build(BuildContext context) {
    TabController tabController = TabController(length: 3, vsync: this);

    return Scaffold(
      drawer: drawerfunc(),
      backgroundColor: const Color.fromRGBO(18, 18, 18, 0.5),
      // Nút NLP Voice Search (Thuật toán tự code)
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Nút NLP Voice Search (Thuật toán tự code - Mới)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // NLP Voice Search - Tiếng Việt
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  NLPVoiceSearchButton(
                onResult: (String recognizedText, Map<String, dynamic> nlpResult) {
                  print('🎤 Voice: $recognizedText');
                  print('🎯 Intent: ${nlpResult['intent']}');
                  print('🔄 Processed: ${nlpResult['processed_query']}');
                  print('📊 Confidence: ${nlpResult['confidence']}');
                  
                  // Tự động navigate to search page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VoiceSearchResultPage(
                        searchQuery: nlpResult['processed_query'] ?? recognizedText,
                        aiAnalysis: {
                          'search_query': nlpResult['processed_query'],
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
                },
                initialLanguage: 'vi-VN',
              ),
              const SizedBox(height: 8),
              const Text(
                'NLP + ML',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
        ],
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            iconTheme: const IconThemeData(color: Colors.white),
            backgroundColor: const Color.fromRGBO(18, 18, 18, 0.9),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Trending 🔥',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  height: 45,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: DropdownButton(
                      autofocus: true,
                      underline: Container(height: 0, color: Colors.transparent),
                      dropdownColor: Colors.black.withOpacity(0.6),
                      icon: const Icon(
                        Icons.arrow_drop_down_sharp,
                        color: Colors.amber,
                        size: 30,
                      ),
                      value: uval,
                      items: const [
                        DropdownMenuItem(
                          value: 1,
                          child: Text(
                            'Weekly',
                            style: TextStyle(
                              decoration: TextDecoration.none,
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 2,
                          child: Text(
                            'Daily',
                            style: TextStyle(
                              decoration: TextDecoration.none,
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          trendingweek.clear();
                          uval = int.parse(value.toString());
                          trendinglist(uval);
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
            centerTitle: true,
            toolbarHeight: 60,
            pinned: true,
            expandedHeight: MediaQuery.of(context).size.height * 0.5,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: FutureBuilder(
                future: trendinglist(uval),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    if (trendingweek.isEmpty) {
                      return const Center(
                        child: Text(
                          "No data available",
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    }
                    return CarouselSlider(
                      options: CarouselOptions(
                        viewportFraction: 1,
                        autoPlay: true,
                        autoPlayInterval: const Duration(seconds: 2),
                        height: MediaQuery.of(context).size.height,
                      ),
                      items: trendingweek.map((i) {
                        return Builder(builder: (BuildContext context) {
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      descriptioncheckui(i['id'], i['media_type']),
                                ),
                              );
                            },
                            child: Container(
                              width: MediaQuery.of(context).size.width,
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  colorFilter: ColorFilter.mode(
                                    Colors.black.withOpacity(0.3),
                                    BlendMode.darken,
                                  ),
                                  image: NetworkImage(
                                      'https://image.tmdb.org/t/p/w500${i['poster_path']}'),
                                  fit: BoxFit.fill,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.only(
                                            left: 10, bottom: 6),
                                        child: Text(
                                          ' # ${i['indexno'] + 1}',
                                          style: TextStyle(
                                            color: Colors.amber.withOpacity(0.7),
                                            fontSize: 18,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        margin: const EdgeInsets.only(
                                            right: 8, bottom: 5),
                                        width: 90,
                                        padding: const EdgeInsets.all(5),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.withOpacity(0.2),
                                          borderRadius: const BorderRadius.all(
                                              Radius.circular(8)),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                          children: [
                                            const Icon(
                                              Icons.star,
                                              color: Colors.amber,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              '${i['vote_average']}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        });
                      }).toList(),
                    );
                  } else {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.amber),
                    );
                  }
                },
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              searchbarfun(),
              Padding(
                padding: const EdgeInsets.only(left: 10, right: 10),
                child: SizedBox(
                  height: 50,
                  width: MediaQuery.of(context).size.width,
                  child: TabBar(
                    dividerColor: Colors.transparent,
                    physics: const BouncingScrollPhysics(),
                    labelPadding: const EdgeInsets.symmetric(horizontal: 0),
                    controller: tabController,
                    indicator: BoxDecoration(
                      color: Colors.amber.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    tabs: const [
                      Tab(
                        child: Center(
                          child: Text(
                            'Tv Series',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      Tab(
                        child: Center(
                          child: Text(
                            'Movies',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      Tab(
                        child: Center(
                          child: Text(
                            'Upcoming',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                height: 1100,
                width: MediaQuery.of(context).size.width,
                child: TabBarView(
                  controller: tabController,
                  children: const [
                    TvSeries(),
                    Movie(),
                    Upcomming(),
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

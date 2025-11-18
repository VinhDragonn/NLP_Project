import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'MovieByTagScreen.dart';

class TagList extends StatefulWidget {
  @override
  State<TagList> createState() => _TagListState();
}

class _TagListState extends State<TagList> {
  List genres = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchGenres();
  }

  Future<void> fetchGenres() async {
    final url =
        'https://api.themoviedb.org/3/genre/movie/list?api_key=0db97c6b458a3b54cbe7a8b0b01aac26&language=en-US';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        genres = data['genres'];
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(18, 18, 18, 0.9),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('Tags / Genres'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.amber))
          : genres.isEmpty
              ? Center(
                  child: Text('No genres found',
                      style: TextStyle(color: Colors.white)))
              : ListView.builder(
                  itemCount: genres.length,
                  itemBuilder: (context, index) {
                    final genre = genres[index];
                    return Card(
                      color: Colors.grey[900],
                      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        title: Text(
                          genre['name'],
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                        trailing:
                            Icon(Icons.arrow_forward_ios, color: Colors.white),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MovieByTagScreen(
                                tag: genre['name'],
                                genreId: genre['id'],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}

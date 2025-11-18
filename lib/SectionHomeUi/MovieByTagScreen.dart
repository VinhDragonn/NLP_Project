import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../DetailScreen/MovieDetails.dart';

class MovieByTagScreen extends StatefulWidget {
  final String tag;
  final int genreId;
  const MovieByTagScreen({Key? key, required this.tag, required this.genreId})
      : super(key: key);

  @override
  State<MovieByTagScreen> createState() => _MovieByTagScreenState();
}

class _MovieByTagScreenState extends State<MovieByTagScreen> {
  List movies = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchMoviesByTag();
  }

  Future<void> fetchMoviesByTag() async {
    final url =
        'https://api.themoviedb.org/3/discover/movie?api_key=0db97c6b458a3b54cbe7a8b0b01aac26&with_genres=${widget.genreId}';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        movies = data['results'];
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
        title: Text('${widget.tag} Movies'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.amber))
          : movies.isEmpty
              ? Center(
                  child: Text('No movies found',
                      style: TextStyle(color: Colors.white)))
              : ListView.builder(
                  itemCount: movies.length,
                  itemBuilder: (context, index) {
                    final movie = movies[index];
                    return Card(
                      color: Colors.grey[900],
                      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: movie['poster_path'] != null
                            ? Image.network(
                                'https://image.tmdb.org/t/p/w200${movie['poster_path']}',
                                width: 50,
                                height: 75,
                                fit: BoxFit.cover,
                              )
                            : Icon(Icons.movie, color: Colors.white),
                        title: Text(
                          movie['title'] ?? 'Unknown Title',
                          style: TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          'Rating: ${movie['vote_average']}',
                          style: TextStyle(color: Colors.grey),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  MovieDetails(id: movie['id']),
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

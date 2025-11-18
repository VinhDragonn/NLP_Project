import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:r08fullmovieapp/services/history_service.dart';

class HistoryList extends StatelessWidget {
  final HistoryService _historyService = HistoryService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(18, 18, 18, 0.9),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('Watch History'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _historyService.getHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No watch history yet',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            );
          }
          final docs = snapshot.data!.docs;
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final movie = docs[index].data();
              return Card(
                color: Colors.grey[900],
                margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: movie['poster_path'] != null && movie['poster_path'] != ''
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
                    'Watched on: \\${movie['watched_at'] ?? 'Unknown date'}',
                    style: TextStyle(color: Colors.grey),
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      await _historyService.removeHistory(docs[index].id);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class MlPredictService {
  final String baseUrl;

  MlPredictService({String? baseUrl}) : baseUrl = baseUrl ?? (dotenv.env['ML_URL'] ?? 'http://127.0.0.1:8000');

  Future<Map<String, dynamic>> predict({
    String? movieTitle,
    required String directors,
    required String genres,
    required String productionCompany,
    required double runtime,
    required double releaseYear,
    double? audienceRating,      // Optional - chỉ dùng cho model cũ
    double? tomatometerCount,    // Optional
    double? audienceCount,       // Optional
  }) async {
    final uri = Uri.parse('$baseUrl/predict');
    final payload = {
      if (movieTitle != null) 'movie_title': movieTitle,
      'directors': directors,
      'genres': genres,
      'production_company': productionCompany,
      'runtime': runtime,
      'release_year': releaseYear,
      // Chỉ gửi nếu có (để tương thích cả 2 model)
      if (audienceRating != null) 'audience_rating': audienceRating,
      if (tomatometerCount != null) 'tomatometer_count': tomatometerCount,
      if (audienceCount != null) 'audience_count': audienceCount,
    };

    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (res.statusCode != 200) {
      throw Exception('Prediction failed: ${res.statusCode} ${res.body}');
    }

    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}

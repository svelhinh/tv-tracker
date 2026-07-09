import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/tmdb_config.dart';
import '../domain/tmdb_show_search_result.dart';

class TmdbClient {
  TmdbClient({
    http.Client? httpClient,
    String? apiKey,
    this.language = 'fr-FR',
  })  : _httpClient = httpClient ?? http.Client(),
        _apiKey = apiKey ?? tmdbApiKey;

  final http.Client _httpClient;
  final String _apiKey;
  final String language;

  Future<List<TmdbShowSearchResult>> searchTv(String query) async {
    if (_apiKey.isEmpty) {
      throw const TmdbException('TMDB_API_KEY manquant.');
    }

    final uri = Uri.parse('$tmdbApiBaseUrl/search/tv').replace(
      queryParameters: {
        'api_key': _apiKey,
        'query': query,
        'language': language,
        'include_adult': 'false',
      },
    );

    final response = await _httpClient.get(uri);
    if (response.statusCode != 200) {
      throw TmdbException(
        'Recherche TMDB échouée (${response.statusCode}) pour "$query".',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final results = json['results'] as List<dynamic>? ?? [];

    return results
        .whereType<Map<String, dynamic>>()
        .map(TmdbShowSearchResult.fromJson)
        .where((result) => result.name.isNotEmpty)
        .toList();
  }

  void close() => _httpClient.close();
}

class TmdbException implements Exception {
  const TmdbException(this.message);

  final String message;

  @override
  String toString() => message;
}

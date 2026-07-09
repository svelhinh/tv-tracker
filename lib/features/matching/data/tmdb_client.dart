import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/tmdb_config.dart';
import '../../../core/metrics/tmdb_api_metrics.dart';
import '../domain/tmdb_show_search_result.dart';

class TmdbClient {
  TmdbClient({
    http.Client? httpClient,
    String? apiKey,
    this.language = 'fr-FR',
    this._metrics,
  }) : _httpClient = httpClient ?? http.Client(),
       _apiKey = apiKey ?? tmdbApiKey;

  final http.Client _httpClient;
  final String _apiKey;
  final String language;
  final TmdbApiMetrics? _metrics;
  final Map<String, List<TmdbShowSearchResult>> _searchCache = {};

  Future<List<TmdbShowSearchResult>> searchTv(String query) async {
    if (_apiKey.isEmpty) {
      throw const TmdbException('TMDB_API_KEY manquant.');
    }

    final cacheKey = query.trim().toLowerCase();
    final cached = _searchCache[cacheKey];
    if (cached != null) {
      _metrics?.recordCacheHit();
      return cached;
    }

    final uri = Uri.parse('$tmdbApiBaseUrl/search/tv').replace(
      queryParameters: {
        'api_key': _apiKey,
        'query': query,
        'language': language,
        'include_adult': 'false',
      },
    );

    final stopwatch = Stopwatch()..start();
    var failed = false;

    try {
      final response = await _httpClient.get(uri);
      if (response.statusCode != 200) {
        failed = true;
        throw TmdbException(
          'Recherche TMDB échouée (${response.statusCode}) pour "$query".',
        );
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final results = json['results'] as List<dynamic>? ?? [];

      final parsed = results
          .whereType<Map<String, dynamic>>()
          .map(TmdbShowSearchResult.fromJson)
          .where((result) => result.name.isNotEmpty)
          .toList();

      _searchCache[cacheKey] = parsed;
      return parsed;
    } finally {
      stopwatch.stop();
      _metrics?.recordCall(latency: stopwatch.elapsed, failed: failed);
    }
  }

  void close() => _httpClient.close();
}

class TmdbException implements Exception {
  const TmdbException(this.message);

  final String message;

  @override
  String toString() => message;
}

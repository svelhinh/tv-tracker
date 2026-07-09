import 'package:flutter_test/flutter_test.dart';
import 'package:tv_tracker/features/import/domain/tv_time_show.dart';
import 'package:tv_tracker/features/matching/data/tmdb_client.dart';
import 'package:tv_tracker/features/matching/data/tmdb_show_matcher.dart';
import 'package:tv_tracker/features/matching/domain/show_match_result.dart';
import 'package:tv_tracker/features/matching/domain/tmdb_show_search_result.dart';

class _FakeTmdbClient extends TmdbClient {
  _FakeTmdbClient(this._responses) : super(apiKey: 'test');

  final Map<String, List<TmdbShowSearchResult>> _responses;

  @override
  Future<List<TmdbShowSearchResult>> searchTv(String query) async {
    return _responses[query] ?? [];
  }

  @override
  void close() {}
}

void main() {
  group('TmdbShowMatcher', () {
    test('picks confident match on exact title', () async {
      final client = _FakeTmdbClient({
        'Attack on Titan': [
          const TmdbShowSearchResult(id: 1429, name: 'Attack on Titan'),
          const TmdbShowSearchResult(
            id: 999,
            name: 'Attack on Titan: No Regrets',
          ),
        ],
      });
      final matcher = TmdbShowMatcher(client);

      final report = await matcher.matchShows([
        const TvTimeShow(tvTimeId: '1', name: 'Attack on Titan'),
      ], sampleSize: 1);

      expect(report.confidentCount, 1);
      expect(report.results.first.tmdbId, 1429);
      expect(report.results.first.tmdbPosterPath, isNull);
      expect(report.results.first.confidence, ShowMatchConfidence.confident);
    });

    test('marks ambiguous when candidates are close', () async {
      final client = _FakeTmdbClient({
        'The Office': [
          const TmdbShowSearchResult(id: 2316, name: 'The Office'),
          const TmdbShowSearchResult(id: 8592, name: 'The Office'),
        ],
      });
      final matcher = TmdbShowMatcher(client);

      final report = await matcher.matchShows([
        const TvTimeShow(tvTimeId: '1', name: 'The Office'),
      ], sampleSize: 1);

      expect(report.results.first.confidence, ShowMatchConfidence.ambiguous);
    });

    test('returns no match when search is empty', () async {
      final client = _FakeTmdbClient({});
      final matcher = TmdbShowMatcher(client);

      final report = await matcher.matchShows([
        const TvTimeShow(tvTimeId: '1', name: 'Série Inconnue XYZ'),
      ], sampleSize: 1);

      expect(report.noMatchCount, 1);
      expect(report.results.first.confidence, ShowMatchConfidence.noMatch);
    });

    test('resolves poster path from best match', () async {
      final client = _FakeTmdbClient({
        'Arcane': [
          const TmdbShowSearchResult(
            id: 94605,
            name: 'Arcane',
            posterPath: '/arcane.jpg',
          ),
        ],
      });
      final matcher = TmdbShowMatcher(client);

      final posterPath = await matcher.resolvePosterPath(
        const TvTimeShow(tvTimeId: '1', name: 'Arcane'),
      );

      expect(posterPath, '/arcane.jpg');
    });
  });
}

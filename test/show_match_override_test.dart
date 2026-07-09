import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tv_tracker/features/import/domain/tv_time_show.dart';
import 'package:tv_tracker/features/matching/data/show_match_override_store.dart';
import 'package:tv_tracker/features/matching/data/tmdb_client.dart';
import 'package:tv_tracker/features/matching/data/tmdb_show_matcher.dart';
import 'package:tv_tracker/features/matching/domain/show_match_override.dart';
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
  group('ShowMatchOverrideStore', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('persists manual match and reloads it', () async {
      final store = ShowMatchOverrideStore();
      await store.save(
        ShowMatchOverride.matched(
          tvTimeShowId: '42',
          tmdbId: 100,
          tmdbName: 'Test Show',
          tmdbFirstAirDate: '2020-01-01',
        ),
      );

      final loaded = await store.loadAll();
      expect(loaded['42']?.tmdbId, 100);
      expect(loaded['42']?.tmdbName, 'Test Show');
    });

    test('persists ignored show', () async {
      final store = ShowMatchOverrideStore();
      await store.save(ShowMatchOverride.ignored(tvTimeShowId: '99'));

      final loaded = await store.loadAll();
      expect(loaded['99']?.isIgnored, isTrue);
    });
  });

  group('TmdbShowMatcher overrides', () {
    test('uses saved manual match without calling search', () async {
      final client = _FakeTmdbClient({});
      final matcher = TmdbShowMatcher(client);

      final report = await matcher.matchShows(
        const [TvTimeShow(tvTimeId: '1', name: 'Arrow')],
        overrides: {
          '1': ShowMatchOverride.matched(
            tvTimeShowId: '1',
            tmdbId: 1412,
            tmdbName: 'Arrow',
          ),
        },
      );

      expect(report.results.first.confidence, ShowMatchConfidence.manual);
      expect(report.results.first.tmdbId, 1412);
    });

    test('marks ignored shows and skips search', () async {
      final client = _FakeTmdbClient({});
      final matcher = TmdbShowMatcher(client);

      final report = await matcher.matchShows(
        const [TvTimeShow(tvTimeId: '2', name: 'Armor Wars')],
        overrides: {
          '2': ShowMatchOverride.ignored(tvTimeShowId: '2'),
        },
      );

      expect(report.results.first.confidence, ShowMatchConfidence.ignored);
    });
  });
}

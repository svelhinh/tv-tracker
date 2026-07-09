import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/tmdb_config.dart';
import '../../import/application/tv_time_import_provider.dart';
import '../data/show_match_override_store.dart';
import '../data/tmdb_client.dart';
import '../data/tmdb_show_matcher.dart';
import '../domain/show_match_override.dart';
import '../domain/show_match_report.dart';
import '../domain/tmdb_show_search_result.dart';

final tmdbClientProvider = Provider<TmdbClient>((ref) {
  final client = TmdbClient();
  ref.onDispose(client.close);
  return client;
});

final showMatchOverrideStoreProvider = Provider<ShowMatchOverrideStore>(
  (ref) => ShowMatchOverrideStore(),
);

final showMatchOverridesProvider =
    AsyncNotifierProvider<
      ShowMatchOverridesNotifier,
      Map<String, ShowMatchOverride>
    >(ShowMatchOverridesNotifier.new);

class ShowMatchOverridesNotifier
    extends AsyncNotifier<Map<String, ShowMatchOverride>> {
  @override
  Future<Map<String, ShowMatchOverride>> build() async {
    return ref.read(showMatchOverrideStoreProvider).loadAll();
  }

  Future<void> saveManualMatch({
    required String tvTimeShowId,
    required int tmdbId,
    required String tmdbName,
    String? tmdbFirstAirDate,
    String? tmdbPosterPath,
  }) async {
    final override = ShowMatchOverride.matched(
      tvTimeShowId: tvTimeShowId,
      tmdbId: tmdbId,
      tmdbName: tmdbName,
      tmdbFirstAirDate: tmdbFirstAirDate,
      tmdbPosterPath: tmdbPosterPath,
    );
    await ref.read(showMatchOverrideStoreProvider).save(override);
    state = AsyncData(await ref.read(showMatchOverrideStoreProvider).loadAll());
    ref.invalidate(tmdbMatchReportProvider);
  }

  Future<void> ignoreShow(String tvTimeShowId) async {
    final override = ShowMatchOverride.ignored(tvTimeShowId: tvTimeShowId);
    await ref.read(showMatchOverrideStoreProvider).save(override);
    state = AsyncData(await ref.read(showMatchOverrideStoreProvider).loadAll());
    ref.invalidate(tmdbMatchReportProvider);
  }
}

final tmdbMatchRequestIdProvider = StateProvider<int>((ref) => 0);

final tmdbMatchReportProvider = FutureProvider<ShowMatchReport?>((ref) async {
  final requestId = ref.watch(tmdbMatchRequestIdProvider);
  if (requestId == 0) return null;

  final import = await ref.watch(tvTimeImportProvider.future);
  if (import == null || import.shows.isEmpty) return null;
  if (!hasTmdbApiKey) {
    throw const TmdbException(
      'TMDB_API_KEY manquant. Ajoute-la dans .env ou lance avec '
      '--dart-define=TMDB_API_KEY=ta_cle',
    );
  }

  final overrides = await ref.watch(showMatchOverridesProvider.future);
  final matcher = TmdbShowMatcher(ref.watch(tmdbClientProvider));
  return matcher.matchShows(
    import.shows,
    sampleSize: defaultMatchSampleSize,
    overrides: overrides,
  );
});

final tmdbCandidatesProvider =
    FutureProvider.family<List<TmdbShowSearchResult>, String>((
      ref,
      tvTimeShowId,
    ) async {
      final import = await ref.watch(tvTimeImportProvider.future);
      if (import == null) return [];

      final show = import.shows.firstWhere(
        (entry) => entry.tvTimeId == tvTimeShowId,
        orElse: () => throw StateError('Série introuvable: $tvTimeShowId'),
      );

      final matcher = TmdbShowMatcher(ref.watch(tmdbClientProvider));
      return matcher.getCandidates(show);
    });

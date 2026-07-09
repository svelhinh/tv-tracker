import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/tmdb_config.dart';
import '../../import/application/tv_time_import_provider.dart';
import '../../import/domain/tv_time_show.dart';
import '../data/tmdb_show_matcher.dart';
import 'show_poster_provider.dart';
import 'tmdb_match_provider.dart';

final postImportTmdbSyncInProgressProvider = StateProvider<bool>(
  (ref) => false,
);

void startPostImportTmdbSync(WidgetRef ref) {
  if (!hasTmdbApiKey) return;

  final import = ref.read(tvTimeImportProvider).valueOrNull;
  if (import == null || import.shows.isEmpty) return;

  unawaited(_runSync(ref, import.shows));
}

Future<void> _runSync(WidgetRef ref, List<TvTimeShow> shows) async {
  if (ref.read(postImportTmdbSyncInProgressProvider)) return;

  ref.read(postImportTmdbSyncInProgressProvider.notifier).state = true;
  try {
    await syncTmdbForShows(ref, shows);
  } finally {
    ref.read(postImportTmdbSyncInProgressProvider.notifier).state = false;
  }
}

Future<void> syncTmdbForShows(WidgetRef ref, List<TvTimeShow> shows) async {
  if (!hasTmdbApiKey || shows.isEmpty) return;

  final overrides = await ref.read(showMatchOverridesProvider.future);
  final matcher = TmdbShowMatcher(ref.read(tmdbClientProvider));
  final report = await matcher.matchShows(shows, overrides: overrides);
  final posters = posterPathsFromMatchResults(report.results);

  if (posters.isNotEmpty) {
    await ref.read(showPosterCacheProvider.notifier).mergePosters(posters);
  }
}

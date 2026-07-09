import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/tmdb_config.dart';
import '../../../core/utils/tmdb_image.dart';
import '../../import/domain/tv_time_show.dart';
import '../../tracker/application/tracker_provider.dart';
import '../../tracker/domain/tracked_show.dart';
import '../data/poster_cache_store.dart';
import '../data/tmdb_client.dart';
import '../data/tmdb_show_matcher.dart';
import 'tmdb_match_provider.dart';

const showsPageSize = 20;
const _posterRequestDelayMs = 260;
const _noPosterSentinel = '';

final posterCacheStoreProvider = Provider<PosterCacheStore>(
  (ref) => PosterCacheStore(),
);

final showPosterCacheProvider =
    AsyncNotifierProvider<ShowPosterCacheNotifier, Map<String, String>>(
      ShowPosterCacheNotifier.new,
    );

final posterFetchInProgressProvider = StateProvider<bool>((ref) => false);

class ShowPosterCacheNotifier extends AsyncNotifier<Map<String, String>> {
  @override
  Future<Map<String, String>> build() async {
    return ref.read(posterCacheStoreProvider).loadAll();
  }

  Future<void> loadPostersForShows(List<TvTimeShow> shows) async {
    if (!hasTmdbApiKey || shows.isEmpty) return;
    if (ref.read(posterFetchInProgressProvider)) return;

    final cache = Map<String, String>.from(state.valueOrNull ?? {});
    final pending = shows
        .where((show) => !cache.containsKey(show.tvTimeId))
        .take(showsPageSize)
        .toList();
    if (pending.isEmpty) return;

    ref.read(posterFetchInProgressProvider.notifier).state = true;

    try {
      final overrides = ref.read(showMatchOverridesProvider).valueOrNull ?? {};
      final matcher = TmdbShowMatcher(ref.read(tmdbClientProvider));

      for (final show in pending) {
        final override = overrides[show.tvTimeId];
        if (override?.tmdbPosterPath != null &&
            override!.tmdbPosterPath!.isNotEmpty) {
          cache[show.tvTimeId] = override.tmdbPosterPath!;
          continue;
        }

        try {
          final posterPath = await matcher.resolvePosterPath(
            show,
            override: override,
          );
          cache[show.tvTimeId] = posterPath ?? _noPosterSentinel;
        } on TmdbException {
          cache[show.tvTimeId] = _noPosterSentinel;
        }

        await Future<void>.delayed(
          const Duration(milliseconds: _posterRequestDelayMs),
        );
      }

      await ref.read(posterCacheStoreProvider).saveAll(cache);
      state = AsyncData(cache);
    } finally {
      ref.read(posterFetchInProgressProvider.notifier).state = false;
    }
  }
}

final showPosterUrlProvider = Provider.family<String?, String>((ref, showId) {
  final overrides = ref.watch(showMatchOverridesProvider).valueOrNull ?? {};
  final override = overrides[showId];
  if (override?.tmdbPosterPath != null &&
      override!.tmdbPosterPath!.isNotEmpty) {
    return tmdbPosterUrl(override.tmdbPosterPath);
  }

  final cache = ref.watch(showPosterCacheProvider).valueOrNull ?? {};
  if (!cache.containsKey(showId)) return null;

  final posterPath = cache[showId];
  if (posterPath == null || posterPath.isEmpty) return null;
  return tmdbPosterUrl(posterPath);
});

final showsPageCountProvider = StateProvider<int>((ref) => 1);

final paginatedTrackedShowsProvider = Provider<PaginatedShows?>((ref) {
  final all = ref.watch(trackedShowsProvider);
  if (all == null) return null;

  final pageCount = ref.watch(showsPageCountProvider);
  final visibleCount = pageCount * showsPageSize;

  return PaginatedShows(
    items: all.take(visibleCount).toList(),
    totalCount: all.length,
    hasMore: all.length > visibleCount,
  );
});

class PaginatedShows {
  const PaginatedShows({
    required this.items,
    required this.totalCount,
    required this.hasMore,
  });

  final List<TrackedShow> items;
  final int totalCount;
  final bool hasMore;
}

Future<void> loadPostersForPage(WidgetRef ref, int pageNumber) async {
  final all = ref.read(trackedShowsProvider);
  if (all == null || pageNumber < 1) return;

  final start = (pageNumber - 1) * showsPageSize;
  if (start >= all.length) return;

  final end = start + showsPageSize;
  final shows = all
      .sublist(start, end > all.length ? all.length : end)
      .map((tracked) => tracked.show)
      .toList();

  await ref.read(showPosterCacheProvider.notifier).loadPostersForShows(shows);
}

void resetShowsPagination(WidgetRef ref) {
  ref.read(showsPageCountProvider.notifier).state = 1;
  ref.invalidate(showPosterCacheProvider);
}

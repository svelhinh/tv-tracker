import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../import/application/tv_time_import_provider.dart';
import '../../import/domain/tv_time_show.dart';
import '../../import/domain/tv_time_watched_episode.dart';
import '../data/watch_state_store.dart';
import '../domain/episode_key.dart';
import '../domain/show_detail.dart';
import '../domain/show_progress.dart';
import '../domain/tracked_show.dart';
import '../domain/watch_state_delta.dart';
import 'tracker_service.dart';

final watchStateStoreProvider = Provider<WatchStateStore>(
  (ref) => WatchStateStore(),
);

final watchStateProvider =
    AsyncNotifierProvider<WatchStateNotifier, Map<String, WatchStateDelta>>(
      WatchStateNotifier.new,
    );

class WatchStateNotifier extends AsyncNotifier<Map<String, WatchStateDelta>> {
  @override
  Future<Map<String, WatchStateDelta>> build() async {
    return ref.read(watchStateStoreProvider).loadAll();
  }

  Future<void> toggleEpisode({
    required TvTimeShow show,
    required int season,
    required int episode,
    required bool currentlyWatched,
  }) async {
    final import = await ref.read(tvTimeImportProvider.future);
    if (import == null) return;

    final key = EpisodeKey(season: season, episode: episode);
    final baseWatched = TrackerService.baseWatchedForShow(
      show,
      import.watchedEpisodes,
    );
    final currentDelta = state.valueOrNull?[show.tvTimeId];
    final nextDelta = TrackerService.toggleEpisode(
      key: key,
      currentlyWatched: currentlyWatched,
      baseWatched: baseWatched,
      currentDelta: currentDelta,
    );

    await ref.read(watchStateStoreProvider).save(show.tvTimeId, nextDelta);
    state = AsyncData({...?state.valueOrNull, show.tvTimeId: nextDelta});
  }
}

final trackedShowsProvider = Provider<List<TrackedShow>?>((ref) {
  final import = ref.watch(tvTimeImportProvider).valueOrNull;
  if (import == null) return null;

  final watchStates = ref.watch(watchStateProvider).valueOrNull ?? {};

  final shows = [...import.shows]
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  return shows
      .map(
        (show) => TrackedShow(
          show: show,
          progress: _progressForShow(
            show: show,
            watchedEpisodes: import.watchedEpisodes,
            watchState: watchStates[show.tvTimeId],
          ),
        ),
      )
      .toList();
});

final showDetailProvider = Provider.family<ShowDetail?, String>((ref, showId) {
  final import = ref.watch(tvTimeImportProvider).valueOrNull;
  if (import == null) return null;

  final matches = import.shows.where((entry) => entry.tvTimeId == showId);
  if (matches.isEmpty) return null;
  final show = matches.first;

  final watchStates = ref.watch(watchStateProvider).valueOrNull ?? {};
  final baseWatched = TrackerService.baseWatchedForShow(
    show,
    import.watchedEpisodes,
  );
  final watched = TrackerService.effectiveWatched(
    baseWatched: baseWatched,
    delta: watchStates[show.tvTimeId],
  );

  return ShowDetail(
    show: show,
    progress: TrackerService.computeProgress(show: show, watched: watched),
    seasons: TrackerService.buildSeasons(watched),
  );
});

ShowProgress _progressForShow({
  required TvTimeShow show,
  required List<TvTimeWatchedEpisode> watchedEpisodes,
  WatchStateDelta? watchState,
}) {
  final baseWatched = TrackerService.baseWatchedForShow(show, watchedEpisodes);
  final watched = TrackerService.effectiveWatched(
    baseWatched: baseWatched,
    delta: watchState,
  );

  return TrackerService.computeProgress(show: show, watched: watched);
}

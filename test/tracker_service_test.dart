import 'package:flutter_test/flutter_test.dart';

import 'package:tv_tracker/features/import/domain/tv_time_show.dart';
import 'package:tv_tracker/features/import/domain/tv_time_watched_episode.dart';
import 'package:tv_tracker/features/tracker/application/tracker_service.dart';
import 'package:tv_tracker/features/tracker/domain/episode_key.dart';
import 'package:tv_tracker/features/tracker/domain/watch_state_delta.dart';

void main() {
  const show = TvTimeShow(
    tvTimeId: '1',
    name: 'Test Show',
    episodesSeenCount: 10,
  );

  final episodes = [
    const TvTimeWatchedEpisode(
      showName: 'Test Show',
      showId: '1',
      seasonNumber: 1,
      episodeNumber: 1,
      episodeId: 'e1',
    ),
    const TvTimeWatchedEpisode(
      showName: 'Test Show',
      showId: '1',
      seasonNumber: 1,
      episodeNumber: 2,
      episodeId: 'e2',
    ),
    const TvTimeWatchedEpisode(
      showName: 'Test Show',
      showId: '1',
      seasonNumber: 2,
      episodeNumber: 1,
      episodeId: 'e3',
    ),
  ];

  group('TrackerService', () {
    test('computes watched episodes from import', () {
      final base = TrackerService.baseWatchedForShow(show, episodes);

      expect(base, {
        const EpisodeKey(season: 1, episode: 1),
        const EpisodeKey(season: 1, episode: 2),
        const EpisodeKey(season: 2, episode: 1),
      });
    });

    test('applies manual watch delta', () {
      final base = TrackerService.baseWatchedForShow(show, episodes);
      final delta = WatchStateDelta(
        added: {EpisodeKey(season: 1, episode: 3)},
        removed: {EpisodeKey(season: 1, episode: 2)},
      );

      final watched = TrackerService.effectiveWatched(
        baseWatched: base,
        delta: delta,
      );

      expect(watched, {
        const EpisodeKey(season: 1, episode: 1),
        const EpisodeKey(season: 1, episode: 3),
        const EpisodeKey(season: 2, episode: 1),
      });
    });

    test('recalculates progress after toggle', () {
      final base = TrackerService.baseWatchedForShow(show, episodes);
      final watched = TrackerService.effectiveWatched(baseWatched: base);
      final progress = TrackerService.computeProgress(
        show: show,
        watched: watched,
      );

      expect(progress.watchedCount, 3);
      expect(progress.totalCount, 10);
      expect(progress.ratio, 0.3);
    });

    test('builds seasons from watched episodes only', () {
      final watched = {
        const EpisodeKey(season: 1, episode: 1),
        const EpisodeKey(season: 1, episode: 2),
      };

      final seasons = TrackerService.buildSeasons(watched);

      expect(seasons.length, 1);
      expect(seasons.first.episodes.length, 2);
      expect(
        seasons.first.episodes.every((episode) => episode.isWatched),
        isTrue,
      );
    });
  });
}

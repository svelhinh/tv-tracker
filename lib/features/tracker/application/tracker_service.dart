import '../../import/domain/tv_time_show.dart';
import '../../import/domain/tv_time_watched_episode.dart';
import '../domain/episode_key.dart';
import '../domain/show_detail.dart';
import '../domain/show_progress.dart';
import '../domain/watch_state_delta.dart';

class TrackerService {
  static Set<EpisodeKey> baseWatchedForShow(
    TvTimeShow show,
    List<TvTimeWatchedEpisode> episodes,
  ) {
    return episodes
        .where((episode) => _belongsToShow(show, episode))
        .map(
          (episode) => EpisodeKey(
            season: episode.seasonNumber,
            episode: episode.episodeNumber,
          ),
        )
        .toSet();
  }

  static Set<EpisodeKey> effectiveWatched({
    required Set<EpisodeKey> baseWatched,
    WatchStateDelta? delta,
  }) {
    final watched = Set<EpisodeKey>.from(baseWatched);
    if (delta == null) return watched;

    watched
      ..addAll(delta.added)
      ..removeAll(delta.removed);

    return watched;
  }

  static ShowProgress computeProgress({
    required TvTimeShow show,
    required Set<EpisodeKey> watched,
  }) {
    return ShowProgress(
      watchedCount: watched.length,
      totalCount: show.episodesSeenCount,
    );
  }

  static List<TrackedSeason> buildSeasons(Set<EpisodeKey> watched) {
    if (watched.isEmpty) {
      return [
        const TrackedSeason(
          seasonNumber: 1,
          episodes: [
            TrackedEpisode(seasonNumber: 1, episodeNumber: 1, isWatched: false),
          ],
        ),
      ];
    }

    final episodesBySeason = <int, Set<int>>{};
    for (final key in watched) {
      episodesBySeason.putIfAbsent(key.season, () => {}).add(key.episode);
    }

    final seasons = episodesBySeason.keys.toList()..sort();
    return seasons.map((seasonNumber) {
      final episodeNumbers = episodesBySeason[seasonNumber]!;
      final maxEpisode = episodeNumbers.reduce((a, b) => a > b ? a : b);

      final episodes = <TrackedEpisode>[];
      for (var episode = 1; episode <= maxEpisode; episode++) {
        episodes.add(
          TrackedEpisode(
            seasonNumber: seasonNumber,
            episodeNumber: episode,
            isWatched: episodeNumbers.contains(episode),
          ),
        );
      }

      return TrackedSeason(seasonNumber: seasonNumber, episodes: episodes);
    }).toList();
  }

  static WatchStateDelta toggleEpisode({
    required EpisodeKey key,
    required bool currentlyWatched,
    required Set<EpisodeKey> baseWatched,
    WatchStateDelta? currentDelta,
  }) {
    final delta = currentDelta ?? const WatchStateDelta();
    final added = Set<EpisodeKey>.from(delta.added);
    final removed = Set<EpisodeKey>.from(delta.removed);
    final isFromImport = baseWatched.contains(key);

    if (currentlyWatched) {
      if (isFromImport) {
        removed.add(key);
      } else {
        added.remove(key);
      }
    } else {
      if (isFromImport) {
        removed.remove(key);
      } else {
        added.add(key);
      }
    }

    return WatchStateDelta(added: added, removed: removed);
  }

  static bool _belongsToShow(TvTimeShow show, TvTimeWatchedEpisode episode) {
    if (episode.showId.isNotEmpty) {
      return episode.showId == show.tvTimeId;
    }

    return episode.showName.trim().toLowerCase() ==
        show.name.trim().toLowerCase();
  }
}

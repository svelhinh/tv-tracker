import 'tv_time_show.dart';
import 'tv_time_watched_episode.dart';

class TvTimeImportResult {
  const TvTimeImportResult({
    required this.shows,
    required this.watchedEpisodes,
  });

  final List<TvTimeShow> shows;
  final List<TvTimeWatchedEpisode> watchedEpisodes;
}

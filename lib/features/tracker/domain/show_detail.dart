import '../../import/domain/tv_time_show.dart';
import 'show_progress.dart';

class ShowDetail {
  const ShowDetail({
    required this.show,
    required this.progress,
    required this.seasons,
  });

  final TvTimeShow show;
  final ShowProgress progress;
  final List<TrackedSeason> seasons;
}

class TrackedSeason {
  const TrackedSeason({required this.seasonNumber, required this.episodes});

  final int seasonNumber;
  final List<TrackedEpisode> episodes;
}

class TrackedEpisode {
  const TrackedEpisode({
    required this.seasonNumber,
    required this.episodeNumber,
    required this.isWatched,
  });

  final int seasonNumber;
  final int episodeNumber;
  final bool isWatched;

  String get label => 'Épisode $episodeNumber';
}

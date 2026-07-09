class TvTimeWatchedEpisode {
  const TvTimeWatchedEpisode({
    required this.showName,
    required this.showId,
    required this.seasonNumber,
    required this.episodeNumber,
    required this.episodeId,
    this.watchedAt,
  });

  final String showName;
  final String showId;
  final int seasonNumber;
  final int episodeNumber;
  final String episodeId;
  final DateTime? watchedAt;

  String get label => '$showName S${seasonNumber}E$episodeNumber';
}

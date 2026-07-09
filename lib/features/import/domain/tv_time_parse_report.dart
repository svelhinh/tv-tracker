class TvTimeParseReport {
  const TvTimeParseReport({
    this.errors = const [],
    this.warnings = const [],
    this.csvFileCount = 0,
    this.sourceFilesPresent = const {},
    this.skippedShowRows = 0,
    this.skippedEpisodeRowsV2 = 0,
    this.skippedEpisodeRowsV1 = 0,
    this.skippedEpisodeRowsRewatched = 0,
    this.episodesWithoutWatchDate = 0,
    this.episodesWithoutShowId = 0,
    this.showsWithoutSeenCount = 0,
    this.legacyFilesPresent = const [],
  });

  final List<String> errors;
  final List<String> warnings;
  final int csvFileCount;
  final Map<String, bool> sourceFilesPresent;
  final int skippedShowRows;
  final int skippedEpisodeRowsV2;
  final int skippedEpisodeRowsV1;
  final int skippedEpisodeRowsRewatched;
  final int episodesWithoutWatchDate;
  final int episodesWithoutShowId;
  final int showsWithoutSeenCount;
  final List<String> legacyFilesPresent;

  bool get hasErrors => errors.isNotEmpty;
  bool get hasWarnings => warnings.isNotEmpty;

  int get totalSkippedEpisodeRows =>
      skippedEpisodeRowsV2 + skippedEpisodeRowsV1 + skippedEpisodeRowsRewatched;
}

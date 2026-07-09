import 'tv_time_parse_report.dart';
import 'tv_time_show.dart';
import 'tv_time_watched_episode.dart';

class TvTimeImportSummary {
  const TvTimeImportSummary({
    required this.showCount,
    required this.watchedEpisodeCount,
    required this.report,
    required this.exampleShows,
    required this.exampleEpisodes,
    required this.fieldNotes,
  });

  final int showCount;
  final int watchedEpisodeCount;
  final TvTimeParseReport report;
  final List<TvTimeShow> exampleShows;
  final List<TvTimeWatchedEpisode> exampleEpisodes;
  final List<String> fieldNotes;

  static TvTimeImportSummary fromData({
    required List<TvTimeShow> shows,
    required List<TvTimeWatchedEpisode> episodes,
    required TvTimeParseReport report,
    int exampleCount = 5,
  }) {
    final fieldNotes = <String>[
      'tv_show_id : exploitable pour le matching TMDB (ID interne TV Time).',
      'episode_id : exploitable comme identifiant épisode TV Time.',
      'watchedAt : parfois absent (surtout via rewatched_episode.csv).',
      'nb_episodes_seen : agrégat TV Time, pas la liste détaillée des épisodes.',
      'seen_episode.csv : legacy, souvent vide — ignoré au profit de tracking-prod-records*.csv.',
    ];

    if (report.episodesWithoutShowId > 0) {
      fieldNotes.add(
        'showId manquant sur ${report.episodesWithoutShowId} épisode(s) '
        '(rewatched_episode.csv ne fournit pas l\'ID série).',
      );
    }

    if (report.showsWithoutSeenCount > 0) {
      fieldNotes.add(
        'nb_episodes_seen absent pour ${report.showsWithoutSeenCount} série(s) '
        '(user_tv_show_data.csv incomplet ou manquant).',
      );
    }

    for (final legacyFile in report.legacyFilesPresent) {
      fieldNotes.add('$legacyFile présent mais non utilisé (format legacy).');
    }

    return TvTimeImportSummary(
      showCount: shows.length,
      watchedEpisodeCount: episodes.length,
      report: report,
      exampleShows: shows.take(exampleCount).toList(),
      exampleEpisodes: episodes.take(exampleCount).toList(),
      fieldNotes: fieldNotes,
    );
  }
}

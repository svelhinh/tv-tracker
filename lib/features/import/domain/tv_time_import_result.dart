import 'import_metrics.dart';
import 'tv_time_import_summary.dart';
import 'tv_time_parse_report.dart';
import 'tv_time_show.dart';
import 'tv_time_watched_episode.dart';

class TvTimeImportResult {
  TvTimeImportResult({
    required this.shows,
    required this.watchedEpisodes,
    required this.report,
    this.metrics,
  }) : summary = TvTimeImportSummary.fromData(
         shows: shows,
         episodes: watchedEpisodes,
         report: report,
       );

  final List<TvTimeShow> shows;
  final List<TvTimeWatchedEpisode> watchedEpisodes;
  final TvTimeParseReport report;
  final TvTimeImportSummary summary;
  final ImportMetrics? metrics;
}

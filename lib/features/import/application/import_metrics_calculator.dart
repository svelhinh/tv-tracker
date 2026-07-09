import 'dart:convert';

import '../domain/import_metrics.dart';
import '../domain/tv_time_import_result.dart';
import '../domain/tv_time_show.dart';
import '../domain/tv_time_watched_episode.dart';

class ImportMetricsCalculator {
  const ImportMetricsCalculator._();

  static ImportMetrics compute({
    required TvTimeImportResult result,
    required Duration importDuration,
    int zipSizeBytes = 0,
    int tmdbCallsDuringImport = 0,
  }) {
    final showCount = result.shows.length;
    final episodeCount = result.watchedEpisodes.length;

    return ImportMetrics(
      importDuration: importDuration,
      zipSizeBytes: zipSizeBytes,
      showCount: showCount,
      episodeCount: episodeCount,
      estimatedStorageBytes: estimateStorageBytes(result),
      tmdbCallsDuringImport: tmdbCallsDuringImport,
      estimatedTmdbCallsForFullMatch: showCount,
      estimatedTmdbCallsForPosters: 0,
    );
  }

  static int estimateStorageBytes(TvTimeImportResult result) {
    final payload = {
      'shows': result.shows.map(_showToJson).toList(),
      'episodes': result.watchedEpisodes.map(_episodeToJson).toList(),
    };
    final jsonBytes = utf8.encode(jsonEncode(payload)).length;
    const posterCacheBytesPerShow = 60;
    const storageOverheadFactor = 1.3;

    final posterCacheBytes = result.shows.length * posterCacheBytesPerShow;
    return ((jsonBytes + posterCacheBytes) * storageOverheadFactor).round();
  }

  static Map<String, dynamic> _showToJson(TvTimeShow show) {
    return {
      'id': show.tvTimeId,
      'name': show.name,
      'active': show.isActive,
      'episodesSeenCount': show.episodesSeenCount,
    };
  }

  static Map<String, dynamic> _episodeToJson(TvTimeWatchedEpisode episode) {
    return {
      'showId': episode.showId,
      'showName': episode.showName,
      'season': episode.seasonNumber,
      'episode': episode.episodeNumber,
      'episodeId': episode.episodeId,
      'watchedAt': episode.watchedAt?.toIso8601String(),
    };
  }
}

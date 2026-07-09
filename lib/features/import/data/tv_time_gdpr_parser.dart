import 'dart:io';

import '../domain/tv_time_import_result.dart';
import '../domain/tv_time_show.dart';
import '../domain/tv_time_watched_episode.dart';

/// Parse un export GDPR TV Time (dossier de CSV décompressé).
class TvTimeGdprParser {
  static const followedShowsFile = 'followed_tv_show.csv';
  static const userShowDataFile = 'user_tv_show_data.csv';
  static const trackingRecordsV2File = 'tracking-prod-records-v2.csv';
  static const trackingRecordsFile = 'tracking-prod-records.csv';
  static const rewatchedEpisodesFile = 'rewatched_episode.csv';

  static TvTimeImportResult parseFromDirectory(String directoryPath) {
    final dir = Directory(directoryPath);
    final files = <String, String>{};

    for (final entity in dir.listSync()) {
      if (entity is! File || !entity.path.endsWith('.csv')) continue;
      final name = entity.uri.pathSegments.last;
      files[name] = entity.readAsStringSync();
    }

    return parseFromFiles(files);
  }

  static TvTimeImportResult parseFromFiles(Map<String, String> files) {
    final episodesSeenByShowId = _parseEpisodesSeenCounts(
      files[userShowDataFile],
    );
    final shows = _parseShows(
      files[followedShowsFile],
      episodesSeenByShowId,
    );
    final watchedEpisodes = _parseWatchedEpisodes(files);

    return TvTimeImportResult(
      shows: shows,
      watchedEpisodes: watchedEpisodes,
    );
  }

  static Map<String, int> _parseEpisodesSeenCounts(String? csv) {
    if (csv == null) return {};

    final counts = <String, int>{};
    for (final row in _parseCsvRows(csv)) {
      final showId = row['tv_show_id'];
      final count = int.tryParse(row['nb_episodes_seen'] ?? '');
      if (showId == null || count == null) continue;
      counts[showId] = count;
    }
    return counts;
  }

  static List<TvTimeShow> _parseShows(
    String? followedCsv,
    Map<String, int> episodesSeenByShowId,
  ) {
    if (followedCsv == null) return [];

    final shows = <TvTimeShow>[];
    for (final row in _parseCsvRows(followedCsv)) {
      final id = row['tv_show_id'];
      final name = row['tv_show_name'];
      if (id == null || name == null || name.isEmpty) continue;

      shows.add(
        TvTimeShow(
          tvTimeId: id,
          name: name,
          isActive: row['active'] != '0',
          episodesSeenCount: episodesSeenByShowId[id],
        ),
      );
    }

    shows.sort((a, b) => a.name.compareTo(b.name));
    return shows;
  }

  static List<TvTimeWatchedEpisode> _parseWatchedEpisodes(
    Map<String, String> files,
  ) {
    final byEpisodeId = <String, TvTimeWatchedEpisode>{};

    void addEpisode(TvTimeWatchedEpisode episode) {
      final existing = byEpisodeId[episode.episodeId];
      if (existing == null) {
        byEpisodeId[episode.episodeId] = episode;
        return;
      }

      final existingDate = existing.watchedAt;
      final newDate = episode.watchedAt;
      if (existingDate == null || (newDate != null && newDate.isAfter(existingDate))) {
        byEpisodeId[episode.episodeId] = episode;
      }
    }

    for (final row in _parseCsvRows(files[trackingRecordsV2File] ?? '')) {
      final gsi = row['gsi'] ?? '';
      if (!gsi.startsWith('watch-episode')) continue;

      final episode = _episodeFromV2Row(row);
      if (episode != null) addEpisode(episode);
    }

    for (final row in _parseCsvRows(files[trackingRecordsFile] ?? '')) {
      if (row['type'] != 'watch') continue;

      final episode = _episodeFromV1Row(row);
      if (episode != null) addEpisode(episode);
    }

    for (final row in _parseCsvRows(files[rewatchedEpisodesFile] ?? '')) {
      final episode = _episodeFromRewatchedRow(row);
      if (episode != null) addEpisode(episode);
    }

    final episodes = byEpisodeId.values.toList()
      ..sort((a, b) {
        final showCompare = a.showName.compareTo(b.showName);
        if (showCompare != 0) return showCompare;
        final seasonCompare = a.seasonNumber.compareTo(b.seasonNumber);
        if (seasonCompare != 0) return seasonCompare;
        return a.episodeNumber.compareTo(b.episodeNumber);
      });

    return episodes;
  }

  static TvTimeWatchedEpisode? _episodeFromV2Row(Map<String, String> row) {
    final showName = row['series_name'];
    final showId = row['s_id'];
    final season = int.tryParse(row['season_number'] ?? '');
    final episodeNumber = int.tryParse(row['episode_number'] ?? '');
    final episodeId = row['episode_id'] ?? row['ep_id'];

    if (showName == null ||
        showId == null ||
        season == null ||
        episodeNumber == null ||
        episodeId == null ||
        episodeId.isEmpty) {
      return null;
    }

    return TvTimeWatchedEpisode(
      showName: showName,
      showId: showId,
      seasonNumber: season,
      episodeNumber: episodeNumber,
      episodeId: episodeId,
      watchedAt: _parseDateTime(row['created_at']),
    );
  }

  static TvTimeWatchedEpisode? _episodeFromV1Row(Map<String, String> row) {
    final showName = row['series_name'];
    final showId = row['series_id'];
    final season = int.tryParse(row['season_number'] ?? '');
    final episodeNumber = int.tryParse(row['episode_number'] ?? '');
    final episodeId = row['episode_id'];

    if (showName == null ||
        showId == null ||
        season == null ||
        episodeNumber == null ||
        episodeId == null ||
        episodeId.isEmpty) {
      return null;
    }

    final watchDate = row['watch_date'];
    final watchedAt = watchDate != null && watchDate.isNotEmpty
        ? _parseUnixSeconds(watchDate)
        : _parseDateTime(row['created_at']);

    return TvTimeWatchedEpisode(
      showName: showName,
      showId: showId,
      seasonNumber: season,
      episodeNumber: episodeNumber,
      episodeId: episodeId,
      watchedAt: watchedAt,
    );
  }

  static TvTimeWatchedEpisode? _episodeFromRewatchedRow(Map<String, String> row) {
    final showName = row['tv_show_name'];
    final season = int.tryParse(row['episode_season_number'] ?? '');
    final episodeNumber = int.tryParse(row['episode_number'] ?? '');
    final episodeId = row['episode_id'];

    if (showName == null ||
        season == null ||
        episodeNumber == null ||
        episodeId == null ||
        episodeId.isEmpty) {
      return null;
    }

    return TvTimeWatchedEpisode(
      showName: showName,
      showId: '',
      seasonNumber: season,
      episodeNumber: episodeNumber,
      episodeId: episodeId,
      watchedAt: _parseDateTime(row['created_at']),
    );
  }

  static DateTime? _parseDateTime(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value.replaceFirst(' ', 'T'));
  }

  static DateTime? _parseUnixSeconds(String value) {
    final seconds = int.tryParse(value);
    if (seconds == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true).toLocal();
  }

  static List<Map<String, String>> _parseCsvRows(String csv) {
    if (csv.isEmpty) return [];

    final rows = <List<String>>[];
    final currentRow = <String>[];
    final cell = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < csv.length; i++) {
      final char = csv[i];

      if (inQuotes) {
        if (char == '"') {
          final hasEscapedQuote = i + 1 < csv.length && csv[i + 1] == '"';
          if (hasEscapedQuote) {
            cell.write('"');
            i++;
          } else {
            inQuotes = false;
          }
        } else {
          cell.write(char);
        }
        continue;
      }

      switch (char) {
        case '"':
          inQuotes = true;
        case ',':
          currentRow.add(cell.toString());
          cell.clear();
        case '\r':
          break;
        case '\n':
          currentRow.add(cell.toString());
          cell.clear();
          if (currentRow.any((value) => value.isNotEmpty)) {
            rows.add(List<String>.from(currentRow));
          }
          currentRow.clear();
        default:
          cell.write(char);
      }
    }

    if (cell.isNotEmpty || currentRow.isNotEmpty) {
      currentRow.add(cell.toString());
      if (currentRow.any((value) => value.isNotEmpty)) {
        rows.add(currentRow);
      }
    }

    if (rows.isEmpty) return [];

    final headers = rows.first;
    return rows
        .skip(1)
        .map(
          (values) => {
            for (var i = 0; i < headers.length; i++)
              headers[i]: i < values.length ? values[i] : '',
          },
        )
        .toList();
  }
}

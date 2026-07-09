import 'dart:io';

import '../domain/tv_time_import_result.dart';
import '../domain/tv_time_parse_report.dart';
import '../domain/tv_time_show.dart';
import '../domain/tv_time_watched_episode.dart';

/// Parse un export GDPR TV Time (dossier de CSV décompressé).
class TvTimeGdprParser {
  static const followedShowsFile = 'followed_tv_show.csv';
  static const userShowDataFile = 'user_tv_show_data.csv';
  static const trackingRecordsV2File = 'tracking-prod-records-v2.csv';
  static const trackingRecordsFile = 'tracking-prod-records.csv';
  static const rewatchedEpisodesFile = 'rewatched_episode.csv';
  static const legacySeenEpisodeFile = 'seen_episode.csv';

  static const _sourceFiles = [
    followedShowsFile,
    userShowDataFile,
    trackingRecordsV2File,
    trackingRecordsFile,
    rewatchedEpisodesFile,
  ];

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
    final errors = <String>[];
    final warnings = <String>[];
    final legacyFilesPresent = <String>[];

    final sourceFilesPresent = {
      for (final name in _sourceFiles) name: files.containsKey(name),
    };

    if (!sourceFilesPresent[followedShowsFile]!) {
      errors.add(
        '$followedShowsFile introuvable — impossible de lister les séries.',
      );
    }

    if (!sourceFilesPresent[userShowDataFile]!) {
      warnings.add('$userShowDataFile absent — nb_episodes_seen indisponible.');
    }

    if (!sourceFilesPresent[trackingRecordsV2File]! &&
        !sourceFilesPresent[trackingRecordsFile]!) {
      warnings.add(
        'Aucun fichier tracking-prod-records*.csv — la liste détaillée des '
        'épisodes vus sera vide ou très incomplète.',
      );
    } else if (!sourceFilesPresent[trackingRecordsV2File]!) {
      warnings.add(
        '$trackingRecordsV2File absent — seul $trackingRecordsFile sera utilisé.',
      );
    }

    if (!sourceFilesPresent[rewatchedEpisodesFile]!) {
      warnings.add('$rewatchedEpisodesFile absent — rewatchs non inclus.');
    }

    if (files.containsKey(legacySeenEpisodeFile)) {
      legacyFilesPresent.add(legacySeenEpisodeFile);
    }

    final episodesSeenByShowId = _parseEpisodesSeenCounts(
      files[userShowDataFile],
    );
    final showParse = _parseShows(
      files[followedShowsFile],
      episodesSeenByShowId,
    );
    final episodeParse = _parseWatchedEpisodes(files);

    final report = TvTimeParseReport(
      errors: errors,
      warnings: warnings,
      csvFileCount: files.length,
      sourceFilesPresent: sourceFilesPresent,
      skippedShowRows: showParse.skippedRows,
      skippedEpisodeRowsV2: episodeParse.skippedV2,
      skippedEpisodeRowsV1: episodeParse.skippedV1,
      skippedEpisodeRowsRewatched: episodeParse.skippedRewatched,
      episodesWithoutWatchDate: episodeParse.withoutWatchDate,
      episodesWithoutShowId: episodeParse.withoutShowId,
      showsWithoutSeenCount: showParse.withoutSeenCount,
      legacyFilesPresent: legacyFilesPresent,
    );

    return TvTimeImportResult(
      shows: showParse.shows,
      watchedEpisodes: episodeParse.episodes,
      report: report,
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

  static _ShowParseResult _parseShows(
    String? followedCsv,
    Map<String, int> episodesSeenByShowId,
  ) {
    if (followedCsv == null) {
      return const _ShowParseResult();
    }

    final shows = <TvTimeShow>[];
    var skippedRows = 0;
    var withoutSeenCount = 0;

    for (final row in _parseCsvRows(followedCsv)) {
      final id = row['tv_show_id'];
      final name = row['tv_show_name'];
      if (id == null || name == null || name.isEmpty) {
        skippedRows++;
        continue;
      }

      final seenCount = episodesSeenByShowId[id];
      if (seenCount == null) withoutSeenCount++;

      shows.add(
        TvTimeShow(
          tvTimeId: id,
          name: name,
          isActive: row['active'] != '0',
          episodesSeenCount: seenCount,
        ),
      );
    }

    shows.sort((a, b) => a.name.compareTo(b.name));
    return _ShowParseResult(
      shows: shows,
      skippedRows: skippedRows,
      withoutSeenCount: withoutSeenCount,
    );
  }

  static _EpisodeParseResult _parseWatchedEpisodes(Map<String, String> files) {
    final byEpisodeId = <String, TvTimeWatchedEpisode>{};
    var skippedV2 = 0;
    var skippedV1 = 0;
    var skippedRewatched = 0;

    void addEpisode(TvTimeWatchedEpisode episode) {
      final existing = byEpisodeId[episode.episodeId];
      if (existing == null) {
        byEpisodeId[episode.episodeId] = episode;
        return;
      }

      final existingDate = existing.watchedAt;
      final newDate = episode.watchedAt;
      if (existingDate == null ||
          (newDate != null && newDate.isAfter(existingDate))) {
        byEpisodeId[episode.episodeId] = episode;
      }
    }

    for (final row in _parseCsvRows(files[trackingRecordsV2File] ?? '')) {
      final gsi = row['gsi'] ?? '';
      if (!gsi.startsWith('watch-episode')) continue;

      final episode = _episodeFromV2Row(row);
      if (episode == null) {
        skippedV2++;
        continue;
      }
      addEpisode(episode);
    }

    for (final row in _parseCsvRows(files[trackingRecordsFile] ?? '')) {
      if (row['type'] != 'watch') continue;

      final episode = _episodeFromV1Row(row);
      if (episode == null) {
        skippedV1++;
        continue;
      }
      addEpisode(episode);
    }

    for (final row in _parseCsvRows(files[rewatchedEpisodesFile] ?? '')) {
      final episode = _episodeFromRewatchedRow(row);
      if (episode == null) {
        skippedRewatched++;
        continue;
      }
      addEpisode(episode);
    }

    final episodes = byEpisodeId.values.toList()
      ..sort((a, b) {
        final showCompare = a.showName.compareTo(b.showName);
        if (showCompare != 0) return showCompare;
        final seasonCompare = a.seasonNumber.compareTo(b.seasonNumber);
        if (seasonCompare != 0) return seasonCompare;
        return a.episodeNumber.compareTo(b.episodeNumber);
      });

    final withoutWatchDate = episodes
        .where((episode) => episode.watchedAt == null)
        .length;
    final withoutShowId = episodes
        .where((episode) => episode.showId.isEmpty)
        .length;

    return _EpisodeParseResult(
      episodes: episodes,
      skippedV2: skippedV2,
      skippedV1: skippedV1,
      skippedRewatched: skippedRewatched,
      withoutWatchDate: withoutWatchDate,
      withoutShowId: withoutShowId,
    );
  }

  static TvTimeWatchedEpisode? _episodeFromV2Row(Map<String, String> row) {
    final showName = row['series_name'];
    final showId = row['s_id'];
    final season = int.tryParse(row['season_number'] ?? '');
    final episodeNumber = int.tryParse(row['episode_number'] ?? '');
    final episodeId = row['episode_id'].ifEmpty(row['ep_id']);

    if (showName == null ||
        showId == null ||
        season == null ||
        episodeNumber == null ||
        episodeId == null) {
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

  static TvTimeWatchedEpisode? _episodeFromRewatchedRow(
    Map<String, String> row,
  ) {
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
    return DateTime.fromMillisecondsSinceEpoch(
      seconds * 1000,
      isUtc: true,
    ).toLocal();
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

class _ShowParseResult {
  const _ShowParseResult({
    this.shows = const [],
    this.skippedRows = 0,
    this.withoutSeenCount = 0,
  });

  final List<TvTimeShow> shows;
  final int skippedRows;
  final int withoutSeenCount;
}

class _EpisodeParseResult {
  const _EpisodeParseResult({
    this.episodes = const [],
    this.skippedV2 = 0,
    this.skippedV1 = 0,
    this.skippedRewatched = 0,
    this.withoutWatchDate = 0,
    this.withoutShowId = 0,
  });

  final List<TvTimeWatchedEpisode> episodes;
  final int skippedV2;
  final int skippedV1;
  final int skippedRewatched;
  final int withoutWatchDate;
  final int withoutShowId;
}

extension _NullableStringFallback on String? {
  String? ifEmpty(String? fallback) {
    if (this == null || this!.isEmpty) return fallback;
    return this;
  }
}

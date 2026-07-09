import 'dart:io';

import 'package:tv_tracker/core/config/env_file_reader.dart';
import 'package:tv_tracker/core/config/tmdb_config.dart';
import 'package:tv_tracker/core/metrics/tmdb_api_metrics.dart';
import 'package:tv_tracker/features/import/application/import_metrics_calculator.dart';
import 'package:tv_tracker/features/import/data/tv_time_export_importer.dart';
import 'package:tv_tracker/features/import/data/tv_time_gdpr_parser.dart';
import 'package:tv_tracker/features/import/domain/import_metrics.dart';
import 'package:tv_tracker/features/import/domain/tv_time_import_result.dart';
import 'package:tv_tracker/features/matching/data/tmdb_client.dart';
import 'package:tv_tracker/features/matching/data/tmdb_show_matcher.dart';

Future<void> main(List<String> args) async {
  final withTmdb = args.contains('--with-tmdb');
  final zipPath = _readArg(args, '--zip');
  final exportDirPath = _readArg(args, '--dir') ?? 'resources/gdpr-data';

  ImportMetrics metrics;
  TvTimeImportResult importResult;

  if (zipPath != null) {
    final file = File(zipPath);
    if (!file.existsSync()) {
      stderr.writeln('ZIP introuvable : $zipPath');
      exitCode = 1;
      return;
    }

    importResult = await TvTimeExportImporter.importFromZipFile(zipPath);
    metrics = importResult.metrics!;
  } else {
    final exportDir = Directory(exportDirPath);
    if (!exportDir.existsSync()) {
      stderr.writeln('Dossier introuvable : $exportDirPath');
      stderr.writeln(
        'Place un export TV Time dans resources/gdpr-data/ '
        'ou passe --zip=chemin/vers/export.zip',
      );
      exitCode = 1;
      return;
    }

    final stopwatch = Stopwatch()..start();
    importResult = TvTimeGdprParser.parseFromDirectory(exportDir.path);
    stopwatch.stop();

    metrics = ImportMetricsCalculator.compute(
      result: importResult,
      importDuration: stopwatch.elapsed,
      zipSizeBytes: _directorySizeBytes(exportDir),
    );
  }

  var tmdbCallsDuringImport = metrics.tmdbCallsDuringImport;
  var actualTmdbCalls = 0;

  if (withTmdb) {
    await loadEnvFile();
    if (!hasTmdbApiKey) {
      stderr.writeln('TMDB_API_KEY manquant pour --with-tmdb.');
      exitCode = 1;
      return;
    }

    final apiMetrics = TmdbApiMetrics();
    final client = TmdbClient(metrics: apiMetrics);
    final matcher = TmdbShowMatcher(client);

    try {
      stdout.writeln(
        'Matching TMDB en cours (${importResult.shows.length} séries)...',
      );
      await matcher.matchShows(importResult.shows);
      actualTmdbCalls = apiMetrics.callCount;
      tmdbCallsDuringImport = actualTmdbCalls;

      metrics = ImportMetrics(
        importDuration: metrics.importDuration,
        zipSizeBytes: metrics.zipSizeBytes,
        showCount: metrics.showCount,
        episodeCount: metrics.episodeCount,
        estimatedStorageBytes: metrics.estimatedStorageBytes,
        tmdbCallsDuringImport: tmdbCallsDuringImport,
        estimatedTmdbCallsForFullMatch: metrics.estimatedTmdbCallsForFullMatch,
        estimatedTmdbCallsForPosters: metrics.estimatedTmdbCallsForPosters,
      );
    } finally {
      client.close();
    }
  }

  _printReport(metrics, actualTmdbCalls: actualTmdbCalls);
}

String? _readArg(List<String> args, String name) {
  for (final arg in args) {
    if (arg.startsWith('$name=')) {
      return arg.substring(name.length + 1);
    }
  }
  return null;
}

int _directorySizeBytes(Directory dir) {
  var total = 0;
  for (final entity in dir.listSync(recursive: true)) {
    if (entity is File) {
      total += entity.lengthSync();
    }
  }
  return total;
}

void _printReport(ImportMetrics metrics, {int actualTmdbCalls = 0}) {
  stdout.writeln('=== Estimation scale TV Tracker ===');
  stdout.writeln();
  stdout.writeln('--- Par utilisateur (export référence) ---');
  stdout.writeln('Séries : ${metrics.showCount}');
  stdout.writeln('Épisodes vus : ${metrics.episodeCount}');
  stdout.writeln('Durée import : ${_formatDuration(metrics.importDuration)}');
  if (metrics.zipSizeBytes > 0) {
    stdout.writeln('Taille export : ${_formatBytes(metrics.zipSizeBytes)}');
  }
  stdout.writeln(
    'Stockage local estimé : ${_formatBytes(metrics.estimatedStorageBytes)}',
  );
  stdout.writeln(
    'Appels TMDB pendant import : ${metrics.tmdbCallsDuringImport}',
  );
  if (actualTmdbCalls > 0) {
    stdout.writeln('Appels TMDB réels (matching) : $actualTmdbCalls');
  }
  stdout.writeln(
    'Appels TMDB estimés 1re session : ${metrics.estimatedTmdbCallsFirstSession} '
    '(matching + posters fusionnés, cache session local)',
  );
  stdout.writeln();

  stdout.writeln('--- Extrapolation ---');
  for (final estimate in metrics.extrapolate()) {
    stdout.writeln(
      '${estimate.userCount} utilisateurs : '
      '${estimate.totalShows} séries, '
      '${estimate.totalEpisodes} épisodes, '
      '${estimate.totalTmdbCallsFirstSession} appels TMDB, '
      '${estimate.storageLabel}, '
      '${estimate.importTimeLabel} import séquentiel',
    );
  }
  stdout.writeln();

  stdout.writeln('--- Points de risque coût ---');
  for (final note in metrics.costRiskNotes) {
    stdout.writeln('• $note');
  }
  stdout.writeln();

  stdout.writeln('--- Verdict ---');
  stdout.writeln(_verdict(metrics));
}

String _verdict(ImportMetrics metrics) {
  final perUserStorageMb = metrics.estimatedStorageBytes / (1024 * 1024);
  final extrap100k = metrics.extrapolate().last;

  if (metrics.showCount > 500) {
    return 'Bibliothèque lourde (${metrics.showCount} séries). '
        'Le matching TMDB séquentiel deviendra le goulot principal.';
  }

  if (extrap100k.totalStorageBytes > 50 * 1024 * 1024 * 1024) {
    return 'Stockage backend > 50 Go à 100k users — prévoir base + archivage.';
  }

  if (extrap100k.totalTmdbCallsFirstSession > 1000000) {
    return 'Volume TMDB élevé à 100k users '
        '(${extrap100k.totalTmdbCallsFirstSession} appels). '
        'Cache serveur et batch matching indispensables.';
  }

  if (perUserStorageMb < 5 && metrics.showCount < 200) {
    return 'Profil raisonnable pour un prototype. '
        'Les coûts exploseront surtout via TMDB sans cache partagé.';
  }

  return 'Profil modéré. Surveiller TMDB et persistance avant beta publique.';
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes o';
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} Ko';
  }
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} Mo';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} Go';
}

String _formatDuration(Duration duration) {
  if (duration.inHours >= 1) {
    return '${duration.inHours}h ${duration.inMinutes.remainder(60)}min';
  }
  if (duration.inMinutes >= 1) {
    return '${duration.inMinutes}min ${duration.inSeconds.remainder(60)}s';
  }
  if (duration.inMilliseconds >= 1000) {
    return '${(duration.inMilliseconds / 1000).toStringAsFixed(2)} s';
  }
  return '${duration.inMilliseconds} ms';
}

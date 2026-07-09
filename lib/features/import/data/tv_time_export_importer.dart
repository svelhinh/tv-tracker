import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

import '../application/import_metrics_calculator.dart';
import '../domain/tv_time_import_result.dart';
import 'tv_time_gdpr_parser.dart';

class TvTimeExportImporter {
  static Future<TvTimeImportResult> importFromZipFile(String zipPath) async {
    final bytes = await File(zipPath).readAsBytes();
    return importFromZipBytes(bytes, zipSizeBytes: bytes.length);
  }

  static Future<TvTimeImportResult> importFromZipBytes(
    List<int> bytes, {
    int? zipSizeBytes,
  }) async {
    Directory? tempDir;
    final stopwatch = Stopwatch()..start();

    try {
      tempDir = await _extractZipToTemp(bytes);
      final exportDir = _findExportDirectory(tempDir);
      if (exportDir == null) {
        throw const FormatException(
          'Export TV Time invalide : followed_tv_show.csv introuvable dans le ZIP.',
        );
      }

      final result = TvTimeGdprParser.parseFromDirectory(exportDir.path);
      stopwatch.stop();

      return TvTimeImportResult(
        shows: result.shows,
        watchedEpisodes: result.watchedEpisodes,
        report: result.report,
        metrics: ImportMetricsCalculator.compute(
          result: result,
          importDuration: stopwatch.elapsed,
          zipSizeBytes: zipSizeBytes ?? bytes.length,
        ),
      );
    } finally {
      await tempDir?.delete(recursive: true);
    }
  }

  static Future<Directory> _extractZipToTemp(List<int> bytes) async {
    final archive = ZipDecoder().decodeBytes(bytes);
    final tempDir = await Directory.systemTemp.createTemp('tv_time_export_');

    for (final file in archive) {
      if (file.isFile) {
        final name = file.name;
        if (name.contains('__MACOSX')) continue;

        final outputFile = File(p.join(tempDir.path, name));
        await outputFile.parent.create(recursive: true);
        await outputFile.writeAsBytes(file.content as List<int>);
      }
    }

    return tempDir;
  }

  static Directory? _findExportDirectory(Directory root) {
    final markerFile = File(
      p.join(root.path, TvTimeGdprParser.followedShowsFile),
    );
    if (markerFile.existsSync()) return root;

    for (final entity in root.listSync()) {
      if (entity is! Directory) continue;
      final found = _findExportDirectory(entity);
      if (found != null) return found;
    }

    return null;
  }
}

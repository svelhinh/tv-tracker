import 'dart:io';

import 'package:tv_tracker/features/import/data/tv_time_gdpr_parser.dart';

void main() {
  final exportDir = Directory('resources/gdpr-data');
  if (!exportDir.existsSync()) {
    stderr.writeln('Dossier introuvable : ${exportDir.path}');
    stderr.writeln(
      'Place un export TV Time décompressé dans resources/gdpr-data/',
    );
    exitCode = 1;
    return;
  }

  final result = TvTimeGdprParser.parseFromDirectory(exportDir.path);
  final summary = result.summary;
  final report = summary.report;

  stdout.writeln('=== Résumé import TV Time (GDPR) ===');
  stdout.writeln('Fichiers CSV : ${report.csvFileCount}');
  stdout.writeln('Séries trouvées : ${summary.showCount}');
  stdout.writeln('Épisodes vus : ${summary.watchedEpisodeCount}');
  stdout.writeln();

  if (report.hasErrors) {
    stdout.writeln('--- Erreurs ---');
    for (final error in report.errors) {
      stdout.writeln('  • $error');
    }
    stdout.writeln();
  }

  if (report.hasWarnings) {
    stdout.writeln('--- Avertissements ---');
    for (final warning in report.warnings) {
      stdout.writeln('  • $warning');
    }
    stdout.writeln();
  }

  stdout.writeln('--- Champs / limites ---');
  for (final note in summary.fieldNotes) {
    stdout.writeln('  • $note');
  }
  stdout.writeln();

  stdout.writeln('--- Exemples séries ---');
  for (final show in summary.exampleShows) {
    stdout.writeln('  [${show.tvTimeId}] ${show.name}');
  }

  stdout.writeln();
  stdout.writeln('--- Exemples épisodes ---');
  for (final episode in summary.exampleEpisodes) {
    stdout.writeln('  ${episode.label} (ep_id=${episode.episodeId})');
  }
}

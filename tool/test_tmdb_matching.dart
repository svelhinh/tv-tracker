import 'dart:io';

import 'package:tv_tracker/core/config/env_file_reader.dart';
import 'package:tv_tracker/core/config/tmdb_config.dart';
import 'package:tv_tracker/features/import/data/tv_time_gdpr_parser.dart';
import 'package:tv_tracker/features/matching/data/tmdb_client.dart';
import 'package:tv_tracker/features/matching/data/tmdb_show_matcher.dart';

Future<void> main() async {
  await loadEnvFile();

  if (!hasTmdbApiKey) {
    stderr.writeln('TMDB_API_KEY manquant.');
    stderr.writeln(
      'Crée un fichier .env à la racine (voir .env.example), ou lance avec :',
    );
    stderr.writeln(
      'dart run tool/test_tmdb_matching.dart '
      '--dart-define=TMDB_API_KEY=ta_cle',
    );
    exitCode = 1;
    return;
  }

  final exportDir = Directory('resources/gdpr-data');
  if (!exportDir.existsSync()) {
    stderr.writeln('Dossier introuvable : ${exportDir.path}');
    exitCode = 1;
    return;
  }

  final import = TvTimeGdprParser.parseFromDirectory(exportDir.path);
  final client = TmdbClient();
  final matcher = TmdbShowMatcher(client);

  try {
    final report = await matcher.matchShows(import.shows);
    final percent = (report.confidentRate * 100).toStringAsFixed(0);

    stdout.writeln('=== Test matching TMDB (${report.sampleSize} séries) ===');
    stdout.writeln('Matchs confiants : ${report.confidentCount} ($percent%)');
    stdout.writeln('Ambigus : ${report.ambiguousCount}');
    stdout.writeln('Sans match : ${report.noMatchCount}');
    stdout.writeln(
      report.isReliableEnough
          ? 'Verdict : assez fiable pour continuer.'
          : 'Verdict : matching à affiner.',
    );
    stdout.writeln();
    stdout.writeln('--- Erreurs typiques ---');
    for (final issue in report.typicalIssues) {
      stdout.writeln('• $issue');
    }
    stdout.writeln();
    stdout.writeln('--- Détail ---');
    for (final result in report.results) {
      final tmdb = result.tmdbId != null
          ? ' → [${result.tmdbId}] ${result.tmdbName}'
          : '';
      stdout.writeln('${result.show.name}$tmdb (${result.confidence.name})');
    }
  } finally {
    client.close();
  }
}

import 'dart:io';

import 'package:tv_tracker/features/import/data/tv_time_gdpr_parser.dart';

void main() {
  final exportDir = Directory('resources/gdpr-data');
  if (!exportDir.existsSync()) {
    stderr.writeln('Dossier introuvable : ${exportDir.path}');
    stderr.writeln('Place un export TV Time décompressé dans resources/gdpr-data/');
    exitCode = 1;
    return;
  }

  final result = TvTimeGdprParser.parseFromDirectory(exportDir.path);

  stdout.writeln('=== Format export TV Time (GDPR) ===');
  stdout.writeln('Dossier : ${exportDir.path}');
  stdout.writeln('Fichiers CSV : ${exportDir.listSync().whereType<File>().length}');
  stdout.writeln();
  stdout.writeln('Séries suivies : ${result.shows.length}');
  stdout.writeln('Épisodes vus   : ${result.watchedEpisodes.length}');
  stdout.writeln();

  stdout.writeln('--- 5 premières séries ---');
  for (final show in result.shows.take(5)) {
    stdout.writeln('  [${show.tvTimeId}] ${show.name}');
  }

  stdout.writeln();
  stdout.writeln('--- 5 premiers épisodes vus ---');
  for (final episode in result.watchedEpisodes.take(5)) {
    stdout.writeln(
      '  ${episode.showName} S${episode.seasonNumber}E${episode.episodeNumber}'
      ' (ep_id=${episode.episodeId}, ${episode.watchedAt})',
    );
  }
}
